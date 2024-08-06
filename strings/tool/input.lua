ds_path = "D:/Program Files/Steam/steamapps/common/dont_starve"  -- don't dont_starve file path, need DLC003

local dst_string_path = "E:/my/game/Dont starve/Porklandstring"

package.path = package.path .. ";../?.lua"
package.path = package.path .. ";".. dst_string_path .. "/?.lua"
package.path = package.path .. ";".. ds_path .. "/data/scripts" .. "/?.lua"

keys = {  -- copy key = over key
    --["POG"] = "POG",

    ["CANDLEHAT"] = "CANDLEHAT",
    ["CORK_BAT"] = "CORK_BAT",
    ["ANTMASKHAT"] = "ANTMASKHAT",
    ["ANTSUIT"] = "ANTSUIT",
    ["BUGREPELLENT"] = "BUGREPELLENT",
    ["GASCLOUD"] = "GASCLOUD",
    ["HOGUSPORKUSATOR"] = "HOGUSPORKUSATOR",
    ["DISGUISEHAT"] = "DISGUISEHAT",
    ["PITHHAT"] = "PITHHAT",
    ["BATHAT"] = "BATHAT",

    ["WALL_PIG_RUINS"] = "WALL_PIG_RUINS",

    ["PORKLAND_INTRO_BASKET"] = "PORKLAND_INTRO_BASKET",
    ["PORKLAND_INTRO_BALLOON"] = "PORKLAND_INTRO_BALLOON",
    ["PORKLAND_INTRO_TRUNK"] = "PORKLAND_INTRO_TRUNK",
    ["PORKLAND_INTRO_SUITCASE"] = "PORKLAND_INTRO_SUITCASE",
    ["PORKLAND_INTRO_FLAGS"] = "PORKLAND_INTRO_FLAGS",
    ["PORKLAND_INTRO_SANDBAG"] = "PORKLAND_INTRO_SANDBAG",

    ["CITY_HAMMER"] = "CITY_HAMMER",

    ["GNATMOUND"] = "GNATMOUND",
    ["GNAT"] = "GNAT",

    ["CUTNETTLE"] = "CUTNETTLE",
    ["NETTLE"] = "NETTLE",
    ["DUG_NETTLE"] = "DUG_NETTLE",
    ["MEATED_NETTLE"] = "MEATED_NETTLE",
    ["NETTLELOSANGE"] = "NETTLELOSANGE",
    ["SPRINKLER"] = "SPRINKLER",

    ["THUNDERBIRD"] = "THUNDERBIRD",
    ["THUNDERBIRDNEST"] = "THUNDERBIRDNEST",
    ["FEATHER_THUNDER"] = "FEATHER_THUNDER",

    ["PIG_RUINS_ENTRANCE"] = "PIG_RUINS_ENTRANCE",
    ["PIG_RUINS_ENTRANCE2"] = "PIG_RUINS_ENTRANCE2",
    ["PIG_RUINS_ENTRANCE3"] = "PIG_RUINS_ENTRANCE3",
    ["PIG_RUINS_ENTRANCE4"] = "PIG_RUINS_ENTRANCE4",
    ["PIG_RUINS_ENTRANCE5"] = "PIG_RUINS_ENTRANCE5",
    ["PIG_RUINS_ENTRANCE_SMALL"] = "PIG_RUINS_ENTRANCE_SMALL",
    ["PIG_RUINS_EXIT"] = "PIG_RUINS_EXIT",
    ["PIG_RUINS_EXIT2"] = "PIG_RUINS_EXIT2",
    ["PIG_RUINS_EXIT4"] = "PIG_RUINS_EXIT4",

    ["ANTMAN"] = "ANTMAN",
    ["ANTMAN_WARRIOR"] = "ANTMAN_WARRIOR",

    ["PHEROMONESTONE"] = "PHEROMONESTONE",
    ["PIG_RUINS_TORCH_WALL"] = "PIG_RUINS_TORCH_WALL",
    ["PIG_RUINS_TORCH"] = "PIG_RUINS_TORCH",

    ["SMASHINGPOT"] = "SMASHINGPOT",

    ["PIG_RUINS_DART_TRAP"] = "PIG_RUINS_DART_TRAP",
    ["PIG_RUINS_SPEAR_TRAP"] = "PIG_RUINS_SPEAR_TRAP",
    ["PIG_RUINS_SPEAR_TRAP_TRIGGERED"] = "PIG_RUINS_SPEAR_TRAP_TRIGGERED",
    ["PIG_RUINS_SPEAR_TRAP_BROKEN"] = "PIG_RUINS_SPEAR_TRAP_BROKEN",
    ["PIG_RUINS_PRESSURE_PLATE"] = "PIG_RUINS_PRESSURE_PLATE",
    ["PIG_RUINS_DART_STATUE"] = "PIG_RUINS_DART_STATUE",

    ["DECO_RUINS_FOUNTAIN"] = "DECO_RUINS_FOUNTAIN",
    ["DECO_RUINS_ENDSWELL"] = "DECO_RUINS_ENDSWELL",

    ["DECO_RUINS_BEAM_ROOM"] = "DECO_RUINS_BEAM_ROOM",
    ["DECO_CAVE_BEAM_ROOM"] = "DECO_CAVE_BEAM_ROOM",
    ["DECO_CAVE_BAT_BURROW"] = "DECO_CAVE_BAT_BURROW",
    ["DECO_RUINS_BEAM_ROOM_BLUE"] = "DECO_RUINS_BEAM_ROOM_BLUE",

    ["ANTCOMBHOME"] = "ANTCOMBHOME",
    ["SECURITYCONTRACT"] = "SECURITYCONTRACT",

    ["PLAYERHOUSE_CITY"] = "PLAYERHOUSE_CITY",
    ["JELLYBUG"] = "JELLYBUG",
    ["JELLYBUG_COOKED"] = "JELLYBUG_COOKED",
    ["SLUGBUG"] = "SLUGBUG",
    ["SLUGBUG_COOKED"] = "SLUGBUG_COOKED",

    ["PLAYER_HOUSE_COTTAGE_CRAFT"] = "PLAYER_HOUSE_COTTAGE_CRAFT",
    ["PLAYER_HOUSE_VILLA_CRAFT"] = "PLAYER_HOUSE_VILLA_CRAFT",
    ["PLAYER_HOUSE_TUDOR_CRAFT"] = "PLAYER_HOUSE_TUDOR_CRAFT",
    ["PLAYER_HOUSE_GOTHIC_CRAFT"] = "PLAYER_HOUSE_GOTHIC_CRAFT",
    ["PLAYER_HOUSE_TURRET_CRAFT"] = "PLAYER_HOUSE_TURRET_CRAFT",
    ["PLAYER_HOUSE_BRICK_CRAFT"] = "PLAYER_HOUSE_BRICK_CRAFT",
    ["PLAYER_HOUSE_MANOR_CRAFT"] = "PLAYER_HOUSE_MANOR_CRAFT",
    ["CLIPPINGS"] = "CLIPPINGS",

    ["BANDITMAP"] = "BANDITMAP",
    ["BANDITTREASURE"] = "BANDITTREASURE",

    ["ROCK_ANTCAVE"] = "ROCK_ANTCAVE",
    ["ANT_CAVE_LANTERN"] = "ANT_CAVE_LANTERN",

    ["PLAYER_HOUSE_COTTAGE"] = "PLAYER_HOUSE_COTTAGE",
    ["PLAYER_HOUSE_VILLA"] = "PLAYER_HOUSE_VILLA",
    ["PLAYER_HOUSE_TUDOR"] = "PLAYER_HOUSE_TUDOR",
    ["PLAYER_HOUSE_MANOR"] = "PLAYER_HOUSE_MANOR",
    ["PLAYER_HOUSE_GOTHIC"] = "PLAYER_HOUSE_GOTHIC",
    ["PLAYER_HOUSE_BRICK"] = "PLAYER_HOUSE_BRICK",
    ["PLAYER_HOUSE_TURRET"] = "PLAYER_HOUSE_TURRET",

    ["DEED"] = "DEED",
    ["CONSTRUCTION_PERMIT"] = "CONSTRUCTION_PERMIT",
    ["DEMOLITION_PERMIT"] = "DEMOLITION_PERMIT",

    ["BANDITHAT"] = "BANDITHAT",
    ["PIGBANDIT"] = "PIGBANDIT",

    ["PIG_RUINS_CREEPING_VINES"] = "PIG_RUINS_CREEPING_VINES",

    ["PIGMAN_HUNTER"] = "PIGMAN_HUNTER",
    ["PIGMAN_PROFESSOR"] = "PIGMAN_PROFESSOR",
    ["PIGMAN_HATMAKER"] = "PIGMAN_HATMAKER",
    ["PIGMAN_ERUDITE"] = "PIGMAN_ERUDITE",
    ["PIGMAN_STOREOWNER"] = "PIGMAN_STOREOWNER",
    ["PIGMAN_FLORIST"] = "PIGMAN_FLORIST",
    ["PIGMAN_FARMER"] = "PIGMAN_FARMER",
    ["PIGMAN_MECHANIC"] = "PIGMAN_MECHANIC",
    ["PIGMAN_MINER"] = "PIGMAN_MINER",
    ["PIGMAN_BANKER"] = "PIGMAN_BANKER",
    ["PIGMAN_COLLECTOR"] = "PIGMAN_COLLECTOR",
    ["PIGMAN_BEAUTICIAN"] = "PIGMAN_BEAUTICIAN",

    ["PIG_SHOP_TINKER"] = "PIG_SHOP_TINKER",
    ["PIG_SHOP_ACADEMY"] = "PIG_SHOP_ACADEMY",
    ["PIG_SHOP_HATSHOP"] = "PIG_SHOP_HATSHOP",
    ["PIG_SHOP_WEAPONS"] = "PIG_SHOP_WEAPONS",
    ["PIG_SHOP_ARCANE"] = "PIG_SHOP_ARCANE",
    ["PIG_SHOP_PRODUCE"] = "PIG_SHOP_PRODUCE",
    ["PIG_SHOP_HOOFSPA"] = "PIG_SHOP_HOOFSPA",
    ["PIG_SHOP_GENERAL"] = "PIG_SHOP_GENERAL",
    ["PIG_SHOP_FLORIST"] = "PIG_SHOP_FLORIST",
    ["RECONSTRUCTION_PROJECT"] = "RECONSTRUCTION_PROJECT",

    ["PIG_SHOP_BANK"] = "PIG_SHOP_BANK",
    ["PIGMAN_USHER"] = "PIGMAN_USHER",
    ["PIGMAN_ROYALGUARD_2"] = "PIGMAN_ROYALGUARD_2",
    ["PIG_SHOP_ANTIQUITIES"] = "PIG_SHOP_ANTIQUITIES",

    ["WALLCRACK_RUINS"] = "WALLCRACK_RUINS",
    ["HEDGE"] = "HEDGE",
    ["TOPIARY"] = "TOPIARY",

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
