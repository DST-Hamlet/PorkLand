GLOBAL.setfenv(1, GLOBAL)

local InventoryItemMoisture = require("components/inventoryitemmoisture")

local _GetTargetMoisture = InventoryItemMoisture.GetTargetMoisture
function InventoryItemMoisture:GetTargetMoisture(...)
    local x, _, z = self.inst.Transform:GetWorldPosition()
    if TheWorld.components.interiorspawner:IsInInteriorRegion(x, z) then
        return 0
    else
        return _GetTargetMoisture(self, ...)
    end
end
