
AddRoom("BG_rainforest_base", {
    colour = {r = 1.0, g = 1.0, b = 1.0, a = 0.3},
    value = WORLD_TILES.RAINFOREST,
    tags = {"ExitPiece", "Bramble"},
    contents = {
        distributepercent = .38, --.5
        distributeprefabs = {
			rainforesttree = 0.6,--1.4,
			grass_tall = .5,
			sapling = .6,
			flower_rainforest = 0.15,
			--flower = 0.05,
			dungpile = 0.03,
			fireflies = 0.05,
			peagawk_spawner = 0.01,
			--	randomrelic = 0.008,
			--	randomruin = 0.005,
			randomdust = 0.005,
			rock_flippable = 0.08,
			radish_planted = 0.05,
			asparagus_planted = 0.05,
    	},
    	countprefabs = {
        	vampirebatcave_potential = 1,
    	},
    }
})

AddRoom("rainforest_ruins", {
    colour = {r = 0.0, g = 1, b = 0.3, a = 0.3},
    value = WORLD_TILES.RAINFOREST,
    tags = {"ExitPiece", "Bramble"},
    contents = {
        distributepercent =.35, -- .5
		distributeprefabs = {
			rainforesttree = .5,--.7,
			grass_tall = 0.5,
			sapling = .6,
			flower_rainforest = 0.15,
			--flower = 0.05,
						--	randomrelic = 0.008,
						--	randomruin = 0.005,
			randomdust = 0.005,
			rock_flippable = 0.08,
			radish_planted = 0.05,
			asparagus_planted = 0.05,
    	},
		countprefabs = {
			pig_ruins_entrance_small = 1,
			vampirebatcave_potential = 1,
		},
    }
})


AddRoom("rainforest_lillypond", {
    colour = {r = 1.0, g = 0.3, b = 0.3, a = 0.3},
    value = WORLD_TILES.LILYPOND,
    tags = {"ExitPiece", "Bramble"},
    contents = {
    	countstaticlayouts = {
			["lilypad2"]= math.random(1, 3),
			["lilypad"]= math.random(4, 8),
    	},

        distributepercent = .3, -- .3

        distributeprefabs = {
			--lilypad = 2,
			reeds_water = 3,
			lotus = 2,
			hippopotamoose = 0.08,
			relic_1 = 0.04,
			relic_2 = 0.04,
			relic_3 = 0.04,
        },
		countprefabs = {
			hippopotamoose = 1,
		},
    }
})

AddRoom("rainforest_pugalisk", {
    colour = {r = 0.0, g = 1, b = 0.3, a = 0.3},
    value = WORLD_TILES.RAINFOREST,
    tags = {"ExitPiece", "Bramble"},
    contents = {
        distributepercent = .15, -- .3
        distributeprefabs = {
			rainforesttree = .7,
			grass_tall = 0.5,
			sapling = .6,
			flower_rainforest = 0.15,
						--	flower = 0.05,
						--	randomrelic = 0.008,
						--	randomruin = 0.005,
			randomdust = 0.005,
			rock_flippable = 0.08,
			radish_planted = 0.05,
			asparagus_planted = 0.05,
        },
		countprefabs = {
			pugalisk = 1
		},
    }
})

AddRoom("rainforest_base_nobatcave", {
    colour = {r = 1.0, g = 1.0, b = 1.0, a = 0.3},
    value = WORLD_TILES.RAINFOREST,
    tags = {"ExitPiece", "Bramble"},
    contents = {
        distributepercent = .38, --.5
        distributeprefabs = {
			rainforesttree = 0.6,--1.4,
			grass_tall = .5,
			sapling = .6,
			flower_rainforest = 0.15,
			--flower = 0.05,
			dungpile = 0.03,
			fireflies = 0.05,
			peagawk_spawner = 0.01,
			--	randomrelic = 0.008,
			--	randomruin = 0.005,
			randomdust = 0.005,
			rock_flippable = 0.08,
			radish_planted = 0.05,
			asparagus_planted = 0.05,
    	},
    }
})