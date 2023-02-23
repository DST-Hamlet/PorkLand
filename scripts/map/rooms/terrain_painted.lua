AddRoom("BG_painted_base", {
    colour = {r = 1.0, g = 1.0, b = 1.0, a = 0.3},
    value = WORLD_TILES.PAINTED,
    tags = {"ExitPiece", "Bramble"},
    contents = {
        distributepercent = .15,  -- .26
        distributeprefabs = {
            tubertree = 1,
            gnatmound = 0.1,
            rocks = 0.1,
            nitre = 0.1,
            flint = 0.05,
            iron = 0.2,
            thunderbirdnest = 0.1,
            sedimentpuddle = 0.1,
            pangolden = 0.005,
            goldnugget = 0.03,
        },
        countprefabs = {
            pangolden = 1,
            vampirebatcave_potential = 1,
        },
    }
})

AddRoom("painted_base_nobatcave", {
    colour = {r = 1.0, g = 1.0, b = 1.0, a = 0.3},
    value = WORLD_TILES.PAINTED,
    tags = {"ExitPiece", "Bramble"},
    contents = {
        distributepercent = .15,  -- .26
        distributeprefabs = {
            tubertree = 1,
            gnatmound = 0.1,
            rocks = 0.1,
            nitre = 0.1,
            flint = 0.05,
            iron = 0.2,
            thunderbirdnest = 0.1,
            sedimentpuddle = 0.1,
            pangolden = 0.005,
            goldnugget = 0.03,
        },
        countprefabs = {
            pangolden = 1,
        },
    }
})
