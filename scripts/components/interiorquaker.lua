--------------------------------------------------------------------------
--[[ InteriorQuaker Class Definition ]]
--------------------------------------------------------------------------

return Class(function(self,inst)

--------------------------------------------------------------------------
--[[ Constants ]]
--------------------------------------------------------------------------

local DEBRIS_CHANCE_COMMON = 0.75 -- 75%
local DEBRIS_CHANCE_RARE = DEBRIS_CHANCE_COMMON + 0.2 -- 20%
local DEBRIS_CHANCE_VERY_RARE = DEBRIS_CHANCE_RARE + 0.04 -- 4%
-- local DEBRIS_CHANCE_ULTRA_RARE = DEBRIS_CHANCE_VERY_RARE + 0.01 -- 1%

local DEBRIS_LOOT = {
    COMMON = {
        "rocks",
        "flint",
    },
    RARE = {
        "mole",
        "nitre",
        "rabid_beetle",
        "scorpion",
    },
    VERY_RARE = {
        "goldnugget",
        "bluegem",
    },
    ULTRA_RARE = {
        "relic_1",
        "relic_2",
        "relic_3",
    },
}

local QUAKE_LEVELS = {
    [INTERIOR_QUAKE_LEVELS.PILLAR_WORKED] = {
        quake_time = function() return GetRandomWithVariance(1, 0.5) end,--how long the quake lasts
        debrispersecond = function() return math.random(5, 6) end,     --how much debris falls every second
        debrisbreakchance = 0.75,
        max_critters = 0,
        level = 1, -- level determines how it would affect rooms next to the one quaking
        quake_intensity = 0.6,
    },
    [INTERIOR_QUAKE_LEVELS.PILLAR_DESTROYED] = {
        quake_time = function() return math.random(5, 8) + 5 end,
        debrispersecond = function() return math.random(9, 10) end,
        debrisbreakchance = 0.95,
        max_critters = 4,
        level = 2,
        quake_intensity = 0.8,
    },
    [INTERIOR_QUAKE_LEVELS.QUEEN_ATTACK] = {
        quake_time = function() return math.random(4, 8) end,
        debrispersecond = function() return math.random(15, 20) end,
        debrisbreakchance = 0.99,
        max_critters = 1,
        critter_spawn_offset = {x = 2.5},
        level = 2,
        quake_intensity = 0.1,
    },
    [INTERIOR_QUAKE_LEVELS.MINOR_QUAKE] = {},
}

local DENSITYRADIUS = 5 -- the minimum radius that can contain 3 debris (allows for some clumping)

local SMASHABLE_TAGS = {"smashable", "quakedebris", "_combat"}
local NON_SMASHABLE_TAGS = {"INLIMBO", "playerghost", "irreplaceable", "outofreach"}
local QUAKEDEBRIS_CANT_TAGS = {"quakedebris"}
local QUAKEDEBRIS_ONEOF_TAGS = {"INLIMBO"}


--------------------------------------------------------------------------
--[[ Member variables ]]
--------------------------------------------------------------------------

-- Public
self.inst = inst

-- Private
local _ismastersim = TheWorld.ismastersim
local _world = TheWorld
local _active_players = {}
local _critters_per_quake = {} -- {[number]interiorID: [string]number of critters left to spawn in a room}
local _debris_spawn_rates = {} -- {[number]inetiorID: [number]debris_per_second}
local _debris_spawn_times = {} -- {[number]interiorID: [number]tiem to next debris spawn in a room}
local _isquaking = {} -- {[number]interiorID: [string]quake level in a room}
local _quake_times = {} -- {[number]inetiorID: [number]time left for quaking in a room}
local _tasks = {}

--------------------------------------------------------------------------
--[[ Private member functions ]]
--------------------------------------------------------------------------

local IsDebrisCritter = _ismastersim and function(prefab)
    local critters = {mole = true, rabid_beetle = true, scorpion = true}
    return critters[prefab]
end or nil

local _BreakDebris = _ismastersim and function(debris)
    local x, _, z = debris.Transform:GetWorldPosition()
    SpawnPrefab("ground_chunks_breaking").Transform:SetPosition(x, 0, z)
    debris:Remove()
end or nil

local UpdateShadowSize = _ismastersim and function(shadow, height)
    local scale_factor = Lerp(0.5, 1.5, height / 35)
    shadow.Transform:SetScale(scale_factor, scale_factor, scale_factor)
end or nil

local _GroundDetectionUpdate = _ismastersim and function(debris)
    local x, y, z = debris.Transform:GetWorldPosition()
    if y <= 0.2 then
        if not debris:IsOnValidGround() then
            debris:PushEvent("detachchild")
            debris:Remove()
        elseif _world.Map:IsPointNearHole(Vector3(x, 0, z)) then
            if IsDebrisCritter(debris.prefab) then
                debris:PushEvent("detachchild")
                debris:Remove()
            else
                _BreakDebris(debris)
            end
        else
            -- break stuff we land on
            -- NOTE: re-check validity as we iterate, since we're invalidating stuff as we go
            local softbounce = false

            local ents = TheSim:FindEntities(x, 0, z, 2, nil, NON_SMASHABLE_TAGS, SMASHABLE_TAGS)
            for _, v in pairs(ents) do
                if v ~= debris and v:IsValid() and not v:IsInLimbo() then
                    softbounce = true
                    --NOTE: "smashable" excluded for now
                    if v:HasTag("quakedebris") then
                        _BreakDebris(v)
                    elseif v.components.combat ~= nil and not (v:HasTag("epic") or v:HasTag("wall")) then
                        v.components.combat:GetAttacked(debris, 20, nil)
                    end
                end
            end

            debris.Physics:SetDamping(0.9)

            if softbounce then
                local speed = 3.2 + math.random()
                local angle = math.random() * TWOPI
                debris.Physics:SetMotorVel(0, 0, 0)
                debris.Physics:SetVel(speed * math.cos(angle), speed * 2.3, speed * math.sin(angle))
            end

            debris.shadow:Remove()
            debris.shadow = nil

            debris.updatetask:Cancel()
            debris.updatetask = nil

            --NOTE: There will always be at least one found within DENSITYRADIUS, ourself!
            if not (math.random() < 0.75 or #TheSim:FindEntities(x, 0, y, DENSITYRADIUS, nil, QUAKEDEBRIS_CANT_TAGS, QUAKEDEBRIS_ONEOF_TAGS) > 1)
                or IsDebrisCritter(debris.prefab) then -- keep it
                debris.persists = true
                debris.entity:SetCanSleep(true)
                if debris._restorepickup then
                    debris._restorepickup = nil
                    if debris.components.inventoryitem ~= nil then
                        debris.components.inventoryitem.canbepickedup = true
                    end
                end
                debris:PushEvent("stopfalling")
            elseif debris:GetTimeAlive() < 1.5 then
                --should be our first bounce
                debris:DoTaskInTime(softbounce and 0.4 or 0.6, _BreakDebris)
            else
                --we missed detecting our first bounce, so break immediately this time
                _BreakDebris(debris)
            end
        end
    elseif debris:GetTimeAlive() < 3 then
        if y < 2 then
            debris.Physics:SetMotorVel(0, 0, 0)
        end
        UpdateShadowSize(debris.shadow, y)
    elseif debris:IsInLimbo() then
        --failsafe, but maybe we got trapped or picked up somehow, so keep it
        debris.persists = true
        debris.entity:SetCanSleep(true)
        debris.shadow:Remove()
        debris.shadow = nil
        debris.updatetask:Cancel()
        debris.updatetask = nil
        if debris._restorepickup then
            debris._restorepickup = nil
            if debris.components.inventoryitem ~= nil then
                debris.components.inventoryitem.canbepickedup = true
            end
        end
        debris:PushEvent("stopfalling")
    elseif IsDebrisCritter(debris.prefab) then
        --failsafe
        debris:PushEvent("detachchild")
        debris:Remove()
    else
        --failsafe
        _BreakDebris(debris)
    end
end or nil

local OnRemoveDebris = _ismastersim and function(debris)
    debris.shadow:Remove()
end or nil

local GetTimeForNextDebris = _ismastersim and function(interiorID)
    return 1 / _debris_spawn_rates[interiorID]
end or nil

local GetDebrisSpawnPoint = _ismastersim and function(interiorID, is_critter)
    local interior_spawner = TheWorld.components.interiorspawner

    local interior_center = interior_spawner:GetInteriorCenter(interiorID)
    local center_position = interior_center:GetPosition()
    local width, depth = interior_center:GetSize()
    local offset = Vector3(0, 0, 0)

    local critter_spawn_offset = QUAKE_LEVELS[_isquaking[interiorID]].critter_spawn_offset

    if critter_spawn_offset and is_critter then
        if critter_spawn_offset.x then
            offset.x = critter_spawn_offset.x + math.random() * ((depth - critter_spawn_offset.x) / 2)
        end
        if critter_spawn_offset.z then
            offset.z = critter_spawn_offset.z + math.random() * ((width - critter_spawn_offset.z) / 2)
        end
    else
        offset = Vector3(math.random() * depth - depth / 2, 0, math.random() * width - width / 2)
    end

    return center_position + offset
end or nil

local GetDebrisPrefab = _ismastersim and function(interiorID)
    local rand = math.random()

    if rand < DEBRIS_CHANCE_COMMON then
        return GetRandomItem(DEBRIS_LOOT.COMMON)
    elseif rand < DEBRIS_CHANCE_RARE then
        local prefab = GetRandomItem(DEBRIS_LOOT.RARE)

        local attempts = 0
        while _critters_per_quake[interiorID] <= 0 and IsDebrisCritter(prefab) do -- Make sure we don't spawn a ton of critters per quake
            prefab = GetRandomItem(DEBRIS_LOOT.RARE)
            attempts = attempts + 1
            if attempts > 10 then
                break
            end
        end
        return prefab
    elseif rand < DEBRIS_CHANCE_VERY_RARE then
        return GetRandomItem(DEBRIS_LOOT.VERY_RARE)
    else
        return GetRandomItem(DEBRIS_LOOT.ULTRA_RARE)
    end
end or nil

local SpawnDebrisForRoom = _ismastersim and function(interiorID)
    local prefab = GetDebrisPrefab(interiorID)
    if not prefab then
        return
    end

    local is_critter = IsDebrisCritter(prefab)
    local spawn_point = GetDebrisSpawnPoint(interiorID, is_critter)

    if not spawn_point then
        return
    end

    local debris = SpawnPrefab(prefab)

    debris.entity:SetCanSleep(false)
    debris.persists = false

    if is_critter and debris and debris.sg then
        _critters_per_quake[interiorID] = _critters_per_quake[interiorID] - 1
        debris.sg:GoToState("fall")
    end

    if math.random() < 0.5 then
        debris.Transform:SetRotation(180)
    end

    debris.Physics:Teleport(spawn_point.x, 35, spawn_point.z)

    if debris.components.inventoryitem ~= nil and debris.components.inventoryitem.canbepickedup then
        debris.components.inventoryitem.canbepickedup = false
        debris._restorepickup = true
    end

    debris.shadow = SpawnPrefab("warningshadow")
    debris.shadow:ListenForEvent("onremove", OnRemoveDebris, debris)
    debris.shadow.Transform:SetPosition(spawn_point.x, 0, spawn_point.z)
    UpdateShadowSize(debris.shadow, 35)

    debris.updatetask = debris:DoPeriodicTask(FRAMES, _GroundDetectionUpdate)
    debris:PushEvent("startfalling")

    return debris
end or nil

local StopUpdateTask = _ismastersim and function(interiorID)
    if _tasks[interiorID] then
        _tasks[interiorID]:Cancel()
        _tasks[interiorID] = nil
    end
end or nil

local StartUpdateTask = _ismastersim and function(interiorID, time, callback)
    StopUpdateTask(interiorID)
    -- time, fn, initialdelay, dt, interiorID
    _tasks[interiorID] = inst:DoPeriodicTask(time, callback, time, time, interiorID)
end or nil

local UpdateTask = _ismastersim and function(src, dt, interiorID)
    _quake_times[interiorID] = _quake_times[interiorID] - dt
    if _quake_times[interiorID] <= 0 then
        _world:PushEvent("interior_endquake", {interiorID = interiorID})
    else
        _debris_spawn_times[interiorID] = _debris_spawn_times[interiorID] - dt
        if _debris_spawn_times[interiorID] <= 0 then
            local debris = SpawnDebrisForRoom(interiorID)
            ShakeAllCamerasInRoom(interiorID, CAMERASHAKE.FULL, 0.7, 0.02, QUAKE_LEVELS[_isquaking[interiorID]].quake_intensity, debris, 40)
            _debris_spawn_times[interiorID] = GetTimeForNextDebris(interiorID)
        end
    end
end

local StartQuakeForRoom = _ismastersim and function(src, data)
    local interiorID = data.interiorID
    if not interiorID then
        return
    end

    local quake_level = data.quake_level
    local quake_params = QUAKE_LEVELS[quake_level]
    if not quake_params then
        return
    end

    _quake_times[interiorID] = quake_params.quake_time()
    _isquaking[interiorID] = quake_level
    _critters_per_quake[interiorID] = quake_params.max_critters
    _debris_spawn_rates[interiorID] = quake_params.debrispersecond()
    _debris_spawn_times[interiorID] = GetTimeForNextDebris(interiorID)

    StartUpdateTask(interiorID, FRAMES, UpdateTask)

    TheWorld.components.interiorspawner:ForEachPlayerInRoom(interiorID, function(player)
        player.player_classified.isquaking:set(true)
    end)
end or nil

local EndQuakeForRoom = _ismastersim and function(src, data)
    local interiorID = data.interiorID
    if not interiorID then
        return
    end

    _isquaking[interiorID] = nil
    _quake_times[interiorID] = nil
    _critters_per_quake[interiorID] = nil
    _debris_spawn_rates[interiorID] = nil
    _debris_spawn_times[interiorID] = nil

    StopUpdateTask(interiorID)

    TheWorld.components.interiorspawner:ForEachPlayerInRoom(interiorID, function(player)
        player.player_classified.isquaking:set(false)
    end)
end or nil

--------------------------------------------------------------------------
--[[ Private event handlers ]]
--------------------------------------------------------------------------

local function OnQuakeSoundDirty()
    if ThePlayer.player_classified.isquaking:value() then
        if not _world.SoundEmitter:PlayingSound("earthquake") then
            _world.SoundEmitter:PlaySound("dontstarve/cave/earthquake", "earthquake")
        end
        _world.SoundEmitter:SetParameter("earthquake", "intensity", 1)
    elseif _world.SoundEmitter:PlayingSound("earthquake") then
        _world.SoundEmitter:KillSound("earthquake")
    end
end

local OnUsedDoor = _ismastersim and function(player, data)
    if not data.door then
        return
    end

    local target_interior = data.door.components.door.target_interior
    if data.exterior or not _isquaking[target_interior] then
        player.player_classified.isquaking:set(false)
    else
        player.player_classified.isquaking:set(true)
    end
end or nil

local OnPlayerJoined = _ismastersim and function(src, player)
    for i, v in ipairs(_active_players) do
        if v == player then
            return
        end
    end
    table.insert(_active_players, player)

    local x, _ ,z = player.Transform:GetWorldPosition()
    if TheWorld.components.interiorspawner:IsInInteriorRegion(x, z) then
        local room_id = TheWorld.components.interiorspawner:PositionToIndex({x = x, z = z})
        if _isquaking[room_id] then
            player.player_classified.isquaking:set(true)
        end
    end

    player:ListenForEvent("used_door", OnUsedDoor)
end or nil

local OnPlayerLeft = _ismastersim and function(src, player)
    for i, v in ipairs(_active_players) do
        if v == player then
            player:RemoveEventCallback("used_door", OnUsedDoor)
            table.remove(_active_players, i)
            return
        end
    end
end or nil

--------------------------------------------------------------------------
--[[ Public member functions ]]
--------------------------------------------------------------------------

function self:IsRoomQuaking(interiorID)
    return _isquaking[interiorID] ~= nil
end

--------------------------------------------------------------------------
--[[ Initialization ]]
--------------------------------------------------------------------------

if not TheNet:IsDedicated() then
    inst:ListenForEvent("isquakingdirty", OnQuakeSoundDirty, ThePlayer)
end

if _ismastersim then
    inst:ListenForEvent("interior_startquake", StartQuakeForRoom, _world)
    inst:ListenForEvent("interior_endquake", EndQuakeForRoom, _world)
    inst:ListenForEvent("ms_playerjoined", OnPlayerJoined, _world)
    inst:ListenForEvent("ms_playerleft", OnPlayerLeft, _world)
end

--------------------------------------------------------------------------
--[[ Save/Load ]]
--------------------------------------------------------------------------

if _ismastersim then function self:OnSave()
    return {
        critters_per_quake = _critters_per_quake,
        debris_spawn_rates = _debris_spawn_rates,
        debris_spawn_times = _debris_spawn_times,
        isquaking = _isquaking,
        quake_times = _quake_times,
    }
end end

if _ismastersim then function self:OnLoad(data)
    if not data then
        return
    end
    _critters_per_quake = data.critters_per_quake
    _debris_spawn_rates = data.debris_spawn_rates
    _debris_spawn_times = data.debris_spawn_times
    _isquaking = data.isquaking
    _quake_times = data.quake_times
end end

--------------------------------------------------------------------------
--[[ Debug ]]
--------------------------------------------------------------------------

--------------------------------------------------------------------------
--[[ End ]]
--------------------------------------------------------------------------

end)
