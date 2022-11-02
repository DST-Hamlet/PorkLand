AddRoom("BG_plains_base", {
    colour = {r = 1.0, g = 1.0, b = 1.0, a = 0.3},
    value = WORLD_TILES.PLAINS,
    tags = {"ExitPiece", "Bramble"},
    contents = {
        distributepercent = .25, --.22, --.26
        distributeprefabs = {
			clawpalmtree = 0.5,
			grass_tall = 1,
			sapling = .3,
			flower_rainforest = 0.05,
			dungpile = 0.03,
			peagawk_spawner = 0.01,
			-- randomrelic = 0.0016,
			-- randomruin = 0.0025,
			randomdust = 0.0025,
			rock_flippable = 0.08,
			aloe_planted = 0.08,
			pog = 0.01,
			asparagus_planted = 0.05,
        },
        countprefabs = {
        	grass_tall_patch = 2,
        	vampirebatcave_potential = 1,
        },
    }
})

AddRoom("plains_tallgrass", {
    colour = {r = 0.0, g = 1, b = 0.3, a = 0.3},
    value = WORLD_TILES.PLAINS,
    tags = {"ExitPiece", "Bramble"},
    contents = {
        distributepercent = .15,-- .15, -- .3
        distributeprefabs = {
			clawpalmtree = .25,
			grass_tall = 1,
			flower_rainforest = 0.05,
					--		randomrelic = 0.0016,
			--randomruin = 0.0025,
			randomdust = 0.0025,
			rock_flippable = 0.08,
			aloe_planted = 0.08,
			pog = 0.01,
			asparagus_planted = 0.05,
        },
        countprefabs = {
        	grass_tall_patch = 2,
        	vampirebatcave_potential = 1,
        },
    }
})

AddRoom("plains_ruins", {
    colour = {r = 0.0, g = 1, b = 0.3, a = 0.3},
    value = WORLD_TILES.PLAINS,
    tags = {"ExitPiece", "Bramble"},
    contents = {
        distributepercent = .25,-- .15, -- .3
        distributeprefabs = {
			clawpalmtree = .25,
			grass_tall = 1,
			flower_rainforest = 0.05,
			-- randomrelic = 0.0016,
			-- randomruin = 0.0025,
			randomdust = 0.0025,
			rock_flippable = 0.08,
			aloe_planted = 0.08,
			pog = 0.01,
			asparagus_planted = 0.05,
        },
        countprefabs = {
        	grass_tall_patch = 2,
        	pig_ruins_entrance_small = 1,
        	vampirebatcave_potential = 1,
        },
    }
})

AddRoom("plains_pogs", {
    colour = {r = 0.0, g = 1, b = 0.3, a = 0.3},
    value = WORLD_TILES.PLAINS,
    tags = {"ExitPiece", "Bramble"},
    contents = {
        distributepercent = .25,-- .15, -- .3
        distributeprefabs = {
			clawpalmtree = .25,
			grass_tall = 1,
			flower_rainforest = 0.05,
			pog = 0.1,
			randomdust = 0.0025,
			rock_flippable = 0.08,
			aloe_planted = 0.08,
			asparagus_planted = 0.05,
        },
        countprefabs = {
        	pog = 2,
        	pig_ruins_entrance_small = 2,
        	vampirebatcave_potential = 1,
        },
    }
})

AddRoom("plains_base_nobatcave", {
    colour = {r = 1.0, g = 1.0, b = 1.0, a = 0.3},
    value = WORLD_TILES.PLAINS,
    tags = {"ExitPiece", "Bramble"},
    contents = {
        distributepercent = .25, --.22, --.26
        distributeprefabs = {
			clawpalmtree = 0.5,
			grass_tall = 1,
			sapling = .3,
			flower_rainforest = 0.05,
			dungpile = 0.03,
			peagawk_spawner = 0.01,
			-- randomrelic = 0.0016,
			-- randomruin = 0.0025,
			randomdust = 0.0025,
			rock_flippable = 0.08,
			aloe_planted = 0.08,
			pog = 0.01,
        asparagus_planted = 0.05,
        },
        countprefabs = {
        	grass_tall_patch = 2,
        },
    }
})