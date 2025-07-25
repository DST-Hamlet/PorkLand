local AddClassPostConstruct = AddClassPostConstruct
GLOBAL.setfenv(1, GLOBAL)

local EquipSlot = require("equipslotutil")
local Equippable = require("components/equippable_replica")

function Equippable:SetBoatEquipSlot(eslot)
    self._boatequipslot:set(EquipSlot.BoatToID(eslot))
end

function Equippable:BoatEquipSlot()
    return EquipSlot.BoatFromID(self._boatequipslot:value())
end

local _IsEquipped = Equippable.IsEquipped
function Equippable:IsEquipped(container)
    local isequipped = _IsEquipped(self)
    local isboatequipped = false
    if not self.inst.components.equippable then
        local inventoryitem = self.inst.replica.inventoryitem
        local parent = self.inst.entity:GetParent()
        isboatequipped = inventoryitem ~= nil and inventoryitem:IsHeld() and
            parent and parent.replica.container and parent.replica.container.hasboatequipslots and parent.replica.container:GetItemInBoatSlot(self:BoatEquipSlot()) == self.inst
    end
    return isequipped or isboatequipped
end

AddClassPostConstruct("components/equippable_replica", function(self)
    self._boatequipslot = EquipSlot.BoatCount() <= 7 and net_tinybyte(self.inst.GUID, "equippable._boatequipslot") or net_smallbyte(self.inst.GUID, "equippable._boatequipslot")
end)
