local function OnBoatHealthDelta(inst, data)
    -- we are doing a sneaky, and sending the boolean data.damge, since we cant "know" on the client.
    inst.replica.boathealth._boathealthchange:set_local(data.damage)
    inst.replica.boathealth._boathealthchange:set(data.damage)
end

local function OnBoatHealthDirty(inst)
    local oldpercent = inst.replica.boathealth._oldhealthpercent or 1
    local percent = inst.replica.boathealth:GetPercent()
    local data = {
        oldpercent = oldpercent,
        percent = percent,
        damage = inst.replica.boathealth._boathealthchange:value(),
        currenthealth = inst.replica.boathealth:GetCurrentHealth(),
        maxhealth = inst.replica.boathealth:GetMaxHealth(),
    }

    inst.replica.boathealth._oldhealthpercent = percent
    inst:PushEvent("boathealthchange", data)
end

local BoatHealth = Class(function(self, inst)
    self.inst = inst

    self._maxhealth = net_ushortint(inst.GUID, "_maxhealth")
    self._currenthealth = net_ushortint(inst.GUID, "_currentboathealth")
    self._invincible = net_bool(inst.GUID, "_invincible")

    self._boathealthchange = net_bool(inst.GUID, "_boathealthchange", "boathealthdirty")

    inst:DoTaskInTime(0, function(inst)
        if TheWorld.ismastersim then
            inst:ListenForEvent("boathealthchange", OnBoatHealthDelta)
        else
            inst:ListenForEvent("boathealthdirty", OnBoatHealthDirty)
            self._oldhealthpercent = self._maxhealth:value() > 0 and self._currenthealth:value() / self._maxhealth:value() or 0
        end
    end)
end)

function BoatHealth:GetMaxHealth()
    if self.inst.components.boathealth then
        return self.inst.components.boathealth.maxhealth
    else
        return self._maxhealth:value()
    end
end

function BoatHealth:GetCurrentHealth()
    if self.inst.components.boathealth then
        return self.inst.components.boathealth.currenthealth
    else
        return self._currenthealth:value()
    end
end

function BoatHealth:IsInvincible()
    if self.inst.components.boathealth then
        return self.inst.components.boathealth:IsInvincible()
    else
        return self._invincible:value()
    end
end

function BoatHealth:IsEmpty()
    if self.inst.components.boathealth then
        return self.inst.components.boathealth:IsEmpty()
    else
        return self:GetCurrentHealth() <= 0
    end
end
BoatHealth.IsDead = BoatHealth.IsEmpty

function BoatHealth:IsFull()
    if self.inst.components.boathealth then
        return self.inst.components.boathealth:IsFull()
    else
        return self:GetCurrentHealth() >= self:GetMaxHealth()
    end
end

function BoatHealth:GetPercent()
    if self.inst.components.boathealth then
        return self.inst.components.boathealth:GetPercent()
    else
        if self:GetMaxHealth() > 0 then
            return math.min(1, self:GetCurrentHealth() / self:GetMaxHealth())
        else
            return 0
        end
    end
end


return BoatHealth
