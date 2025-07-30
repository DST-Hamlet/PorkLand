GLOBAL.setfenv(1, GLOBAL)

local InventoryItemMoisture = require("components/inventoryitemmoisture")

local _GetTargetMoisture = InventoryItemMoisture.GetTargetMoisture
function InventoryItemMoisture:GetTargetMoisture(...)
    local x, _, z = self.inst.Transform:GetWorldPosition()
    local old_wetness = TheWorld.state.wetness
    if TheWorld.components.interiorspawner:IsInInteriorRegion(x, z) then
        TheWorld.state.wetness = 0
    end
    local ret = _GetTargetMoisture(self, ...)
    TheWorld.state.wetness = old_wetness
end
