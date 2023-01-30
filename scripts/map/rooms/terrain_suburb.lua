AddRoom("BG_suburb_base", {
    colour = {r = .3, g = 0.3, b = 0.3, a = 0.3},
    value = WORLD_TILES.SUBURB,
    tags = {"ExitPiece", "City_Foundation", "Suburb"},
    contents = {
        distributepercent = 0.1,
        distributeprefabs = {
            rocks = 1,
            grass = 1,
            spoiled_food = 1,
            twigs = 1,
        },
    }
})

local suburb_contents =  {
    distributepercent = 0.1,
    distributeprefabs = {
        rocks = 1,
        grass = 1,
        spoiled_food = 1,
        twigs = 1,
    },
}

AddRoom("suburb_base_1", {
    colour = {r = .3, g = 0.3, b = 0.3, a = 0.3},
    value = WORLD_TILES.SUBURB,
    tags = {"ExitPiece", "City_Foundation", "City1", "Suburb"},
    contents = suburb_contents
})

AddRoom("suburb_base_2", {
    colour = {r = .3,g = 0.3, b = 0.3, a = 0.3},
    value = WORLD_TILES.SUBURB,
    tags = {"ExitPiece", "City_Foundation", "City2", "Suburb"},
    contents = suburb_contents
})
