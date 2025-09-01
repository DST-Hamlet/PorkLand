GLOBAL.setfenv(1, GLOBAL)

local LootDropper = require("components/lootdropper")

local _SpawnLootPrefab = LootDropper.SpawnLootPrefab
function LootDropper:SpawnLootPrefab(lootprefab, pt, ...)
    local item = _SpawnLootPrefab(self, lootprefab, pt, ...)

    if not item then
        print("WARNING! don't have prefab:", lootprefab)
        return item
    end

    if item.components.perishable then
        if self.inst.components.poisonable and self.inst.components.poisonable:IsPoisoned() then
            item.components.perishable:ReducePercent(TUNING.POISON_PERISH_PENALTY)
        elseif self.inst._poison_damage_task then
            item.components.perishable:ReducePercent(TUNING.POISON_PERISH_PENALTY)
        end
    end

    if self.inst.components.citypossession then
        item:AddComponent("citypossession")
        item.components.citypossession:SetCity(self.inst.components.citypossession.cityID)
    end

    return item
end
