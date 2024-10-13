local DecoCreator = require("prefabs/deco_util")

local lights = DecoCreator:GetLights()
local light_small = lights.SMALL
local light_festive = lights.FESTIVETREE
local tag = {"furniture", "rotatableobject"}

return  DecoCreator:Create("deco_lamp_fringe",                 "interior_floorlamp",   "interior_floorlamp",   "floorlamp_fringe",       {physics = "post_physics", light = light_small,   tags = tag, onbuilt = true}),
        DecoCreator:Create("deco_lamp_stainglass",             "interior_floorlamp",   "interior_floorlamp",   "floorlamp_stainglass",   {physics = "post_physics", light = light_small,   tags = tag, onbuilt = true}),
        DecoCreator:Create("deco_lamp_downbridge",             "interior_floorlamp",   "interior_floorlamp",   "floorlamp_downbridge",   {physics = "post_physics", light = light_small,   tags = tag, onbuilt = true}),
        DecoCreator:Create("deco_lamp_2embroidered",           "interior_floorlamp",   "interior_floorlamp",   "floorlamp_2embroidered", {physics = "post_physics", light = light_small,   tags = tag, onbuilt = true}),
        DecoCreator:Create("deco_lamp_ceramic",                "interior_floorlamp",   "interior_floorlamp",   "floorlamp_ceramic",      {physics = "post_physics", light = light_small,   tags = tag, onbuilt = true}),
        DecoCreator:Create("deco_lamp_glass",                  "interior_floorlamp",   "interior_floorlamp",   "floorlamp_glass",        {physics = "post_physics", light = light_small,   tags = tag, onbuilt = true}),
        DecoCreator:Create("deco_lamp_2fringes",               "interior_floorlamp",   "interior_floorlamp",   "floorlamp_2fringes",     {physics = "post_physics", light = light_small,   tags = tag, onbuilt = true}),
        DecoCreator:Create("deco_lamp_candelabra",             "interior_floorlamp",   "interior_floorlamp",   "floorlamp_candelabra",   {physics = "post_physics", light = light_small,   tags = tag, onbuilt = true}),
        DecoCreator:Create("deco_lamp_elizabethan",            "interior_floorlamp",   "interior_floorlamp",   "floorlamp_elizabethan",  {physics = "post_physics", light = light_small,   tags = tag, onbuilt = true}),
        DecoCreator:Create("deco_lamp_gothic",                 "interior_floorlamp",   "interior_floorlamp",   "floorlamp_gothic",       {physics = "post_physics", light = light_small,   tags = tag, onbuilt = true}),
        DecoCreator:Create("deco_lamp_orb",                    "interior_floorlamp",   "interior_floorlamp",   "floorlamp_orb",          {physics = "post_physics", light = light_small,   tags = tag, onbuilt = true}),
        DecoCreator:Create("deco_lamp_bellshade",              "interior_floorlamp",   "interior_floorlamp",   "floorlamp_bellshade",    {physics = "post_physics", light = light_small,   tags = tag, onbuilt = true}),
        DecoCreator:Create("deco_lamp_crystals",               "interior_floorlamp",   "interior_floorlamp",   "floorlamp_crystals",     {physics = "post_physics", light = light_small,   tags = tag, onbuilt = true}),
        DecoCreator:Create("deco_lamp_upturn",                 "interior_floorlamp",   "interior_floorlamp",   "floorlamp_upturn",       {physics = "post_physics", light = light_small,   tags = tag, onbuilt = true}),
        DecoCreator:Create("deco_lamp_2upturns",               "interior_floorlamp",   "interior_floorlamp",   "floorlamp_2upturns",     {physics = "post_physics", light = light_small,   tags = tag, onbuilt = true}),
        DecoCreator:Create("deco_lamp_spool",                  "interior_floorlamp",   "interior_floorlamp",   "floorlamp_spool",        {physics = "post_physics", light = light_small,   tags = tag, onbuilt = true}),
        DecoCreator:Create("deco_lamp_edison",                 "interior_floorlamp",   "interior_floorlamp",   "floorlamp_edison",       {physics = "post_physics", light = light_small,   tags = tag, onbuilt = true}),
        DecoCreator:Create("deco_lamp_adjustable",             "interior_floorlamp",   "interior_floorlamp",   "floorlamp_adjustable",   {physics = "post_physics", light = light_small,   tags = tag, onbuilt = true}),
        DecoCreator:Create("deco_lamp_rightangles",            "interior_floorlamp",   "interior_floorlamp",   "floorlamp_rightangles",  {physics = "post_physics", light = light_small,   tags = tag, onbuilt = true}),
        DecoCreator:Create("deco_lamp_hoofspa",                "interior_floor_decor", "interior_floor_decor", "lamp",                   {physics = "post_physics", light = light_small,   tags = tag, onbuilt = true}),
        DecoCreator:Create("deco_plantholder_winterfeasttree", "interior_floorlamp",   "interior_floorlamp",   "festivetree_idle",       {physics = "post_physics", light = light_festive, tags = tag, onbuilt = true, loopanim = true, blink = true})
