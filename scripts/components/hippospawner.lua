--------------------------------------------------------------------------
--[[ Dependencies ]]
--------------------------------------------------------------------------

--------------------------------------------------------------------------
--[[ HippoSpawner class definition ]]
--------------------------------------------------------------------------
return Class(function(self, inst)

assert(TheWorld.ismastersim, "HippoSpawner should not exist on client")

--------------------------------------------------------------------------
--[[ Private constants ]]
--------------------------------------------------------------------------

local SPAWN_DELAY = 60
local FIND_HIPPO_MATE_RANGE = 32
local FIND_HIPPO_MEMBER_RANGE = 48
local SPAWN_HIPPO_RADIUS = 24
local MIN_HIPPO_DISTANCE = 12
local MIN_PLAYER_DISTANCE = 64 * 1.2 -- this is our "outer" sleep radius
local HIPPO_TIMERNAME = "HIPPO_REPRODUCE_TIMER_"

--------------------------------------------------------------------------
--[[ Public Member Variables ]]
--------------------------------------------------------------------------

self.inst = inst

--------------------------------------------------------------------------
--[[ Private Member Variables ]]
--------------------------------------------------------------------------

local _hippos = {}
local _on_hippo_removed
local _worldsettingstimer = TheWorld.components.worldsettingstimer

--------------------------------------------------------------------------
--[[ Private member functions ]]
--------------------------------------------------------------------------

local function GetTimerName(ent)
    return HIPPO_TIMERNAME .. ent.GUID
end

local function OnHippoRemoved(hippo)
    _worldsettingstimer:StopTimer(GetTimerName(hippo))
    _hippos[hippo] = nil
end

local function CanSpawnNewHippo(hippo)
    if not hippo:IsValid() then
        return false, nil, nil
    end

    if not hippo.components.amphibiouscreature.in_water then
        return false, nil, nil
    end

    local hippos_in_range = 0
    local mate
    for _hippo in pairs(_hippos) do
        if _hippo ~= hippo then
            if hippo:GetDistanceSqToInst(_hippo) <= FIND_HIPPO_MATE_RANGE * FIND_HIPPO_MATE_RANGE then
                hippos_in_range = hippos_in_range + 1
                if not mate and not _hippo.is_dummy_prefab and _worldsettingstimer:GetTimeLeft(GetTimerName(_hippo)) <= SPAWN_DELAY then
                    mate = _hippo
                end
            elseif hippo:GetDistanceSqToInst(_hippo) <= FIND_HIPPO_MEMBER_RANGE * FIND_HIPPO_MEMBER_RANGE then
                hippos_in_range = hippos_in_range + 1
            end
        end
        if hippos_in_range >= 5 then
            return false, nil, nil
        end
    end

    local function is_valid_spawn_point(point)
        local ents = TheSim:FindEntities(point.x, point.y, point.z, MIN_HIPPO_DISTANCE, {"hippopotamoose"})
        return not next(ents)
    end
    local x, y, z = hippo.Transform:GetWorldPosition()
    local offset = FindSwimmableOffset(Vector3(x, y, z), math.random() * 2 * PI, SPAWN_HIPPO_RADIUS, 10, true, false, is_valid_spawn_point)
        or FindWalkableOffset(Vector3(x, y, z), math.random() * 2 * PI, SPAWN_HIPPO_RADIUS, 10, true, false, is_valid_spawn_point)
        or nil

    if mate ~= nil and hippos_in_range < 5 and offset ~= nil then
        return true, mate, offset
    else
        return false, nil, nil
    end
end

--------------------------------------------------------------------------
--[[ Public member functions ]]
--------------------------------------------------------------------------

function self:SpawnHippo(hippo)
    local can_spawn, mate, offset = CanSpawnNewHippo(hippo)
    if can_spawn then
        local start_position = hippo:GetPosition()
        local spawn_point = start_position + offset
        local player_in_range = IsAnyPlayerInRangeSq(spawn_point.x, spawn_point.y, spawn_point.z, MIN_PLAYER_DISTANCE * MIN_PLAYER_DISTANCE)
        local new_hippo = SpawnPrefab(player_in_range and "hippopotamoose_newborn" or "hippopotamoose")
        new_hippo.Transform:SetPosition(spawn_point.x, 0, spawn_point.z)
        if player_in_range then
            -- Add the place holder to the hippo table so they would stop reproducing
            _hippos[new_hippo] = new_hippo
        end

        _worldsettingstimer:StopTimer(GetTimerName(mate))
        _worldsettingstimer:StartTimer(GetTimerName(mate), GetRandomWithVariance(TUNING.HIPPO_MATING_SEASON_BABYDELAY, TUNING.HIPPO_MATING_SEASON_BABYDELAY_VARIANCE))
        _worldsettingstimer:StopTimer(GetTimerName(hippo))
        _worldsettingstimer:StartTimer(GetTimerName(hippo), GetRandomWithVariance(TUNING.HIPPO_MATING_SEASON_BABYDELAY, TUNING.HIPPO_MATING_SEASON_BABYDELAY_VARIANCE))
    else
        _worldsettingstimer:StopTimer(GetTimerName(hippo))
        _worldsettingstimer:StartTimer(GetTimerName(hippo), SPAWN_DELAY)
    end
end

function self:AddHippo(hippo)
    local time = GetRandomWithVariance(TUNING.HIPPO_MATING_SEASON_BABYDELAY, TUNING.HIPPO_MATING_SEASON_BABYDELAY_VARIANCE)
    local max_time = TUNING.HIPPO_MATING_SEASON_BABYDELAY + TUNING.HIPPO_MATING_SEASON_BABYDELAY_VARIANCE

    _hippos[hippo] = hippo
    _worldsettingstimer:AddTimer(GetTimerName(hippo), max_time, true, function()
        self:SpawnHippo(hippo)
    end)
    _worldsettingstimer:StartTimer(GetTimerName(hippo), time)
    hippo:ListenForEvent("onremove", OnHippoRemoved)
end

function self:RemoveHippo(hippo, isdummy)
    if isdummy then
        _hippos[hippo] = nil
        return
    end

    _worldsettingstimer:StopTimer(HIPPO_TIMERNAME .. hippo.GUID)
    if hippo:IsValid() then
        hippo:RemoveEventCallback("onremove", OnHippoRemoved)
    end
end

--------------------------------------------------------------------------
--[[ Debug ]]
--------------------------------------------------------------------------

function self:GetDebugString()
    return string.format("Number of hippos: %d", GetTableSize(_hippos))
end

end)
