local ImitateBrain = Class(function(self, inst)
    self.inst = inst

    self.updatetime = 5

    self.currentbraindata = {}

    self.behaviors =
    {
        ["idle"] = {}
    }
    self.currentbehavior = "idle"

    self.currentbehaviordata = {}
end)

function ImitateBrain:Start()
    if not self.imitatetask then
        self.imitatetask = self.inst:DoPeriodicTask(updatetime, function() self:UpdateBrain(updatetime) end, updatetime * math.random())
    end
end

function ImitateBrain:UpdateBrain(dt)
    if self.behaviors[self.currentbehavior] then
        if self.behaviors[self.currentbehavior].updatefn then
            self.behaviors[self.currentbehavior].updatefn(self.inst, dt, self.currentbehaviordata, self.currentbraindata)
        end
    else
        print("WARNING: ImitateBrain.currentbehavior is not valid", self.currentbehavior)
        self.currentbehavior = "idle"
    end
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
