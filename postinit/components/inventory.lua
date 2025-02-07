local AddComponentPostInit = AddComponentPostInit
local Inventory = require("components/inventory")

local _GetEquippedItem = Inventory.GetEquippedItem
function Inventory:GetEquippedItem(eslot)
    if eslot == nil then
        return false
    else
        return _GetEquippedItem(self, eslot)
    end
end

local _Equip = Inventory.Equip
function Inventory:Equip(item, ...)
    if item == nil or item.components.equippable == nil or item.components.equippable.equipslot == nil then
        return false
    else
        return _Equip(self, item, ...)
    end
end

function Inventory:HasPoisonBlockerEquip()
    for k, v in pairs (self.equipslots) do
        if v.components.equippable ~= nil and v.components.equippable:IsPoisonBlocker() then
            return true
        end
    end
end

function Inventory:HasPoisonGasBlockerEquip()
    for k, v in pairs (self.equipslots) do
        if v.components.equippable ~= nil and v.components.equippable:IsPoisonGasBlocker() then
            return true
        end
    end
end

local function InvSpaceChanged(inst)
    inst:PushEvent("invspacechange", {percent = inst.components.inventory:NumItems() / inst.components.inventory.maxslots})
end

AddComponentPostInit("inventory", function(self)
    self.inst:ListenForEvent("itemget", InvSpaceChanged)
    self.inst:ListenForEvent("itemlose", InvSpaceChanged)
    self.inst:ListenForEvent("dropitem", InvSpaceChanged)
end)
