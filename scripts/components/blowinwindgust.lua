local BlowInWindGust = Class(function(self, inst)
    self.inst = inst
    self.startfn = nil
    self.endfn = nil
    self.destroyfn = nil
    self.state = 0
    self.windspeedthreshold = 0
    self.destroychance = 0.01
    self.task = nil
end)

function BlowInWindGust:OnRemoveEntity()
    self:Stop()
end

function BlowInWindGust:OnRemoveFromEntity()
    self:Stop()
end

local function UpdateTask(inst, dt)
    if not inst or not inst:IsValid() then
        return
    end

    local self = inst.components.blowinwindgust
    local windspeed = TheWorld.net.components.plateauwind and TheWorld.net.components.plateauwind:GetWindSpeed() or 0
    if self.state == 0 then
        if windspeed > self.windspeedthreshold then
            if math.random() < self.destroychance and inst:IsNearPlayer(TUNING.WINDBLOWN_DESTROY_DIST) then
                self:CallDestroyFn()
                self:Stop()
                return
            else
                inst:PushEvent("blownbywind")
            end
            self:CallGustStartFn(windspeed)
            self.state = 1
        end
    elseif self.state == 1 then
        if windspeed < self.windspeedthreshold then
            self:CallGustEndFn(windspeed)
            self.state = 0
        end
    end
    self:Stop()
    self:Start()
end

function BlowInWindGust:Start()
    if self.task == nil then
        local dt = math.random() * 0.5 + 1.0
        self.task = self.inst:DoTaskInTime(dt, UpdateTask, dt)
    end
end

function BlowInWindGust:Stop()
    if self.task then
        self.task:Cancel()
    end
    self.task = nil
end

function BlowInWindGust:OnEntitySleep()
    if self.state == 1 then
        self:CallGustEndFn(0)
    end
    self.state = 0
    self:Stop()
end

function BlowInWindGust:OnEntityWake()
    self.state = 0
    self:Start()
end

function BlowInWindGust:SetWindSpeedThreshold(windspeed)
    self.windspeedthreshold = windspeed
end

function BlowInWindGust:SetDestroyChance(chance)
    self.destroychance = chance
end

function BlowInWindGust:IsGusting()
    return self.state == 1
end

function BlowInWindGust:SetGustStartFn(fn)
    self.startfn = fn
end

function BlowInWindGust:CallGustStartFn(windspeed)
    if self.startfn then
        self.startfn(self.inst, windspeed)
    end
end

function BlowInWindGust:SetGustEndFn(fn)
    self.endfn = fn
end

function BlowInWindGust:CallGustEndFn(windspeed)
    if self.endfn then
        self.endfn(self.inst, windspeed)
    end
end

function BlowInWindGust:SetDestroyFn(fn)
    self.destroyfn = fn
end

function BlowInWindGust:CallDestroyFn()
    if self.destroyfn then
        self.destroyfn(self.inst)
    end
end

return BlowInWindGust
