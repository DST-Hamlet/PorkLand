local GiantBrainController = Class(function(self, inst)
    self.inst = inst

    self.currentbraindata = {}

    self.behaviors =
    {
        ["idle"] = {}
    }
    self.currentbehavior = "idle"

    self.currentbehaviordata = {}

    inst:StartUpdatingComponent(self)
end)

function GiantBrainController:OnUpdate(dt)
    if self.behaviors[self.currentbehavior] then
        if self.behaviors[self.currentbehavior].updatefn then
            self.behaviors[self.currentbehavior].updatefn(self.inst, dt, self.currentbehaviordata, self.currentbraindata)
        end
    else
        print("WARNING: currentbehavior in GiantBrainController is not valid", self.currentbehavior)
        self.currentbehavior = "idle"
    end
end

function GiantBrainController:GoToBehavior(behaviorname)
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
        print("WARNING: behaviorname in GoToBehavior is not valid", self.behaviorname)
        self.currentbehavior = "idle"
    end
end

return GiantBrainController
