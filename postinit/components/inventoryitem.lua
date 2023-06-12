local AddComponentPostInit = AddComponentPostInit
GLOBAL.setfenv(1, GLOBAL)

local InventoryItem = require("components/inventoryitem")

function InventoryItem:SetOnRemovedFn(fn)
    self.onRemovedfn = fn
end

local _OnRemoved = InventoryItem.OnRemoved
function InventoryItem:OnRemoved(...)
    if self.owner then
        if self.onRemovedfn then
            self.onRemovedfn(self.inst, self.owner)
        end
    end
    _OnRemoved(self, ...)
end

AddComponentPostInit("inventoryitem", function(self, inst)
    inst:AddTag("isinventoryitem")
end)
