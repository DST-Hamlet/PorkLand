AddRoom("BG_saltlake_beach", {
    colour = {r = .1, g = 0.1, b = 0.1, a = 0.3}, --鲁鲁：这是啥？
    value = WORLD_TILES.SALTLAKE_NOISE,
    tags = {"ExitPiece"},
    contents = {
        distributepercent = 0.1,--鲁鲁：这是啥？
        distributeprefabs = {
            saltrock = 0.01,
            rocks = 0.01,
            nitre = 0.01,
            tallbirdnest = 0.001,
        },
    }
})

AddRoom("saltlake_beach", {
    colour = {r = 1.0, g = 1.0, b = 1.0, a = 0.3}, --鲁鲁：这是啥？
    value = WORLD_TILES.SALTBEACH,
    tags = {"ExitPiece"},
    contents = {
        distributepercent = .15,  -- .26 --鲁鲁：这是啥？
        distributeprefabs = {
            saltrock = 0.01,
            nitre = 0.01,
            tallbirdnest = 0.001,
        },
        countprefabs = {
            tallbirdnest = 3,
        },
    }
})

AddRoom("saltlake_lake", {
    colour = {r = 1.0, g = 0.3, b = 0.3, a = 0.3}, --鲁鲁：这是啥？
    value = WORLD_TILES.LILYPOND,
    tags = {},
    contents = {
        --[[countstaticlayouts = {
            ["lilypad2"]= math.random(1, 3),
            ["lilypad"]= math.random(4, 8),
        },]]

        distributepercent = .3, --鲁鲁：这是啥？

        distributeprefabs = {
            saltstack = 0.04,
            saltrock = 0.01,
            relic_1 = 0.04,
            relic_2 = 0.04,
            relic_3 = 0.04,
        },
    }
})