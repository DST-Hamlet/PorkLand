GLOBAL.setfenv(1, GLOBAL)

local InventoryItem = require("components/inventoryitem_replica")
local _SetOwner = InventoryItem.SetOwner
function InventoryItem:SetOwner(owner, ...)
    local boat_owner = owner ~= nil and owner:HasTag("boatcontainer") and owner.components.container ~= nil and owner.components.container.opener
    if boat_owner then
        if self.inst.Network ~= nil then
            self.inst.Network:SetClassifiedTarget(boat_owner)
        end
        if self.classified ~= nil then
            self.classified.Network:SetClassifiedTarget(boat_owner or self.inst)
        end
        return
    end
    return _SetOwner(self, owner, ...)
end
