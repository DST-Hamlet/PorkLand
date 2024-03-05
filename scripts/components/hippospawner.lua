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
local FIND_HIPPO_MATE_RANGE = 40
local FIND_HIPPO_MEMBER_RANGE = 60
local SPAWN_HIPPO_RADIUS = 20
local MIN_PLAYER_DISTANCE = 64 * 1.2 -- this is our "outer" sleep radius
local HIPPO_TIMERNAME = "hippo_spawn_timer_"

--------------------------------------------------------------------------
--[[ Public Member Variables ]]
--------------------------------------------------------------------------

self.inst = inst

--------------------------------------------------------------------------
--[[ Private Member Variables ]]
--------------------------------------------------------------------------

local _hippos = {}
local _timers = {}
local _on_hippo_removed

--------------------------------------------------------------------------
--[[ Private member functions ]]
--------------------------------------------------------------------------

local function TimerExistForHippo(hippo)
    return _hippos[hippo] ~= nil and _timers[HIPPO_TIMERNAME .. hippo.GUID] ~= nil
end

local function GetTimeLeftForHippo(hippo)
    if not TimerExistForHippo(hippo) then
        return
    else
        local timer_name = HIPPO_TIMERNAME .. hippo.GUID
        _timers[timer_name].timeleft = _timers[timer_name].end_time - GetTime()
        return _timers[timer_name].timeleft
    end
end

local function SetTimeLeft(hippo, time)
    if not TimerExistForHippo(hippo) then
        return
    else
        GetTimeLeftForHippo(inst)

        local timer_name = HIPPO_TIMERNAME .. hippo.GUID
        _timers[timer_name].timer:Cancel()
        _timers[timer_name].timer = nil
        _timers[timer_name].timeleft = math.max(0, time)
        _timers[timer_name].timer = self.inst:DoTaskInTime(_timers[timer_name].timeleft, function() self:SpawnHippo(hippo) end)
        _timers[timer_name].end_time = GetTime() + _timers[timer_name].timeleft
    end
end

local function StartTimerForHippo(hippo, time)
    time = time or GetRandomWithVariance(TUNING.HIPPO_MATING_SEASON_BABYDELAY, TUNING.HIPPO_MATING_SEASON_BABYDELAY_VARIANCE)
    _timers[HIPPO_TIMERNAME .. hippo.GUID] = {
        start_time = GetTime(),
        end_time = GetTime() + time,
        timeleft = time,
        timer = self.inst:DoTaskInTime(time, function() self:SpawnHippo(hippo) end),
        hippo = hippo
    }
end

local function StopTimerForHippo(hippo)
    if TimerExistForHippo(hippo) then
        local timer_name = HIPPO_TIMERNAME .. hippo.GUID
        _timers[timer_name].timer:Cancel()
        _timers[timer_name].timer = nil
        _timers[timer_name] = nil
    end
end

local function CanSpawnNewHippo(hippo)
    if not hippo:IsValid() then
        return false
    end

    if not hippo.components.amphibiouscreature.in_water then
        return false
    end

    local hippos_in_range = 0
    local mate
    for _, _hippo in pairs(_hippos) do
        if _hippo ~= hippo then
            if hippo:GetDistanceSqToInst(_hippo) <= FIND_HIPPO_MATE_RANGE * FIND_HIPPO_MATE_RANGE then
                hippos_in_range = hippos_in_range + 1
                if not mate and GetTimeLeftForHippo(_hippo) <= SPAWN_DELAY then
                    mate = _hippo
                end
            elseif hippo:GetDistanceSqToInst(_hippo) <= FIND_HIPPO_MEMBER_RANGE * FIND_HIPPO_MEMBER_RANGE then
                hippos_in_range = hippos_in_range + 1
            end
        end
        if hippos_in_range >= 5 then
            return false
        end
    end

    if mate ~= nil and hippos_in_range < 5 then
        return true, mate
    end
end

--------------------------------------------------------------------------
--[[ Public member functions ]]
--------------------------------------------------------------------------

function self:SpawnHippo(hippo)
    local can_spawn, mate = CanSpawnNewHippo(hippo)
    if can_spawn then
        local start_position = hippo:GetPosition()
        local offset = FindSwimmableOffset(start_position, math.random() * 2 * PI, SPAWN_HIPPO_RADIUS)
            or FindWalkableOffset(start_position, math.random() * 2 * PI, SPAWN_HIPPO_RADIUS)
            or Vector3(0, 0, 0)

        local spawn_point = start_position + offset
        local new_hippo = SpawnPrefab(IsAnyPlayerInRangeSq(spawn_point.x, spawn_point.y, spawn_point.z,
            MIN_PLAYER_DISTANCE * MIN_PLAYER_DISTANCE) and "hippopotamoose_newborn" or "hippopotamoose")
        new_hippo.Transform:SetPosition(spawn_point.x, 0, spawn_point.z)

        StopTimerForHippo(mate)
        StartTimerForHippo(mate)
        StopTimerForHippo(hippo)
        StartTimerForHippo(hippo)
    else
        StopTimerForHippo(hippo)
        StartTimerForHippo(hippo, SPAWN_DELAY)
    end
end

function self:AddHippo(hippo)
    _hippos[hippo] = hippo
    StartTimerForHippo(hippo)
    hippo:ListenForEvent("onremove", _on_hippo_removed)
end

-- Realistically you wouldn't call this method
function self:RemoveHippo(hippo)
    StopTimerForHippo(hippo)
    if hippo:IsValid() then
        hippo:RemoveEventCallback("onremove", _on_hippo_removed)
    end
end

function self:OnSave()
    local data = {}
    local references = {}

    for k, v in pairs(_timers) do
        if data.timers == nil then
            data.timers = {}
        end
        data.timers[k] =
        {
            timeleft = GetTimeLeftForHippo(v.hippo),
            hippoid = v.hippo.GUID
        }
    end

    for k, v in pairs(_hippos) do
        if data.hippos == nil then
            data.hippos = { v.GUID }
        else
            table.insert(data.hippos, v.GUID)
        end

        table.insert(references, v.GUID)
    end

    return data, references
end

function self:LoadPostPass(newents, savedata)
    if savedata.timers ~= nil then
        for i, timer in ipairs(savedata.timers) do
            local hippo = newents[timer.hippoid]
            if hippo ~= nil then
                StopTimerForHippo(hippo)
                StartTimerForHippo(hippo, timer.timeleft)
            end
        end
    end
end

function self:LongUpdate(dt)
    for k, v in pairs(_timers) do
        SetTimeLeft(v.hippo, GetTimeLeftForHippo(v.hippo) - dt)
    end
end

--------------------------------------------------------------------------
--[[ Private event handlers ]]
--------------------------------------------------------------------------


function self:GetDebugString()
    local s = ""
    for k,v in pairs(_hippos) do
        s = string.format("%s %s %s\n", s ,tostring(k), tostring(v))
    end
    return s
end

_on_hippo_removed = function() StopTimerForHippo(inst) end

end)
