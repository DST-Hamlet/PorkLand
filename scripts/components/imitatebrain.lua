local ImitateBrain = Class(function(self, inst)
    self.inst = inst

    self.updatetime = 5

    self.currentbraindata = {}

    self.behaviors =
    {
        ["idle"] = {}
    }
    self.currentbehavior = nil

    self.choosebrainfn = function(self, inst)
        return "idle"
    end

    self.currentbehaviordata = {}
end)

function ImitateBrain:Start()
    if not self.imitatetask then
        local updatetime = self.updatetime + self.updatetime * random()
        self.imitatetask = self.inst:DoTaskInTime(updatetime, function() self:UpdateBrain(updatetime) end)
    end
end

function ImitateBrain:UpdateBrain(dt)
    if self.currentbehavior == nil then
        local newbehavior = self:choosebrainfn(inst)
        self:GoToBehavior(newbehavior)
    end
    if self.behaviors[self.currentbehavior] then
        if self.behaviors[self.currentbehavior].updatefn then
            self.behaviors[self.currentbehavior].updatefn(self.inst, dt, self.currentbehaviordata, self.currentbraindata)
        end
    else
        print("WARNING: ImitateBrain.currentbehavior is not valid", self.currentbehavior)
        self.currentbehavior = nil
    end
    if self.imitatetask then
        self.imitatetask = nil
    end
    local updatetime = self.updatetime + self.updatetime * random()
    self.imitatetask = self.inst:DoTaskInTime(updatetime, function() self:UpdateBrain(updatetime) end)
end

function ImitateBrain:GoToBehavior(behaviorname)
    if self.behaviors[behaviorname] then
        if self.behaviors[self.currentbehavior].exitfn then
            self.behaviors[self.currentbehavior].exitfn(self.inst, self.currentbehaviordata, self.currentbraindata)
        end
        self.currentbehavior = behaviorname
        self.currentbehaviordata = {}
        if self.behaviors[self.currentbehavior].enterfn then
            self.behaviors[self.currentbehavior].enterfn(self.inst, self.currentbehaviordata, self.currentbraindata)
        end
    else
        print("WARNING: behaviorname in ImitateBrain:GoToBehavior is not valid", self.behaviorname)
        self.currentbehavior = "idle"
    end
end

return ImitateBrain
