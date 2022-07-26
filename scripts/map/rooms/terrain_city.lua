AddRoom("BG_city_base", {
    colour = {r = .1, g = 0.1, b = 0.1, a = 0.3},
	value = WORLD_TILES.SUBURB,
	tags = {"ExitPiece", "City_Foundation"},
	contents = {
		distributepercent = 0.1,
		distributeprefabs = {
			rocks = 1,
			grass = 1,
			poiled_food = 1,
			wigs = 1,
		},
	}
})


local cityContents = {
    distributepercent = 0.1,
    distributeprefabs = {
		rocks = 1,
		grass = 1,
		spoiled_food = 1,
		twigs = 1,
    },
}

AddRoom("city_base_1", {
    colour = {r = .1, g = 0.1, b = 0.1, a = 0.3},
	value = WORLD_TILES.SUBURB,
	tags = {"ExitPiece", "City_Foundation", "City1"},
	contents = cityContents
})


AddRoom("city_base_2", {
    colour = {r = .1, g = 0.1, b = 0.1, a = 0.3},
	value = WORLD_TILES.SUBURB,
	tags = {"ExitPiece", "City_Foundation", "City2"},
	contents = cityContents
})