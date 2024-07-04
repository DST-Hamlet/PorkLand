local AutoDartThrower = Class(function(self, inst)
    self.inst = inst
end)

function AutoDartThrower:OnEntitySleep()
    self:TurnOff()
end

function AutoDartThrower:OnEntityWake()
    if self.on then
        self:TurnOn()
    end
end

function AutoDartThrower:TurnOn()
    if self.inst.components.disarmable.armed then
        self.on = true
        self.inst:StartUpdatingComponent(self)
        if self.turnonfn then
            self.turnonfn(self.inst)
        end
    end
end

function AutoDartThrower:TurnOff()
    self.on = nil
    self.inst:StopUpdatingComponent(self)
    if self.turnofffn then
        self.turnofffn(self.inst)
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
    return data
end

function AutoDartThrower:OnLoad(data)
    if data then
        if data.on then
            self:TurnOn()
        end
    end
end

return AutoDartThrower
