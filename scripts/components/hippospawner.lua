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
local FIND_HIPPO_MEMBER_RANGE = 40
local SPAWN_HIPPO_RADIUS = 24
local MIN_HIPPO_DISTANCE = 16
local MIN_PLAYER_DISTANCE = 64 * 1.2 -- this is our "outer" sleep radius
local HIPPO_TIMERNAME = "HIPPO_REPRODUCE_TIMER_"
local MAX_HIPPO_NUM = 5

--------------------------------------------------------------------------
--[[ Public Member Variables ]]
--------------------------------------------------------------------------

self.inst = inst

--------------------------------------------------------------------------
--[[ Private Member Variables ]]
--------------------------------------------------------------------------

local _hippos = {}
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

local function FindHippos(x, y, z, radius)
    local hippos_in_range = {}
    for _hippo in pairs(_hippos) do
        if _hippo:GetDistanceSqToPoint(x, y, z) <= radius * radius then
            table.insert(hippos_in_range, _hippo)
        end
    end
    return hippos_in_range
end

local function CanSpawnNewHippo(hippo)
    if not hippo:IsValid() then
        return false, nil, nil
    end

    if not hippo.components.amphibiouscreature.in_water then
        return false, nil, nil
    end

    local mate
    local min_mate_distsq = FIND_HIPPO_MATE_RANGE * FIND_HIPPO_MATE_RANGE
    for _hippo in pairs(_hippos) do
        if _hippo ~= hippo then
            local hippo_distsq = hippo:GetDistanceSqToInst(_hippo)
            if hippo_distsq <= min_mate_distsq
                and not _hippo.is_dummy_prefab
                and _worldsettingstimer:GetTimeLeft(GetTimerName(_hippo)) <= SPAWN_DELAY then

                mate = _hippo
            end
        end
    end

    local x, y, z = hippo.Transform:GetWorldPosition()
    local ents = FindHippos(x, y, z, FIND_HIPPO_MEMBER_RANGE)
    local hippos_num = MAX_HIPPO_NUM * TheWorld.Map:CalcPercentTilesAtPoint(x, y, z, FIND_HIPPO_MEMBER_RANGE,
        function(_x, _y, _z, map)
            return TheWorld.Map:GetTileAtPoint(_x, _y, _z) == WORLD_TILES.LILYPOND
        end)
    hippos_num = math.max(hippos_num, 3)

    if #ents >= hippos_num then
        return false, nil, nil
    end

    local function is_valid_spawn_point(point)
        local close_ents = FindHippos(point.x, point.y, point.z, MIN_HIPPO_DISTANCE)
        if next(close_ents) then
            return false
        end
        return true
    end

    local offset = FindSwimmableOffset(Vector3(x, y, z), math.random() * 2 * PI, SPAWN_HIPPO_RADIUS, 10, true, false, is_valid_spawn_point)

    if mate ~= nil and offset ~= nil then
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
        _worldsettingstimer:StartTimer(GetTimerName(hippo), SPAWN_DELAY * (0.5 + math.random() * 0.5))
    end
end

function self:AddHippo(hippo)
    local time = GetRandomWithVariance(TUNING.HIPPO_MATING_SEASON_BABYDELAY, TUNING.HIPPO_MATING_SEASON_BABYDELAY_VARIANCE)
    local max_time = TUNING.HIPPO_MATING_SEASON_BABYDELAY + TUNING.HIPPO_MATING_SEASON_BABYDELAY_VARIANCE

    _hippos[hippo] = hippo
    _worldsettingstimer:AddTimer(GetTimerName(hippo), max_time, TUNING.HIPPO_ENABLED, function()
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

function self:FindHippos(x, y, z, radius)
    return FindHippos(x, y, z, radius)
end

--------------------------------------------------------------------------
--[[ Debug ]]
--------------------------------------------------------------------------

function self:GetDebugString()
    return string.format("Number of hippos: %d", GetTableSize(_hippos))
end

end)
