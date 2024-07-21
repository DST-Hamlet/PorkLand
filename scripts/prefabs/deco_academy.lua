local DecoCreator = require("prefabs/deco_util")

local lights = DecoCreator:GetLights()

return  DecoCreator:Create("deco_accademy_barrier",           "interior_wall_decals_accademia", "wall_decals_accademia", "velvetrope_backwall",   {physics = "sofa_physics", tags = {"furniture"}, onbuilt = true}),
        DecoCreator:Create("deco_accademy_barrier_vert",      "interior_wall_decals_accademia", "wall_decals_accademia", "velvetrope_sidewall",   {physics = "sofa_physics_vert", tags = {"furniture"}, onbuilt = true, decal = true}),
        DecoCreator:Create("deco_accademy_vause",             "interior_wall_decals_accademia", "wall_decals_accademia", "sculpture_vase",        {tags = {"furniture"}, onbuilt = true }),
        DecoCreator:Create("deco_accademy_graniteblock",      "interior_wall_decals_accademia", "wall_decals_accademia", "stoneblock",            {physics = "post_physics", tags = {"furniture"}, onbuilt = true}),
        DecoCreator:Create("deco_accademy_potterywheel_urn",  "interior_wall_decals_accademia", "wall_decals_accademia", "pottingwheel_urn",      {physics = "post_physics", tags = {"furniture"}, onbuilt = true}),
        DecoCreator:Create("deco_accademy_potterywheel",      "interior_wall_decals_accademia", "wall_decals_accademia", "pottingwheel",          {physics = "post_physics", tags = {"furniture"}, onbuilt = true}),
        DecoCreator:Create("deco_accademy_anvil",             "interior_wall_decals_accademia", "wall_decals_accademia", "anvil",                 {physics = "post_physics", tags = {"furniture"}, onbuilt = true}),
        DecoCreator:Create("deco_accademy_table_books",       "interior_wall_decals_accademia", "wall_decals_accademia", "table_books",           {physics = "post_physics", tags = {"furniture"}, onbuilt = true}),
        DecoCreator:Create("deco_accademy_cornerbeam",        "interior_wall_decals_accademia", "wall_decals_accademia", "pillar_square_front",   {decal = true, loopanim = true, light = lights.SMALL, tags = {"cornerpost"}, onbuilt = true}),
        DecoCreator:Create("deco_accademy_beam",              "interior_wall_decals_accademia", "wall_decals_accademia", "pillar_square_corner",  {decal = true, loopanim = true, light = lights.SMALL}),
        DecoCreator:Create("deco_accademy_pig_king_painting", "interior_wall_decals_accademia", "wall_decals_accademia", "picture_backwall",      {decal = true, tags = {"wallsection"}, onbuilt = true})
