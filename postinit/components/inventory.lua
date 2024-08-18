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
