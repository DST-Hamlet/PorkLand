AddRoom("BG_deeprainforest_base", {
    colour = {r = 0.2, g = 0.6, b = 0.2, a = 0.3},
    value = WORLD_TILES.DEEPRAINFOREST,
    tags = {"ExitPiece", "Canopy"},
    contents = {
        distributepercent = 0.5,
        distributeprefabs = {
            rainforesttree = 2,  -- 4,
            tree_pillar = 0.5,  -- 0.5,
            nettle = 0.12,
            flower_rainforest = 1,
            -- berrybush = 1,
            lightrays_jungle = 1.2,
            deep_jungle_fern_noise = 4,
            jungle_border_vine = 0.5,
            fireflies = 0.2,
            hanging_vine_patch = 0.1,
            randomrelic = 0.02,
            randomruin = 0.02,
            randomdust = 0.02,
            pig_ruins_torch = 0.02,
            -- pig_ruins_artichoke = 0.01,
            -- pig_ruins_head = 0.01,
            mean_flytrap = 0.05,
            rock_flippable = 0.1,
            radish_planted = 0.5,
        },

        countprefabs = {
            vampirebatcave_potential = 1
        },
    }
})

AddRoom("deeprainforest_spider_monkey_nest", {
    colour = {r = 0.2, g = 0.6, b = 0.2, a = 0.3},
    value = WORLD_TILES.DEEPRAINFOREST,
    tags = {"ExitPiece", "Canopy"},
    contents = {
        distributepercent = 0.25,  -- .3
        distributeprefabs = {
            rainforesttree = 3,  -- 4,
            tree_pillar = 1,  -- 0.5,
            nettle = 0.12,
            flower_rainforest = 1,
            lightrays_jungle = 1.2,
            deep_jungle_fern_noise =4,
            jungle_border_vine = 0.5,
            randomrelic = 0.02,
            randomruin = 0.02,
            randomdust = 0.02,
            pig_ruins_torch = 0.02,
            -- pig_ruins_artichoke = 0.01,
            -- pig_ruins_head = 0.01,
            rock_flippable = 0.1,
            radish_planted = 0.5,
        },
        countprefabs = {
            spider_monkey = math.random(1, 2),
            hanging_vine_patch = math.random(0, 2)
        },
    }
})

AddRoom("deeprainforest_flytrap_grove", {
    colour = {r = 0.2, g = 0.6, b = 0.2, a = 0.3},
    value = WORLD_TILES.DEEPRAINFOREST,
    tags = {"ExitPiece", "Canopy"},
    contents = {
        distributepercent = 0.25,  -- .3
        distributeprefabs = {
            rainforesttree = 4,
            tree_pillar = 1,  -- 0.5,
            nettle = 0.12,
            flower_rainforest = 1,
            lightrays_jungle = 1.2,
            deep_jungle_fern_noise =4,
            jungle_border_vine = 0.5,
            fireflies = 0.2,
            randomrelic = 0.02,
            randomruin = 0.02,
            randomdust = 0.02,
            pig_ruins_torch = 0.02,
            -- pig_ruins_artichoke = 0.01,
            -- pig_ruins_head = 0.01,
            rock_flippable = 0.1,
            radish_planted = 0.5,
        },
        countprefabs = {
            mean_flytrap = math.random(10, 15),
            adult_flytrap = math.random(3, 7),
            hanging_vine_patch = math.random(0, 2)
        },
    }
})

AddRoom("deeprainforest_fireflygrove", {
    colour = {r = 1, g = 1, b = 0.2, a = 0.3},
    value = WORLD_TILES.DEEPRAINFOREST,
    tags = {"ExitPiece", "Canopy"},
    contents = {
        distributepercent = 0.25,  -- 0.25,  -- .3
        distributeprefabs = {
            rainforesttree = 4,
            tree_pillar = 1,  -- 0.5,
            nettle = 0.12,
            flower_rainforest = 1,
            lightrays_jungle = 1.2,
            deep_jungle_fern_noise = 4,
            jungle_border_vine = 0.5,
            fireflies = 5,
            hanging_vine_patch = 0.1,
            randomrelic = 0.02,
            randomruin = 0.02,
            randomdust = 0.02,
            pig_ruins_torch = 0.02,
            -- pig_ruins_artichoke = 0.01,
            -- pig_ruins_head = 0.01,
            rock_flippable = 0.1,
            radish_planted = 0.5,
        },
        countprefabs = {
            fireflies = math.random(5, 10)
        },
    }
})


AddRoom("deeprainforest_gas", {
    colour = {r = 1, g = 0.6, b = 0.2, a = 0.3},
    value = WORLD_TILES.GASJUNGLE,
    tags = {"ExitPiece", "Canopy", "Gas_Jungle"},
    contents = {
        distributepercent = 0.45,
        distributeprefabs = {
            rainforesttree_rot = 4,
            tree_pillar = 0.5,
            nettle = 0.12,
            red_mushroom = 0.3,
            green_mushroom = 0.3,
            blue_mushroom = 0.3,
            -- berrybush = 1,
            lightrays_jungle = 1.2,
            poisonmist = 8,
            randomrelic = 0.02,
            randomruin = 0.02,
            randomdust = 0.02,
            rock_flippable = 0.05,
            jungle_border_vine = 0.5,
        },
    }
})

AddRoom("deeprainforest_gas_flytrap_grove", {
    colour = {r = 1, g = 0.6, b = 0.2, a = 0.3},
    value = WORLD_TILES.GASJUNGLE,
    tags = {"ExitPiece", "Canopy", "Gas_Jungle"},
    contents = {
        distributepercent = 0.5,  -- .45
        distributeprefabs = {
            rainforesttree_rot = 2,
            tree_pillar = 0.5,
            nettle = 0.12,
            red_mushroom = 0.3,
            green_mushroom = 0.3,
            blue_mushroom = 0.3,
            -- berrybush = 1,
            lightrays_jungle = 1.2,
            -- mistarea = 6,
            randomrelic = 0.02,
            randomruin = 0.02,
            randomdust = 0.02,
            poisonmist = 8,
            rock_flippable = 0.05,
            jungle_border_vine = 0.5,
        },
        countprefabs = {
            mean_flytrap = math.random(10, 15),
            adult_flytrap = math.random(3, 7),
        },
    }
})

AddRoom("deeprainforest_ruins_entrance", {
    colour = {r = 1, g = 0.1, b = 0.2, a = 0.5},
    value = WORLD_TILES.DEEPRAINFOREST,
    tags = {"ExitPiece", "Canopy"},
    contents = {
        distributepercent = 0.25,  -- .3
        distributeprefabs = {
            rainforesttree = 4,
            tree_pillar = 1,
            nettle = 0.12,
            flower_rainforest = 1,
            lightrays_jungle = 1.2,
            deep_jungle_fern_noise = 4,
            jungle_border_vine = 0.5,
            fireflies = 0.2,
            randomrelic = 0.02,
            randomruin = 0.02,
            randomdust = 0.02,
            pig_ruins_torch = 0.02,
            rock_flippable = 0.1,
            radish_planted = 0.5,
        },
        countprefabs = {
            -- pig_ruins_torch = 3,
            -- pig_ruins_entrance = 1,
            -- pig_ruins_artichoke = 1,
        },

    }
})

AddRoom("deeprainforest_ruins_exit", {
    colour = {r = 0.2, g = 0.1, b = 1, a = 0.5},
    value = WORLD_TILES.DEEPRAINFOREST,
    tags = {"ExitPiece", "Canopy"},
    contents = {
        distributepercent = 0.25,  -- .3
        distributeprefabs = {
            rainforesttree = 4,
            tree_pillar = 1,
            nettle = 0.12,
            flower_rainforest = 1,
            lightrays_jungle = 1.2,
            deep_jungle_fern_noise = 4,
            jungle_border_vine = 0.5,
            fireflies = 0.2,
            randomrelic = 0.02,
            randomruin = 0.02,
            randomdust = 0.02,
            pig_ruins_torch = 0.02,
            rock_flippable = 0.1,
            radish_planted = 0.5,
        },
        countprefabs = {
            -- pig_ruins_torch = 3,
            -- pig_ruins_exit = 1,
            -- pig_ruins_head = 1,
        },

    }
})

AddRoom("deeprainforest_anthill", {
    colour = {r = 1, g = 0, b = 1, a = 0.3},
    value = WORLD_TILES.DEEPRAINFOREST,
    tags = {"ExitPiece", "Canopy"},
    contents = {
        distributepercent = 0.25,  -- .3
        distributeprefabs = {
            rainforesttree = 4,
            tree_pillar = 1,
            nettle = 0.12,
            flower_rainforest = 1,
            lightrays_jungle = 1.2,
            deep_jungle_fern_noise = 4,
            jungle_border_vine = 0.5,
            fireflies = 0.2,
            pig_ruins_torch = 0.02,
            rock_flippable = 0.1,
            radish_planted = 0.5,
            randomrelic = 0.02,
            randomruin = 0.02,
            randomdust = 0.02,
        },

        countprefabs = {
            anthill = 1,
            pighead = 4,
        },

    }
})

AddRoom("deeprainforest_mandrakeman", {
    colour = {r = 1, g = 0, b = 1, a = 0.3},
    value = WORLD_TILES.DEEPRAINFOREST,
    tags = {"ExitPiece", "Canopy"},
    contents = {
        distributepercent = 0.25,  -- .3
        distributeprefabs = {
            rainforesttree = 4,
            tree_pillar = 1,
            nettle = 0.12,
            flower_rainforest = 1,
            lightrays_jungle = 1.2,
            deep_jungle_fern_noise = 4,
            jungle_border_vine = 0.5,
            fireflies = 0.2,
            pig_ruins_torch = 0.02,
            rock_flippable = 0.1,
            radish_planted = 0.5,
            randomrelic = 0.02,
            randomruin = 0.02,
            randomdust = 0.02,
        },

        countprefabs = {
            mandrakehouse = 2
        },

    }
})

AddRoom("deeprainforest_anthill_exit", {
    colour = {r = 1, g = 0, b = 1, a = 0.3},
    value = WORLD_TILES.DEEPRAINFOREST,
    tags = {"ExitPiece", "Canopy"},    contents = {
        distributepercent = 0.25,  -- .3
        distributeprefabs = {
            rainforesttree = 4,
            tree_pillar = 1,
            nettle = 0.12,
            flower_rainforest = 1,
            lightrays_jungle = 1.2,
            deep_jungle_fern_noise = 4,
            jungle_border_vine = 0.5,
            fireflies = 0.2,
            pig_ruins_torch = 0.02,
            rock_flippable = 0.1,
            radish_planted = 0.5,
            randomrelic = 0.02,
            randomruin = 0.02,
            randomdust = 0.02,
        },

        countprefabs = {
            anthill_exit = 1,
        },

    }
})

AddRoom("deeprainforest_base_nobatcave", {
    colour = {r = 0.2, g = 0.6, b = 0.2, a = 0.3},
    value = WORLD_TILES.DEEPRAINFOREST,
    tags = {"ExitPiece", "Canopy"},
    contents = {
        distributepercent = 0.5,
        distributeprefabs = {
            rainforesttree = 2,  -- 4,
            tree_pillar = 0.5,  -- 0.5,
            nettle = 0.12,
            flower_rainforest = 1,
            -- berrybush = 1,
            lightrays_jungle = 1.2,
            deep_jungle_fern_noise = 4,
            jungle_border_vine = 0.5,
            fireflies = 0.2,
            hanging_vine_patch = 0.1,
            randomrelic = 0.02,
            randomruin = 0.02,
            randomdust = 0.02,
            pig_ruins_torch = 0.02,
            -- pig_ruins_artichoke = 0.01,
            -- pig_ruins_head = 0.01,
            mean_flytrap = 0.05,
            rock_flippable = 0.1,
            radish_planted = 0.5,
        },
    }
})
