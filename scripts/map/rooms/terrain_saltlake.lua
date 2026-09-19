AddRoom("BG_saltlake_beach", {
    colour = {r = .1, g = 0.1, b = 0.1, a = 0.3},
    value = WORLD_TILES.SALTLAKE_NOISE,
    tags = {},
    contents = {
        distributepercent = 0.1,--鲁鲁：这是啥？
        distributeprefabs = {
            rock_flippable = 0.1,
            rock_flintless = 0.3,
            saltrock = 0.02,
            rocks = 0.02,
            nitre = 0.02,
            roc_nest_branch1 = 0.05,
            roc_nest_branch2 = 0.05,
            tallbirdnest = 0.0002,
        },
    }
})

AddRoom("saltlake_beach", {
    colour = {r = 1.0, g = 1.0, b = 1.0, a = 0.3},
    value = WORLD_TILES.SALTLAKE_NOISE,
    tags = {},
    contents = {
        distributepercent = 0.1,  -- .26 --鲁鲁：这是啥？
        distributeprefabs = {
            saltrock = 0.01,
            nitre = 0.01,
            rock_flippable = 0.05,
            roc_nest_branch1 = 0.01,
            roc_nest_branch2 = 0.01,
            tallbirdnest = 0.02,
        },
        countprefabs = {
            tallbirdnest = 3,
        },
    }
})

AddRoom("saltlake_lake", {
    colour = {r = 1.0, g = 0.3, b = 0.3, a = 0.3},
    value = WORLD_TILES.SALTLAKE,
    tags = {},
    contents = {
        distributepercent = .1, --鲁鲁：这是啥？

        distributeprefabs = {
            saltstack = 0.001,
            saltrock = 0.001,
            seastack = 0.001,
            --relic_1 = 0.04,
            --relic_2 = 0.04,
            --relic_3 = 0.04,
        },
    }
})