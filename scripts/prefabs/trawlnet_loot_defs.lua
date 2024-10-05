local chance_verylow  = 1
local chance_low      = 2
local chance_medium   = 4
local chance_high     = 8

-- Porkland loot;
local LILYPOND_LOOT = {
    { "cutreeds", chance_high },
    { "cutgrass", chance_high },
    { "twigs", chance_high },
    { "rocks", chance_high },
    { "log", chance_high },
    { "coi", chance_high },
    { "lotus_flower", chance_medium },
    { "rottenegg", chance_medium },
    { "oinc", chance_medium },
    { "iron", chance_medium },
    { "spoiled_fish", chance_medium },
    { "bill_quill", chance_medium },
    { "boneshard", chance_medium },
    { "goldnugget", chance_low },
    { "fabric", chance_low },
    { "goldenshovel", chance_low },
    { "goldenaxe", chance_low },
    { "disarming_kit", chance_low },
    { "shears", chance_low },
    { "trinket_17", chance_low },
    { "oinc10", chance_low },
    { "redgem", chance_verylow },
    { "bluegem", chance_verylow },
    { "purplegem", chance_verylow },
    { "amulet", chance_verylow },
    { "relic_1", chance_verylow },
    { "relic_2", chance_verylow },
    { "relic_3", chance_verylow },
    { "trinket_giftshop_1", chance_verylow },
    { "trinket_giftshop_3", chance_verylow },
    { "trinket_18", chance_verylow },
}

-- Don't collect more than one of these.
local UNIQUE_ITEMS = {
    "trinket_16",
    "trinket_17",
    "trinket_18",
    "trident",
    "relic_1",
    "relic_2",
    "relic_3",
    "trinket_giftshop_1",
    "trinket_giftshop_3",
}

local SPECIAL_CASE_PREFABS = {
    seaweed_planted = function(inst, net)
        if inst and inst.components.pickable then
            if inst.components.pickable.canbepicked
                and inst.components.pickable.caninteractwith then
                net:pickupitem(SpawnPrefab(inst.components.pickable.product))
            end

            inst:Remove()
            return SpawnPrefab("seaweed_stalk")
        end
    end,

    jellyfish_planted = function(inst)
        inst:Remove()
        return SpawnPrefab("jellyfish")
    end,

    mussel_farm = function(inst, net)
        if inst then
            if inst.growthstage <= 0 then
                inst:Remove()
                return SpawnPrefab(inst.components.pickable.product)
            end
        end
    end,

    sunkenprefab = function(inst)
        local item = inst.components.container:RemoveItemBySlot(1)
        inst:Remove()
        return item
    end,

    lobster = function(inst)
        return inst
    end,
}

-- Made this public for easier modding -Half
local function GetLootTable(inst)
    return LILYPOND_LOOT
end

return {
    LILYPOND_LOOT        = LILYPOND_LOOT,
    UNIQUE_ITEMS         = UNIQUE_ITEMS,
    SPECIAL_CASE_PREFABS = SPECIAL_CASE_PREFABS,

    GetLootTable = GetLootTable
}
