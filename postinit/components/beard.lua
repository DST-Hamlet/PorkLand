GLOBAL.setfenv(1, GLOBAL)

local Beard = require("components/beard")

local _UpdateBeardInventory = Beard.UpdateBeardInventory
function Beard:UpdateBeardInventory(...)
    if self.inst:HasTag("wereness") then
        local sack = "woodie_beaver_bag"
        local beardsack = self.inst.components.inventory and self.inst.components.inventory:GetEquippedItem(EQUIPSLOTS.BEARD)
        if sack then
            if not beardsack then
                -- Has level no beard sack. Give beard sack.
                local newsack = SpawnPrefab(sack)
                self.inst.components.inventory:Equip(newsack)
            end
        end
    else
        return _UpdateBeardInventory(self, ...)
    end
end
