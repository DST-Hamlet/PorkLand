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

--------------------------------------------------------------------------
--[[ Member variables ]]
--------------------------------------------------------------------------

-- Public
self.inst = inst

-- Private
local _spawnmode = "normal"
local _active_players = {}
local _batcaves = {}
local _bats = {}
local _bats_to_attack = {}
local _bat_count = 0
local _bat_regen_time = 0
local _bat_attack_time = 0
local _bat_per_player = 0
local _time_modifiers = SourceModifierList(inst, 1)

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

local function OnPlayerJoined(src, player)
    for _, v in ipairs(_active_players) do
        if v == player then
            return
        end
    end
    table.insert(_active_players, player)
end

local function OnPlayerLeft(src, player)
    for i, v in ipairs(_active_players) do
        if v == player then
            table.remove(_active_players, i)
            return
        end
    end
end

-- Spawns a bat in a random bat cave
local function AddBatToCaves()
    local bat_count = self:GetNumBats()
    if bat_count >= MAX_BAT_COUNT then
        return
    end

    local interiorID = GetRandomItem(_batcaves)
    local bat_cave = TheWorld.components.interiorspawner:GetInteriorByIndex(interiorID)
    local width = bat_cave.size_net.width:value()
    local depth = bat_cave.size_net.depth:value()
    local offset = {x = math.random() * width - width / 2, z = math.random() * depth - depth / 2} -- TODO adjust position

    local bat = TheWorld.components.interiorspawner:SpawnObject(interiorID, "vampirebat")
    if bat then
        OnBatSpawned(bat)
        bat.sg:GoToState("flyout", offset)
    end
end

local function GetNextRegenTime()
    local day = TheWorld.state.cycles
    local time = 130

    if day < 5 then
        time = 960 -- 1 bat every 2 days
    elseif day < 10 then
        time = 720 -- 1 bat every 1.5 days
    elseif day < 20 then
        time = 480 -- 1 bat a day
    elseif day < 40 then
        time = 360 -- 1.5 bats / day
    else
        time = 240 -- 2 bats / day
    end

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
    local suitable_bat_count = 0
    for _, bat in pairs(_bats) do
        if IsBatSuitableForAttack(bat) then
            _bats_to_attack[#_bats_to_attack + 1] = bat
            suitable_bat_count = suitable_bat_count + 1
        end
    end

    -- Equally split among all players, each player gets at least 1 bat,
    -- if there are less bats than players, some players will not be attacked
    _bat_per_player = math.min(math.floor(suitable_bat_count / GetTableSize(_active_players)), 1)
end

local function GetSpawnPointForPlayer(player)
    local pt = player:GetPosition()
    local angle = math.random() * 2 * PI
    local radius = BAT_SPAWN_DIST

    -- check walls, allow water
    local offset = FindWalkableOffset(pt, angle, math.random() * radius, 12, true, false, nil, true)

    if offset then
        return pt + offset
    end
end

---@return boolean no_bat_left whether there are bats left for attack
local function SpawnBatsForPlayer(player)
    if not next(_bats_to_attack) then
        return true
    end

    if player:HasTag("inside_interior") then
        return false
    end

    player:DoTaskInTime(5, function() player.components.talker:Say(GetString(player.prefab, "ANNOUCE_BATS")) end)

    local num_spawned = 0
    local mark_for_remove = {}
    for key, bat in pairs(_bats_to_attack) do
        if num_spawned >= _bat_per_player then
            break
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
        end
    end

    for _, key in pairs(mark_for_remove) do
        -- TODO run to door action
        _bats_to_attack[key]:Remove()
        _bats_to_attack[key] = nil
    end

    return false
end

--------------------------------------------------------------------------
--[[ Initialization ]]
--------------------------------------------------------------------------

-- Initialize variables
for i, v in ipairs(AllPlayers) do
    table.insert(_active_players, v)
end
_bat_attack_time = GetNextAttackTime()
_bat_regen_time = GetNextRegenTime()

-- Register events
inst:ListenForEvent("ms_playerjoined", OnPlayerJoined, TheWorld)
inst:ListenForEvent("ms_playerleft", OnPlayerLeft, TheWorld)

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
    local bat_cave_center = TheWorld.components.interiorspawner:GetInteriorByIndex(interiorID)
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

    _bat_attack_time = _bat_attack_time - dt
    if _bat_attack_time <= 0 then
        CollectBatsForAttack()
        if next(_bats_to_attack) then
            local no_bat_left
            for _, player in pairs(_active_players) do
                no_bat_left = SpawnBatsForPlayer(player)
                if no_bat_left then
                    break
                end
            end
            _bats_to_attack = {} -- reset it since all bats were removed from table
        end

        _bat_attack_time = GetNextAttackTime()
    end

    -- slowly fill bat caves on a timer. 
    _bat_regen_time = _bat_regen_time -dt
    if _bat_regen_time <= 0 then
        AddBatToCaves()
        _bat_regen_time = GetNextRegenTime()
    end
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
            CollectBatsForAttack()
            if next(_bats_to_attack) then
                local no_bat_left
                for _, player in pairs(_active_players) do
                    no_bat_left = SpawnBatsForPlayer(player)
                    if no_bat_left then
                        break
                    end
                end
                _bats_to_attack = {} -- reset it since all bats were removed
            end

            _bat_attack_time = GetNextAttackTime()
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

    _bat_attack_time = data.bat_attack_time
    _bat_regen_time = data.bat_regen_time
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
--[[ Debug ]]
--------------------------------------------------------------------------

function self:GetDebugString()
    local s = ""
    s = string.format("Bat count: %d Regen In: %2.0fs Next attack in: %2.0fs", _bat_count, _bat_regen_time, _bat_attack_time)
    return s
end

function self:ForceBatAttack()
    _bat_attack_time = 0
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
