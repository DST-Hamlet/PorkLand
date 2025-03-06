--------------------------------------------------------------------------
--[[ Batted class definition ]]
--------------------------------------------------------------------------

return Class(function(self, inst)

assert(TheWorld.ismastersim, "Batted should not exist on client")

--------------------------------------------------------------------------
--[[ Dependencies ]]
--------------------------------------------------------------------------

local SourceModifierList = require("util/sourcemodifierlist")

--------------------------------------------------------------------------
--[[ Constants ]]
--------------------------------------------------------------------------

local BAT_SPAWN_DIST = 5
local MAX_BAT_COUNT = 25
local BAT_ATTACK_TIME = {base = 4 * TUNING.TOTAL_DAY_TIME, random = 0.5 * TUNING.TOTAL_DAY_TIME}
local MODIFIER_SOURCE_WORLDSETTINGS = "worldsettings"
local MODIFIER_KEY_REGEN_TIME = "regen"
local MODIFIER_RARE = 1.25
local MODIFIER_OFTEN = 0.9
local MODIFIER_ALWAYS = 0.75
local _world = TheWorld

--------------------------------------------------------------------------
--[[ Member variables ]]
--------------------------------------------------------------------------

-- Public
self.inst = inst

-- Private
local _spawnmode = "normal"
local target_players = {}
local _batcaves = {}
local _bats = {}
local _bats_to_attack = {}
local _bat_count = 0
local _bat_regen_time = 0
local _bat_attack_time = 0
local _bat_per_player = 0
local _bat_remainder = 0
local _time_modifiers = SourceModifierList(inst, 1)

local _player_battime_binaryheap = BinaryHeap("porkland_nextbattedtime", "porkland_nextbattedtime_index")
local _target_player = nil
local _force_bat_min = nil
local _force_bat_max = nil

--------------------------------------------------------------------------
--[[ Private event handlers ]]
--------------------------------------------------------------------------

local function OnBatRemoved(bat)
    _bats[bat] = nil
    _bat_count = math.max(_bat_count - 1, 0)
    bat:RemoveEventCallback("onremove", OnBatRemoved)
    bat:RemoveEventCallback("death", OnBatRemoved)
end

local function OnBatSpawned(bat)
    _bats[bat] = bat
    _bat_count = _bat_count + 1
    bat:ListenForEvent("onremove", OnBatRemoved)
    bat:ListenForEvent("death", OnBatRemoved)
end

local function hibernate(bat)
    bat.components.sleeper.hibernate = true
    bat.components.sleeper:GoToSleep()
    bat.sg:GoToState("sleeping")
end

-- Spawns a bat in a random bat cave
local function AddBatToCaves()
    local bat_count = self:GetNumBats()
    if bat_count >= MAX_BAT_COUNT then
        return
    end

    local interiorID = GetRandomItem(_batcaves)
    local bat_cave = TheWorld.components.interiorspawner:GetInteriorCenter(interiorID)
    local width, depth = bat_cave:GetSize()
    local offset = {x = math.random() * width - width / 2, y = 0, z = math.random() * depth - depth / 2}

    local bat = TheWorld.components.interiorspawner:SpawnObject(interiorID, "vampirebat")
    if bat then
        OnBatSpawned(bat)
        if TheWorld.components.interiorspawner:IsAnyPlayerInRoom(interiorID) then
            bat.sg:GoToState("flyout", offset)
            bat:DoTaskInTime(176 * FRAMES, hibernate)
        else
            -- Don't bother if there are no players
            local spawn_point = bat_cave:GetPosition() + offset
            bat.Transform:SetPosition(spawn_point.x, 0, spawn_point.z)
            hibernate(bat)
        end
    end
end

local RATE_D5 = 1 / 960  -- 1 bat every 2 days
local RATE_D10 = 1 / 720 -- 1 bat every 1.5 days
local RATE_D20 = 1 / 480 -- 1 bat a day
local RATE_D40 = 1 / 360 -- 1.5 bats / day
local RATE_D40P = 1 / 240 -- 2 bats / day

local function GetNextRegenTime()
    --local day = TheWorld.state.cycles
    local time = 130
    local rate = 0
    for _, player in pairs(AllPlayers) do
        local age = player.components.age:GetAgeInDays()     
        if age < 5 then
            rate = rate + RATE_D5
        elseif age < 10 then
            rate = rate + RATE_D10
        elseif age < 20 then
            rate = rate + RATE_D20
        elseif age < 40 then
            rate = rate + RATE_D40
        else
            rate = rate + RATE_D40P
        end
    end
    if rate ~= 0 then time = 1 / rate end

    return time * _time_modifiers:CalculateModifierFromKey(MODIFIER_KEY_REGEN_TIME)
end

local function GetNextAttackTime()
    return GetRandomWithVariance(BAT_ATTACK_TIME.base, BAT_ATTACK_TIME.random)
end

-- In case another player is interacting with them
local function IsBatSuitableForAttack(bat)
    if not bat:IsValid() then
        return false
    end

    if not bat.components.health or bat.components.health:IsDead() or bat.components.health.takingfiredamage then
        return false
    end

    if not bat.components.combat or bat.components.combat:HasTarget() then
        return false
    end

    if bat.components.freezable and bat.components.freezable:IsFrozen() then
        return false
    end

    if bat.components.burnable and bat.components.burnable:IsBurning() then
        return false
    end

    if bat.components.hauntable and bat.components.hauntable.panic then
        return false
    end

    return true
end

local function CollectBatsForAttack()
    local putbackin_players = {}
    _target_player = nil
    
    while _player_battime_binaryheap[1] ~= nil do --take stuff out of heap, heap is always sorted at [1] position
        _target_player = _player_battime_binaryheap[1]
        _player_battime_binaryheap:Remove(_target_player)
        if not _target_player:GetIsInInterior() then
            break
        end
        table.insert(putbackin_players, _target_player)
        _target_player = nil
    end
    
    for _, player in ipairs(putbackin_players) do
        _player_battime_binaryheap:Insert(player)
    end

    if _target_player == nil then return end --no players

    local suitable_bat_count = 0
    for _, bat in pairs(_bats) do
        if IsBatSuitableForAttack(bat) then
            _bats_to_attack[#_bats_to_attack + 1] = bat
            suitable_bat_count = suitable_bat_count + 1
        end
    end

    local age = _target_player.components.age:GetAgeInDays()
    local min_bound = 0
    local max_bound = 0
	if _force_bat_min then
		min_bound = _force_bat_min
		max_bound = _force_bat_max
	else
		if age < 10 then
			min_bound = 2
			max_bound = 2
		elseif age < 25 then
			min_bound = 3
			max_bound = 4
		elseif age < 50 then
			min_bound = 4
			max_bound = 6
		elseif age < 100 then
			min_bound = 5
			max_bound = 7
		else
			min_bound = 7
			max_bound = 50
		end --bounds copied from dst wiki
	end

    if suitable_bat_count < min_bound then
        _bat_per_player = 0 --force failure
        _player_battime_binaryheap:Insert(_target_player)
        _target_player = nil
        print("bat attack cant find enough bats", suitable_bat_count, "is less than", min_bound)
    elseif suitable_bat_count > max_bound then -- Throw everything on 1 player, the others have their own batted timer.
        _bat_per_player = max_bound
    else
        _bat_per_player = suitable_bat_count            
    end
    _bat_remainder = suitable_bat_count - _bat_per_player
    
    print("_bat_per_player", _target_player, _bat_per_player, suitable_bat_count)
end

local function GetSpawnPointForPlayer(player)
    local pt = player:GetPosition()
    local radius = BAT_SPAWN_DIST

    local targetpt = FindNearbyLand(pt, math.random() * radius, 12)

    if targetpt then
        return targetpt
    end
end

---@return boolean no_bat_left whether there are bats left for attack
local function SpawnBatsForPlayer(player)
    if not next(_bats_to_attack) then
        return true
    end

    if player:GetIsInInterior() then
        return false
    end

    local num_spawned = 0
    local mark_for_remove = {}
    for key, bat in pairs(_bats_to_attack) do
        if num_spawned >= _bat_per_player then
            break
        end

        if num_spawned >= math.floor(_bat_per_player) then
            if (_bat_remainder <= 0) then
                break
            end
            _bat_remainder = _bat_remainder - 1
        end

        local spawn_point = GetSpawnPointForPlayer(player)
        if bat:IsValid() and spawn_point then
            local bat_shadow = SpawnPrefab("circlingbat")
            -- TODO inherit health and such

            bat_shadow.Transform:SetPosition(spawn_point.x, spawn_point.y, spawn_point.z)

            bat_shadow.components.circler:SetCircleTarget(player)
            bat_shadow.components.circler.dontfollowinterior = true
            bat_shadow.components.circler:Start()

            -- Don't remove/append values when iterating through a table
            mark_for_remove[#mark_for_remove + 1] = key

            num_spawned = num_spawned + 1
        end
    end

    if num_spawned > 0 then
        player:DoTaskInTime(5, function() player.components.talker:Say(GetString(player.prefab, "ANNOUCE_BATS")) end)
    end

    for _, key in pairs(mark_for_remove) do
        local bat = _bats_to_attack[key]
        local interiorID = bat:GetCurrentInteriorID()
        if TheWorld.components.interiorspawner:IsAnyPlayerInRoom(interiorID) then
            local door_id = "vampirebatcave" .. interiorID .. "_exit"
            local door = TheWorld.components.interiorspawner.doors[door_id].inst

            bat.persists = false
            bat._target_exterior = door.components.door.target_exterior
            bat.components.locomotor:GoToEntity(door, ACTIONS.VAMPIREBAT_FLYAWAY, true)
        else
            -- Don't bother if there are no players
            bat:Remove()
        end

        _bats_to_attack[key] = nil
    end

    return false
end

--------------------------------------------------------------------------
--[[ Initialization ]]
--------------------------------------------------------------------------

_bat_attack_time = GetNextAttackTime()
_bat_regen_time = GetNextRegenTime()

self.inst:StartUpdatingComponent(self)

--------------------------------------------------------------------------
--[[ Public getters and setters ]]
--------------------------------------------------------------------------

-- Easy access for roc cave connection
---@return number InteriorID
function self:GetRandomBatCave()
    return GetRandomItem(_batcaves)
end

function self:GetNumBats()
    return _bat_count
end

function self:GetSpawnMode()
    return _spawnmode
end

function self:SetSpawnModeNever()
    _spawnmode = "never"
    _time_modifiers:RemoveModifier(MODIFIER_SOURCE_WORLDSETTINGS, MODIFIER_KEY_REGEN_TIME)
    self.inst:StopUpdatingComponent(self)
end

function self:SetSpawnModeRare()
    _spawnmode = "rare"
    _time_modifiers:SetModifier(MODIFIER_SOURCE_WORLDSETTINGS, MODIFIER_RARE, MODIFIER_KEY_REGEN_TIME)
end

function self:SetSpawnModeNormal()
    _spawnmode = "normal"
    _time_modifiers:RemoveModifier(MODIFIER_SOURCE_WORLDSETTINGS, MODIFIER_KEY_REGEN_TIME)
end

function self:SetSpawnModeOften()
    _spawnmode = "often"
    _time_modifiers:SetModifier(MODIFIER_SOURCE_WORLDSETTINGS, MODIFIER_OFTEN, MODIFIER_KEY_REGEN_TIME)
end

function self:SetSpawnModeAlways()
    _spawnmode = "always"
    _time_modifiers:SetModifier(MODIFIER_SOURCE_WORLDSETTINGS, MODIFIER_ALWAYS, MODIFIER_KEY_REGEN_TIME)
end

--------------------------------------------------------------------------
--[[ Public member functions ]]
--------------------------------------------------------------------------

function self:RegisterBatCave(interiorID)
    table.insert(_batcaves, interiorID)
end

function self:UnRegisterBatCave(interiorID)
    local INTERIOR_RADIUS_SQUARE = 40 * 40 -- big enough to cover the bat cave
    local bat_cave_center = TheWorld.components.interiorspawner:GetInteriorCenter(interiorID)
    for _, bat in pairs(_bats) do
        if bat:GetDistanceSqToInst(bat_cave_center) < INTERIOR_RADIUS_SQUARE then
            OnBatRemoved(bat)
        end
    end
    RemoveByValue(_batcaves, interiorID)
end

function self:OnUpdate(dt)
    if _spawnmode == "never" then
        self.inst:StopUpdatingComponent(self)
        return
    end

    self:LongUpdate(dt)
end

function self:LongUpdate(dt)
    if _spawnmode == "never" then
        return
    end

    if POPULATING then
        return
    end

    local dt_bat_regen = dt
    while dt_bat_regen > 0 do
        if dt_bat_regen < _bat_regen_time then
            _bat_regen_time = _bat_regen_time - dt_bat_regen
            dt_bat_regen = 0
        else
            dt_bat_regen = dt_bat_regen - _bat_regen_time
            AddBatToCaves()
            _bat_regen_time = GetNextRegenTime()
        end
    end

    local dt_bat_attack = dt
    while dt_bat_attack > 0 do
        if dt_bat_attack < _bat_attack_time then
            _bat_attack_time = _bat_attack_time - dt_bat_attack
            dt_bat_attack = 0
        else
            dt_bat_attack = dt_bat_attack - _bat_attack_time
            local spawnfailed = false
            while not spawnfailed do --throw bats at players until spawn fails
                CollectBatsForAttack()
				if not _target_player then
					spawnfailed = true 
				else
					if next(_bats_to_attack) then
						SpawnBatsForPlayer(_target_player)
						--_bats_to_attack = {} -- reset it since all bats were removed
					end
				end
		
				if spawnfailed then
					_bat_attack_time = _bat_regen_time --check next bat regen
				else
					local current_time = TheWorld.state.cycles + TheWorld.state.time
					_target_player.porkland_nextbattedtime = current_time * TUNING.TOTAL_DAY_TIME + GetNextAttackTime()
					_player_battime_binaryheap:Insert(_target_player)
					_target_player = nil
					local player_mod = #AllPlayers
					if player_mod == 0 then player_mod = 1 end
					_bat_attack_time = GetNextAttackTime() / player_mod
				end
            end
			_force_bat_min = nil
			_force_bat_max = nil
        end
    end
end

--------------------------------------------------------------------------
--[[ Save/Load ]]
--------------------------------------------------------------------------

function self:OnSave()
    local data = {}
    local refs = {}

    data.bat_attack_time = _bat_attack_time
    data.bat_regen_time = _bat_regen_time

    data.batcaves = _batcaves

    if next(_bats) then
        data.bats = {}
        for _, bat in pairs(_bats) do
            table.insert(data.bats, bat.GUID)
            table.insert(refs, bat.GUID)
        end
    end

    if next(_bats_to_attack) then
        data.bats_to_attack = {}
        for _, bat in pairs(_bats_to_attack) do
            table.insert(data.bats_to_attack, bat.GUID)
            table.insert(refs, bat.GUID)
        end
    end

    return data, refs
end

function self:OnLoad(data)
    if not data then
        return
    end

    _batcaves = data.batcaves or {}

    _bat_attack_time = data.bat_attack_time or 0
    _bat_regen_time = data.bat_regen_time or 0
end

function self:LoadPostPass(ents, data)
    if not data then
        return
    end

    if data.bats and next(data.bats) then
        for _, bat_GUID in pairs(data.bats) do
            if ents[bat_GUID] then
                OnBatSpawned(ents[bat_GUID].entity)
            end
        end
    end

    if data.bats_to_attack and next(data.bats_to_attack) then
        for _, bat_GUID in pairs(data.bats_to_attack) do
            _bats_to_attack[#_bats_to_attack + 1] = ents[bat_GUID] and ents[bat_GUID].entity
        end
    end
end

--------------------------------------------------------------------------
--[[ Binary Heap Detection ]]
--------------------------------------------------------------------------

local function AddToHeap(src, player)
    player:DoTaskInTime(0, function()
        if not player.porkland_nextbattedtime then --new player or just joined ham
            local current_time = TheWorld.state.cycles + TheWorld.state.time
            player.porkland_nextbattedtime = current_time * TUNING.TOTAL_DAY_TIME + GetNextAttackTime()
        end
		print("BATTED_TIME", player, player.porkland_nextbattedtime)
        _player_battime_binaryheap:Insert(player)
    end)
end
local function RemoveFromHeap(src, player)
    _player_battime_binaryheap:Remove(player)
end
        
inst:ListenForEvent("ms_playerspawn", AddToHeap, _world)
inst:ListenForEvent("ms_playerleft", RemoveFromHeap, _world)

--------------------------------------------------------------------------
--[[ Debug ]]
--------------------------------------------------------------------------

function self:GetDebugString()
    local s = ""
    s = string.format("Bat count: %d Regen In: %2.0fs Next attack in: %2.0fs", _bat_count, _bat_regen_time, _bat_attack_time)
    return s
end

function self:ForceBatAttack()
    _bat_attack_time = 0
	_force_bat_min = 13
	_force_bat_max = 15
    self:OnUpdate(0)
end

function self:RegenBat(amount)
    amount = amount or 1
    for i = 1, amount do
        AddBatToCaves()
    end
end

function self:RegenAllBats()
    local num_tries = 0 -- just in case
    while _bat_count < MAX_BAT_COUNT and num_tries < MAX_BAT_COUNT * 2 do
        AddBatToCaves()
        num_tries = num_tries + 1
    end
end

--------------------------------------------------------------------------
--[[ End ]]
--------------------------------------------------------------------------

end)
