local function onsailor(self)
    if self.inst.replica.sailable then
        self.inst.replica.sailable._sailor:set(self.sailor)
    end
    if self:IsOccupied() then
        self.inst:RemoveTag("sailable")
    else
        self.inst:AddTag("sailable")
    end

    local container = self.inst.components.container

    if container then
        if container.old_canbeopened == nil then
            container.old_canbeopened = container.canbeopened
        end

        container:Close()
        if self.sailor then
            container:ChangeBoatType(true)
            container.canbeopened = false -- 有人的船容器不能通过打开动作来开启
        else
            container:ChangeBoatType(false)
            container.canbeopened = container.old_canbeopened
        end
    end
    
    if self.check_container_task then
        self.check_container_task:Cancel()
    end

    self.check_container_task = self.inst:DoTaskInTime(0.25, function()
        self.check_container_task = nil
        if container and self:GetSailor() then
            container:Open(self:GetSailor())
        end
    end)
end

local Sailable = Class(function(self, inst)
    self.inst = inst
    self.flotsambuild = nil
    self.unoccupiedanim = "run_loop"
    self.sailor = nil
    self.isembarking = false -- 是否有人正在试图上船

    self.hit_immunity = 0.66  -- time in seconds the boat is immune to hit state reactions after being hit.
    self.next_hit_time = 0
    self.maprevealbonus = 0

    self._externalspeedmultipliers = {}
    self.externalspeedmultiplier = 0

    self._externalaccelerationmultipliers = {}
    self.externalaccelerationmultiplier = 0

    self.inst:DoTaskInTime(0,function() self.externalspeedmultiplier = self:RecalculateExternalSpeedMultiplier(self._externalspeedmultipliers) end)

end, nil, {
    sailor = onsailor,
    isembarking = onsailor,
})

function Sailable:SetHitImmunity(time)
    self.hit_immunity = time
end

function Sailable:GetSailor()
    return self.sailor
end

function Sailable:GetHit()
    self.next_hit_time = GetTime() + self.hit_immunity
end

function Sailable:GetMapRevealBonus()
    return self.maprevealbonus
end

function Sailable:GetIsSailEquipped()
    if self.alwayssail then return true end

    if self.inst.components.container then
        local equipped = self.inst.components.container:GetItemInBoatSlot(BOATEQUIPSLOTS.BOAT_SAIL)
        if equipped and equipped:HasTag("sail") then
            return true
        end
    end
    return false
end

function Sailable:IsOccupied()
    return self.sailor ~= nil or self.isembarking or self.alwaysoccupied
end

function Sailable:CanDoHit()
    return self.next_hit_time <= GetTime()
end

function Sailable:OnEmbarked(sailor)
    self.sailor = sailor
    self.isembarking = false

    self.inst:AddTag("NOCLICK")

    if self.inst.MiniMapEntity then
        self.inst.MiniMapEntity:SetEnabled(false)
    end

    if self.inst.components.boathealth then
        self.inst.components.boathealth:StartConsuming()
    elseif self.inst.components.fueled then
        self.inst.components.fueled:StartConsuming()
    end

    self.inst:PushEvent("embarked", {sailor = sailor})

    if self.inst.components.workable then
        self.inst.components.workable.workable = false
    end

    self.inst.replica.sailable:PlayAnim("idle_loop")
end

function Sailable:OnDisembarked(sailor)
    if self.sailor == sailor then
        self.sailor = nil
    end

    self.inst:RemoveTag("NOCLICK")

    if self.inst.MiniMapEntity then
        self.inst.MiniMapEntity:SetEnabled(true)
    end

    if self.inst.components.boathealth then
        self.inst.components.boathealth:StopConsuming()
        self.inst.components.boathealth:SetIsMoving(false)
    elseif self.inst.components.fueled then
        self.inst.components.fueled:StopConsuming()
    end

    self.inst:PushEvent("disembarked", {sailor = sailor})

    if self.inst.components.workable then
        self.inst.components.workable.workable = true
    end

    self.inst.replica.sailable:PlayAnim("run_loop")
end

function Sailable:OnRemoveFromEntity()
    self.inst:RemoveTag("sailable")
end

function Sailable:RecalculateExternalSpeedMultiplier(sources)
    local m = self.inst.replica.sailable.basicspeedbonus
    for source, src_params in pairs(sources) do
        for k, v in pairs(src_params.multipliers) do
            m = m + v * (6 + self.inst.replica.sailable.basicspeedbonus)
        end
    end
    return m
end

function Sailable:SetExternalSpeedMultiplier(source, key, m)
    if key == nil then
        return
    elseif m == nil or m == 1 then
        self:RemoveExternalSpeedMultiplier(source, key)
        return
    end
    local src_params = self._externalspeedmultipliers[source]
    if src_params == nil then
        self._externalspeedmultipliers[source] = {
            multipliers = { [key] = m },
            onremove = function(source)
                self._externalspeedmultipliers[source] = nil
                self.externalspeedmultiplier = self:RecalculateExternalSpeedMultiplier(self._externalspeedmultipliers)
            end,
        }
        self.inst:ListenForEvent("onremove", self._externalspeedmultipliers[source].onremove, source)
        self.externalspeedmultiplier = self:RecalculateExternalSpeedMultiplier(self._externalspeedmultipliers)
    elseif src_params.multipliers[key] ~= m then
        src_params.multipliers[key] = m
        self.externalspeedmultiplier = self:RecalculateExternalSpeedMultiplier(self._externalspeedmultipliers)
    end
end

function Sailable:RemoveExternalSpeedMultiplier(source, key)
    local src_params = self._externalspeedmultipliers[source]
    if src_params == nil then
        return
    elseif key ~= nil then
        src_params.multipliers[key] = nil
        if next(src_params.multipliers) ~= nil then
            -- this source still has other keys
            self.externalspeedmultiplier = self:RecalculateExternalSpeedMultiplier(self._externalspeedmultipliers)
            return
        end
    end

    self.inst:RemoveEventCallback("onremove", src_params.onremove, source)
    self._externalspeedmultipliers[source] = nil
    self.externalspeedmultiplier = self:RecalculateExternalSpeedMultiplier(self._externalspeedmultipliers)
end

function Sailable:RecalculateExternalAccelerationMultiplier(sources)
    local m = 0
    for source, src_params in pairs(sources) do
        for k, v in pairs(src_params.multipliers) do
            m = m + v
        end
    end
    return m
end

function Sailable:SetExternalAccelerationMultiplier(source, key, m)
    if key == nil then
        return
    elseif m == nil or m == 1 then
        self:RemoveExternalAccelerationMultiplier(source, key)
        return
    end
    local src_params = self._externalaccelerationmultipliers[source]
    if src_params == nil then
        self._externalaccelerationmultipliers[source] = {
            multipliers = { [key] = m },
            onremove = function(source)
                self._externalaccelerationmultipliers[source] = nil
                self.externalaccelerationmultiplier = self:RecalculateExternalAccelerationMultiplier(self._externalaccelerationmultipliers)
            end,
        }
        self.inst:ListenForEvent("onremove", self._externalaccelerationmultipliers[source].onremove, source)
        self.externalaccelerationmultiplier = self:RecalculateExternalAccelerationMultiplier(self._externalaccelerationmultipliers)
    elseif src_params.multipliers[key] ~= m then
        src_params.multipliers[key] = m
        self.externalaccelerationmultiplier = self:RecalculateExternalAccelerationMultiplier(self._externalaccelerationmultipliers)
    end
end

function Sailable:RemoveExternalAccelerationMultiplier(source, key)
    local src_params = self._externalaccelerationmultipliers[source]
    if src_params == nil then
        return
    elseif key ~= nil then
        src_params.multipliers[key] = nil
        if next(src_params.multipliers) ~= nil then
            self.externalaccelerationmultiplier = self:RecalculateExternalAccelerationMultiplier(self._externalaccelerationmultipliers)
            return
        end
    end

    self.inst:RemoveEventCallback("onremove", src_params.onremove, source)
    self._externalaccelerationmultipliers[source] = nil
    self.externalaccelerationmultiplier = self:RecalculateExternalAccelerationMultiplier(self._externalaccelerationmultipliers)
end

function Sailable:GetExternalAccelerationMultiplier(source, key, m)
    return self.externalaccelerationmultiplier
end


return Sailable
