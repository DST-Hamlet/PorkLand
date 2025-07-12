AddRoom("BG_saltlake_beach", {
    colour = {r = .1, g = 0.1, b = 0.1, a = 0.3},--这是啥？
    value = WORLD_TILES.SALT,
    tags = {"ExitPiece"},
    contents = {
        distributepercent = 0.1,--这是啥？
        distributeprefabs = {
            saltrock = 0.1,
            nitre = 0.05,
            tallbirdnest = 0.001,
        },
        countprefabs = {
            tallbirdnest = 1,
        },
    }
})

AddRoom("saltlake_beach", {
    colour = {r = 1.0, g = 1.0, b = 1.0, a = 0.3},
    value = WORLD_TILES.SALT,
    tags = {"ExitPiece"},
    contents = {
        distributepercent = .15,  -- .26
        distributeprefabs = {
            saltrock = 0.1,
            nitre = 0.05,
        },
        countprefabs = {
            tallbirdnest = 1,
        },
    }
})

AddRoom("saltlake_lake", {
    colour = {r = 1.0, g = 0.3, b = 0.3, a = 0.3},
    value = WORLD_TILES.LILYPOND,
    tags = {"ExitPiece"},
    contents = {
        --[[countstaticlayouts = {
            ["lilypad2"]= math.random(1, 3),
            ["lilypad"]= math.random(4, 8),
        },]]

        distributepercent = .3,

        distributeprefabs = {
            -- lilypad = 2,
            saltstack = 0.1,
            saltrock = 0.01,
            relic_1 = 0.04,
            relic_2 = 0.04,
            relic_3 = 0.04,
        },
    }
})