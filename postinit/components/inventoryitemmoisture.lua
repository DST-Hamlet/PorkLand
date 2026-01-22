GLOBAL.setfenv(1, GLOBAL)

local InventoryItemMoisture = require("components/inventoryitemmoisture")

local _GetTargetMoisture = InventoryItemMoisture.GetTargetMoisture
function InventoryItemMoisture:GetTargetMoisture(...)
    if self.moisture_override then
        return self.moisture_override
    end
    local x, _, z = self.inst.Transform:GetWorldPosition()
    local old_wetness = TheWorld.state.wetness
    if TheWorld.components.interiorspawner:IsInInteriorRegion(x, z) then
        TheWorld.state.wetness = 0
    end
    local ret = _GetTargetMoisture(self, ...)
    TheWorld.state.wetness = old_wetness
    return ret
end
