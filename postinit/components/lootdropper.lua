GLOBAL.setfenv(1, GLOBAL)

local unpack = unpack
local VISUALVARIANT_PREFABS = require("prefabs/visualvariant_defs").VISUALVARIANT_PREFABS

----------------------------------------------------------------------------------------
local LootDropper = require("components/lootdropper")

local _SpawnLootPrefab = LootDropper.SpawnLootPrefab
function LootDropper:SpawnLootPrefab(loot, pt, ...)
    local item = _SpawnLootPrefab(self, loot, pt, ...)

    if self.inst.components.poisonable and self.inst.components.poisonable:IsPoisoned() and item.components.perishable then
        item.components.perishable:ReducePercent(TUNING.POISON_PERISH_PENALTY)
    end

	if item.components.visualvariant then
		item.components.visualvariant:CopyOf(self.inst)
	end
	
    return item
end

local _GenerateLoot = LootDropper.GenerateLoot
function LootDropper:GenerateLoot(...)
    local rets = {_GenerateLoot(self, ...)}

    local variant = self.inst.components.visualvariant ~= nil and self.inst.components.visualvariant:GetVariant() or nil
    if variant then
        for i,loot in ipairs(rets[1]) do
            rets[1][i] = VISUALVARIANT_PREFABS[loot] and VISUALVARIANT_PREFABS[loot][variant] or loot
        end
    end
    return unpack(rets)
end
