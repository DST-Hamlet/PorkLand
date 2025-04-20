GLOBAL.setfenv(1, GLOBAL)

local TIMESCALE_TAG_BASE = {"working", "doing"}
local TIMESCALE_TAG_NORIDING = {"attack", "moving"}

local _GoToState = StateGraphInstance.GoToState
StateGraphInstance.GoToState = function(self, statename, params, ...)
    local state = self.sg.states[statename]

    self.has_timescale_tag = nil
    for k, v in pairs(TIMESCALE_TAG_BASE) do
        if state.tags[v] then
            self.has_timescale_tag = true
        end
    end
    if not (self.inst.replica.rider and self.inst.replica.rider:IsRiding()) then
        for k, v in pairs(TIMESCALE_TAG_NORIDING) do
            if state.tags[v] then
                self.has_timescale_tag = true
            end
        end
    end

    if self.inst._actionspeed and self.has_timescale_tag then
        if self.inst.AnimState then
            self.inst.AnimState:SetDeltaTimeMultiplier(self.inst._actionspeed)
        end
        self.enabletimescale = true
    else
        if self.inst.AnimState then
            self.inst.AnimState:SetDeltaTimeMultiplier(1)
        end
        self.enabletimescale = nil
    end

    if self.currentstate and self.inst == ThePlayer then
        if self.lastgotostatetime == nil then
            self.lastgotostatetime = 0
        end
        self.lastgotostatetime = GetTime()
    end

    self.nextstate = statename
    _GoToState(self, statename, params, ...)
    self.nextstate = nil
end

local _SetTimeout = StateGraphInstance.SetTimeout
function StateGraphInstance:SetTimeout(time, ...)
    if self.inst._actionspeed and self.has_timescale_tag then
        local newtime = (math.floor((time / self.inst._actionspeed) / FRAMES) + 1) * FRAMES
        return _SetTimeout(self, newtime)
    end
    return _SetTimeout(self, time, ...)
end

local _Update = StateGraphInstance.Update
function StateGraphInstance:Update(...)
    local force_nextupdate = false
    if self.inst._actionspeed and self.enabletimescale then
        force_nextupdate = true

        local timescale = self.inst._actionspeed

        local dt = 0
        if self.lastupdatetime then
            dt = GetTime() - self.lastupdatetime
        end

        self.timeinstate = self.timeinstate + dt * (timescale - 1)
    end

    local ref = _Update(self, ...)
    return force_nextupdate and 0 or ref
end
