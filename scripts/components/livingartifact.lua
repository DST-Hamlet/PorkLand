local LivingArtifact = Class(function(self, inst)
    self.inst = inst

    self.active = false

    self.total_time = TUNING.IRON_LORD_TIME
    self.time_left = TUNING.IRON_LORD_TIME

    self.onactivatefn = nil
    self.ondeltafn = nil
    self.onfinishfn = nil
end)

function LivingArtifact:SetOnActivateFn(fn)
    self.onactivatefn = fn
end

function LivingArtifact:SetOnDeltaFn(fn)
    self.ondeltafn = fn
end

function LivingArtifact:SetOnFinishedFn(fn)
    self.onfinishfn = fn
end

function LivingArtifact:GetPercent()
    return self.total_time > 0 and math.max(0, math.min(1, self.time_left / self.total_time)) or 0
end

function LivingArtifact:SetPercent(percentage)
    local target = self.total_time * percentage
    self:DoDelta(target - self.time_left)
end

function LivingArtifact:DoDelta(amount)
    self.time_left = math.max(0, math.min(self.total_time, self.time_left + amount))

    if self.ondeltafn then
        self.ondeltafn(self.inst)
    end

    if self.time_left <= 0 then
        if self.onfinishfn then
            self.onfinishfn(self.inst)
        end
        self.inst:StopUpdatingComponent(self)
    end
end

function LivingArtifact:Activate(doer, instant)
    if self.onactivatefn then
        self.onactivatefn(self.inst, doer, instant)
    end
    if instant then
        return
    end
    self.inst:StartUpdatingComponent(self)
end

function LivingArtifact:OnUpdate(dt)
    self:DoDelta(-dt)
end

function LivingArtifact:OnSave()
    return {
        active = self.inst:HasTag("enabled"),
        time_left = self.time_left,
    }
end

function LivingArtifact:OnLoad(data)
    if data and data.active then
        self.time_left = math.max(0, math.min(self.total_time, data.time_left))
    end
end

return LivingArtifact
