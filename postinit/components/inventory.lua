local Inventory = require("components/inventory")

function Inventory:GetFogWaterproofness(slot)
    if self.inst.components.moisture ~= nil and self.inst.components.moisture:GetWaterproofInventory() then
        return 1
    end

    local waterproofness = 0

    if slot then
        local item = self:GetItemInSlot(slot)
        if item and item:HasTag("fogproof") and item.components.waterproofer then
            waterproofness = waterproofness + item.components.waterproofer:GetEffectiveness()
        end
    else
        for _, v in pairs(self.equipslots) do
            if v and v:HasTag("fogproof") and v.components.waterproofer then
                waterproofness = waterproofness + v.components.waterproofer:GetEffectiveness()
            end
        end
    end
    return waterproofness
end
