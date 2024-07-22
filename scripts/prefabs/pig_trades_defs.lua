local TRADER = {
    
    pigman_collector = {
        items = { "stinger", "silk", "mosquitosack", "chitin", "venus_stalk", "venomgland", "spidergland", "lotus_flower", "bill_quill" },
        reset = 0,
        desc = STRINGS.CITY_PIG_COLLECTOR_TRADE,
        reward = "oinc",
        rewardqty = 3
    },

    pigman_banker = {
        items = {"redgem", "bluegem", "greengem", "orangegem", "yellowgem"},
        reset = 0,
        desc = STRINGS.CITY_PIG_BANKER_TRADE,
        reward = "oinc10",
        rewardqty = 1
    },

    pigman_beautician = {
        items = { "feather_crow", "feather_robin", "feather_robin_winter", "peagawkfeather", "feather_thunder", "doydoyfeather" },
        reset = 1,
        desc = STRINGS.CITY_PIG_BEAUTICIAN_TRADE,
        reward = "oinc",
        rewardqty = 2
    },

    pigman_mechanic = {
        items = { "boards", "rope", "cutstone", "papyrus" },
        reset = 0,
        desc = STRINGS.CITY_PIG_MECHANIC_TRADE,
        reward = "oinc",
        rewardqty = 2
    },

    pigman_professor = {
        items = { "relic_1", "relic_2", "relic_3" },
        reset = 0,
        desc = STRINGS.CITY_PIG_PROFESSOR_TRADE,
        reward = "oinc10",
        rewardqty = 1
    },

    pigman_hunter = {
        items = { "houndstooth", "stinger", "hippo_antler" },
        reset = 1,
        desc = STRINGS.CITY_PIG_HUNTER_TRADE,
        reward = "oinc",
        rewardqty = 5
    },

    pigman_mayor = {
        items = { "goldnugget" },
        reset = 0,
        desc = STRINGS.CITY_PIG_MAYOR_TRADE,
        reward = "oinc",
        rewardqty = 5
    },

    pigman_florist = {
        items = { "petals" },
        reset = 1,
        desc = STRINGS.CITY_PIG_FLORIST_TRADE,
        reward = "oinc",
        rewardqty = 1
    },

    pigman_storeowner = {
        items = { "clippings" },
        reset = 0,
        desc = STRINGS.CITY_PIG_STOREOWNER_TRADE,
        reward = "oinc",
        rewardqty = 1
    },

    pigman_farmer = {
        items = { "cutgrass", "twigs" },
        reset = 1,
        desc = STRINGS.CITY_PIG_FARMER_TRADE,
        reward = "oinc",
        rewardqty = 1
    },

    pigman_miner = {
        items = { "rocks" },
        reset = 1,
        desc = STRINGS.CITY_PIG_MINER_TRADE,
        reward = "oinc",
        rewardqty = 1
    },

    pigman_erudite = {
        items = { "nightmarefuel" },
        reset = 1,
        desc = STRINGS.CITY_PIG_ERUDITE_TRADE,
        reward = "oinc",
        rewardqty = 5
    },

    pigman_hatmaker = {
        items = { "silk" },
        reset = 1,
        desc = STRINGS.CITY_PIG_HATMAKER_TRADE,
        reward = "oinc",
        rewardqty = 5
    },

    pigman_queen = {
        items = { "pigcrownhat", "pig_scepter", "relic_4", "relic_5" },
        reset = 0,
        desc = STRINGS.CITY_PIG_QUEEN_TRADE,
        reward = "pedestal_key",
        rewardqty = 1
    },

    pigman_usher = {
        items = { "honey", "jammypreserves", "icecream", "pumpkincookie", "waffles", "berries", "berries_cooked" },
        reset = 1,
        desc = STRINGS.CITY_PIG_USHER_TRADE,
        reward = "oinc",
        rewardqty = 4
    },
}

for i=1, NUM_TRINKETS do
    table.insert(TRADER.pigman_collector.items, "trinket_" .. i)
end

return { TRADER = TRADER }
