local function oncanbepickedup(self, canbepickedup)
    if canbepickedup then
        self.inst:AddTag("canbepickedup")
    else
        self.inst:RemoveTag("canbepickedup")
    end
end

local Pickupable = Class(function(self, inst)
    self.inst = inst
    -- self.onpickupfn = nil
    self.canbepickedup = true
end,
nil,
{
    canbepickedup = oncanbepickedup,
})

function Pickupable:OnRemoveFromEntity()
    self.inst:RemoveTag("canbepickedup")
end

function Pickupable:SetOnPickupFn(fn)
    self.onpickupfn = fn
end

function Pickupable:CanPickUp()
    -- if self.canpickupfn then
        -- return self.canpickupfn(self.inst)
    -- end

    return self.canbepickedup
end

-- If this function retrns true then it has destroyed itself and you shouldnt give it to the player
function Pickupable:OnPickup(pickupguy)
    if not self:CanPickUp() then return false end

    if self.inst.components.burnable and self.inst.components.burnable:IsSmoldering() then
        self.inst.components.burnable:SmotherSmolder(pickupguy)
    end

    -- self.inst.Transform:SetPosition(0,0,0)
    self.inst:PushEvent("onpickup", {owner = pickupguy})
    if self.onpickupfn and type(self.onpickupfn) == "function" then
        self.onpickupfn(self.inst, pickupguy)
    end

    return true
end


return Pickupable
