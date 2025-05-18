local AutoDartThrower = Class(function(self, inst)
    self.inst = inst
end)

function AutoDartThrower:TurnOn(time)
    if self.inst.components.disarmable.armed then
        self.on = true
        self.inst:StartUpdatingComponent(self)
        if self.turnonfn then
            self.turnonfn(self.inst)
        end

        if self.task then
            self.task:Cancel()
            self.task, self.taskinfo = nil
        end
        self.task, self.taskinfo = self.inst:ResumeTask(time or 15, function() self:TurnOff() end)
    end
end

function AutoDartThrower:TurnOff()
    self.on = nil
    self.inst:StopUpdatingComponent(self)
    if self.turnofffn then
        self.turnofffn(self.inst)
    end

    if self.task then
        self.task:Cancel()
        self.task, self.taskinfo = nil
    end
end

function AutoDartThrower:OnUpdate(dt)
    if self.updatefn then
        self.updatefn(self.inst,dt)
    end
end

function AutoDartThrower:OnSave()
    local data = {}

    data.on = self.on

    if self.taskinfo ~= nil then
        data.tasktime = self.inst:TimeRemainingInTask(self.taskinfo)
    end
    return data
end

function AutoDartThrower:OnLoad(data)
    if data then
        if data.on then
            self:TurnOn(data.tasktime or 15)
        end
    end
end

return AutoDartThrower
