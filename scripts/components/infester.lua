local Infester = Class(function(self, inst)
    self.inst = inst
    self.infested = false
    self.inst:ListenForEvent("death", function() self:Uninfest() end)
    self.inst:ListenForEvent("freeze", function() self:Uninfest() end)
    self.inst:ListenForEvent("teleported", function() self:Uninfest(true) end)
    self.basetime = 8
    self.randtime = 8
    self.inst:AddTag("infester")
    self._ontargetremove = function(target)
        self:Uninfest()
    end
end)

function Infester:ShouldStopInfesting(inst)
    if not self.target or not self.target:IsValid() then
        return true
    end

    if self.target and (self.target.components.health:IsDead() or self.target:HasTag("playerghost")) then
        return true
    end

    if TheWorld.state.isday and inst:GetCurrentInteriorID() == nil then
        return false
    end

    local lighttarget = inst:FindLight()
    if lighttarget and inst:GetDistanceSqToInst(lighttarget) > 5 * 5 then
        return lighttarget
    end
end

function Infester:Infest(target)
    if not target.components.infestable then
        return
    end

    self.infested = true
    self.target = target

    self.inst:StartUpdatingComponent(self)

    self.bite_task = self.inst:DoTaskInTime(self.basetime + (math.random() * self.randtime), function() self:Bite() end)

    target:AddChild(self.inst)

    self.inst.AnimState:SetFinalOffset(1)
    self.inst.Transform:SetPosition(0, 0, 0)

    target.components.infestable:Infest(self.inst)
    self.inst.persists = false

    self.inst:ListenForEvent("onremove", self._ontargetremove, target)
    if target:HasTag("player") then
        self.inst:ListenForEvent("player_despawn", self._ontargetremove, target)
    end
end

function Infester:Uninfest(is_teleported)
    self.infested = false
    if self.target then
        self.inst:RemoveEventCallback("onremove", self._ontargetremove, self.target)
        if self.target:HasTag("player") then
            self.inst:RemoveEventCallback("player_despawn", self._ontargetremove, self.target)
        end

        self.target:RemoveChild(self.inst)
        self.inst.persists = true

        local x, y, z = self.target.Transform:GetWorldPosition()

        if is_teleported then
            x, y, z = self.inst.Transform:GetWorldPosition()
        end

        self.inst.Physics:Teleport(x, y, z) -- need to SetPosition here, otherwise self.inst would be left at (0, 0, 0)

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
    if self:ShouldStopInfesting(self.inst) then
        self:Uninfest()
    end
end

return Infester
