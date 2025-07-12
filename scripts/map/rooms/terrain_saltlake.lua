AddRoom("BG_saltlakebeach", {
    colour = {r = .1, g = 0.1, b = 0.1, a = 0.3},--这是啥？
    value = WORLD_TILES.SALT,
    tags = {"ExitPiece"},
    contents = {
        distributepercent = 0.1,--这是啥？
        distributeprefabs = {
            saltrock = 0.1,
            tallbirdnest= 0.1,
        },
    }
})
--[[
AddRoom("Saltlake", {
    colour = {r = .1, g = 0.1, b = 0.1, a = 0.3},--这是啥？
    value = WORLD_TILES.SALTLAKE,
    tags = {"ExitPiece"},
    contents = {
        distributepercent = 0.1,--这是啥？
        distributeprefabs = {
            saltrock = 0.1,
            poiled_food = 1,
            wigs = 1,
        },
    }
})
    --]]