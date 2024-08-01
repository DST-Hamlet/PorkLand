ds_path = "D:/Program Files/Steam/steamapps/common/dont_starve"  -- don't dont_starve file path, need DLC003

local dst_string_path = "E:/my/game/Dont starve/Porklandstring"

package.path = package.path .. ";../?.lua"
package.path = package.path .. ";".. dst_string_path .. "/?.lua"
package.path = package.path .. ";".. ds_path .. "/data/scripts" .. "/?.lua"

keys = {  -- copy key = over key
    --["POG"] = "POG",

    ["ARMOR_WEEVOLE"] = "ARMOR_WEEVOLE",
    ["GASMASKHAT"] = "GASMASKHAT",
    ["BLUNDERBUSS"] = "BLUNDERBUSS",
    ["THUNDERHAT"] = "THUNDERHAT",
    ["ARMORVORTEXCLOAK"] = "ARMORVORTEXCLOAK",

    ["TURF_PIGRUINS"] = "TURF_PIGRUINS",
    ["TURF_RAINFOREST"] = "TURF_RAINFOREST",
    ["TURF_DEEPRAINFOREST"] = "TURF_DEEPRAINFOREST",
    ["TURF_GASJUNGLE"] = "TURF_GASJUNGLE",

    ["TURF_LAWN"] = "TURF_LAWN",
    ["TURF_MOSS"] = "TURF_MOSS",
    ["TURF_FIELDS"] = "TURF_FIELDS",
    ["TURF_FOUNDATION"] = "TURF_FOUNDATION",
    ["TURF_COBBLEROAD"] = "TURF_COBBLEROAD",

    ["TURF_PAINTED"] = "TURF_PAINTED",
    ["TURF_PLAINS"] = "TURF_PLAINS",
    ["TURF_DEEPRAINFOREST_NOCANOPY"] = "TURF_DEEPRAINFOREST_NOCANOPY",

    ["WINDOW_ROUND_CURTAINS_NAILS"] = "WINDOW_ROUND_CURTAINS_NAILS",
    ["WINDOW_ROUND_BURLAP"] = "WINDOW_ROUND_BURLAP",
    ["WINDOW_SMALL_PEAKED"] = "WINDOW_SMALL_PEAKED",
    ["WINDOW_LARGE_SQUARE"] = "WINDOW_LARGE_SQUARE",
    ["WINDOW_TALL"] = "WINDOW_TALL",
    ["WINDOW_LARGE_SQUARE_CURTAIN"] = "WINDOW_LARGE_SQUARE_CURTAIN",
    ["WINDOW_TALL_CURTAIN"] = "WINDOW_TALL_CURTAIN",
    ["WINDOW_SMALL_PEAKED_CURTAIN"] = "WINDOW_SMALL_PEAKED_CURTAIN",
    ["WINDOW_GREENHOUSE"] = "WINDOW_GREENHOUSE",
    ["WINDOW_ROUND"] = "WINDOW_ROUND",

    ["SNAKESKINHAT"] = "SNAKESKINHAT",
    ["ARMOR_SNAKESKIN"] = "ARMOR_SNAKESKIN",
    ["POISONBALM"] = "POISONBALM",

    --["CANDLEHAT"] = "CANDLEHAT",
    --["CORK_BAT"] = "CORK_BAT", 
    --["ANTMASKHAT"] = "ANTMASKHAT",
    --["ANTSUIT"] = "ANTSUIT",
    --["BUGREPELLENT"] = "BUGREPELLENT",
    --["GASCLOUD"] = "GASCLOUD",
    --["HOGUSPORKUSATOR"] = "HOGUSPORKUSATOR",
    --["DISGUISEHAT"] = "DISGUISEHAT",
    --["PITHHAT"] = "PITHHAT",
    --["BATHAT"] = "BATHAT",

    --["WALL_PIG_RUINS"] = "WALL_PIG_RUINS",
    --PORKLAND_INTRO stuff
    --["GNATMOUND"] = "GNATMOUND",
    --["GNAT"] = "GNAT",

    --[[
    ["CUTNETTLE"] = "CUTNETTLE",
    ["NETTLE"] = "NETTLE",
    ["DUG_NETTLE"] = "DUG_NETTLE",
    ["MEATED_NETTLE"] = "MEATED_NETTLE",
    ["NETTLELOSANGE"] = "NETTLELOSANGE",
    ["SPRINKLER"] = "SPRINKLER",
    ]]

    --[[
    ["THUNDERBIRD"] = "THUNDERBIRD",
    ["THUNDERBIRDNEST"] = "THUNDERBIRDNEST",
    ["FEATHER_THUNDER"] = "FEATHER_THUNDER",
    ]]

    --MOONDIAL
}

cn_input_strings = require("string_cn")
en_input_strings = require("string_en")

output_path = "../"
file_prefix = "pl_"
output_potpath = "../../scripts/languages/"
output_popath = output_potpath .. file_prefix

-- load in order, the later will overwrite the previous
-- first param is lua table or lua table file's path, the second param is po file path(if is language, will translate), the third param is whether to overwrite the old content
POT_GENERATION = true
require("strings")
data = {  -- lua file path = po file path
    -- {
    --     "F:/STEAM/steamapps/common/Don't Starve Together/mods/IslandAdventures/strings/",
    --     "F:/STEAM/steamapps/common/Don't Starve Together/modsIslandAdventures/languages/"
    -- },
    {  -- ds file path
        STRINGS,
        ds_path .. "/data/scripts/languages/",
        override = false,
    },
    {
        en_input_strings,  -- input string
        "en",
        override = false,
    },
    {
        cn_input_strings,  -- input string
        "zh-CN",  -- input language , use Google Translate
        override = false,
    },

}
