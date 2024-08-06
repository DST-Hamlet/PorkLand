local Infester = Class(function(self, inst)
    self.inst = inst
    self.infested = false
    self.inst:ListenForEvent("death", function() self:Uninfest() end)
    self.inst:ListenForEvent("freeze", function() self:Uninfest() end)
    self.basetime = 8
    self.randtime = 8
    self.inst:AddTag("infester")
end)

local function ShouldStopInfesting(inst)
    if TheWorld.state.isday then
        return false
    end

    local target = inst:FindLight()
    if target and inst:GetDistanceSqToInst(target) > 5 * 5 then
        return target
    end
end

function Infester:Infest(target)
    if not target:HasTag("player") or not target.components.infestable then
        return
    end

    self.infested = true
    self.target = target

    self.inst:StartUpdatingComponent(self)

    self.bite_task = self.inst:DoTaskInTime(self.basetime + (math.random() * self.randtime), function() self:Bite() end)

    target:AddChild(self.inst)
    target.components.infestable:Infest(self.inst)

    self.inst.AnimState:SetFinalOffset(-1)
    self.inst.Transform:SetPosition(0, 0, 0)
end


function Infester:Uninfest()
    self.infested = false
    if self.target then
        self.target:RemoveChild(self.inst)
        local pos = Vector3(self.target.Transform:GetWorldPosition())
        self.inst.Transform:SetPosition(pos.x, pos.y, pos.z)

        self.target.components.infestable:Uninfest(self.inst)

        self.target = nil
    end
    if self.bite_task then
        self.bite_task:Cancel()
        self.bite_task = nil
    end

    if not (self.inst.components.homeseeker and self.inst.components.homeseeker.home and self.inst.components.homeseeker.home:IsValid()) then
        self.inst.components.knownlocations:RememberLocation("home", self.inst:GetPosition())
    end

    self.inst:ClearBufferedAction()
    self.inst:StopUpdatingComponent(self)
end

function Infester:Bite()
    if self.target then
        self.inst:PushEvent("doattack", {target = self.target})
    end
    self.bite_task = self.inst:DoTaskInTime(self.basetime + math.random() * self.randtime, function() self:Bite() end)
end

function Infester:OnUpdate(dt)
    if ShouldStopInfesting(self.inst) then
        self:Uninfest()
    end
end

return Infester
