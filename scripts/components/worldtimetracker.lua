-- Tracks the time passed without getting affected by the world's clock
-- but does account to rollbacks
local WorldTimeTracker = Class(function(self, inst)
    self.inst = inst

    self.sim_time_on_load = 0
    self.time_passed = 0
end)

function WorldTimeTracker:GetTime()
    return self.time_passed + GetTime() - self.sim_time_on_load
end

function WorldTimeTracker:OnSave()
    return {
        time_passed = self:GetTime()
    }
end

function WorldTimeTracker:OnLoad(data)
    self.sim_time_on_load = GetTime()
    if data then
        self.time_passed = data.time_passed
    end
end

return WorldTimeTracker
