GLOBAL.setfenv(1, GLOBAL)

local LootDropper = require("components/lootdropper")

local _SpawnLootPrefab = LootDropper.SpawnLootPrefab
function LootDropper:SpawnLootPrefab(loot, pt, ...)
    local item = _SpawnLootPrefab(self, loot, pt, ...)

    if self.inst.components.poisonable and self.inst.components.poisonable:IsPoisoned() and item.components.perishable then
        item.components.perishable:ReducePercent(TUNING.POISON_PERISH_PENALTY)
    end

    return item
end
