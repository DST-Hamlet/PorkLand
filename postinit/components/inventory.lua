GLOBAL.setfenv(1, GLOBAL)

local Inventory = require("components/inventory")

function Inventory:IsItemNameEquipped(prefab)
    for k,v in pairs(self.equipslots) do
        if v.prefab == prefab then
            return true
        end
    end

    return false
end
