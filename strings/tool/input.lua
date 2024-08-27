ds_path = "D:/Program Files/Steam/steamapps/common/dont_starve"  -- don't dont_starve file path, need DLC003

local dst_string_path = "E:/my/game/Dont starve/Porklandstring"

package.path = package.path .. ";../?.lua"
package.path = package.path .. ";".. dst_string_path .. "/?.lua"
package.path = package.path .. ";".. ds_path .. "/data/scripts" .. "/?.lua"

keys = {  -- copy key = over key
["INTERIOR_WALL_CHECKERED"] = "INTERIOR_WALL_CHECKERED",
["INTERIOR_WALL_CIRCLES"] = "INTERIOR_WALL_CIRCLES",
["INTERIOR_WALL_FLORAL"] = "INTERIOR_WALL_FLORAL",
["INTERIOR_WALL_FULLWALL_MOULDING"] = "INTERIOR_WALL_FULLWALL_MOULDING",
["INTERIOR_WALL_HARLEQUIN"] = "INTERIOR_WALL_HARLEQUIN",
["INTERIOR_WALL_MARBLE"] = "INTERIOR_WALL_MARBLE",
["INTERIOR_WALL_MAYORSOFFICE"] = "INTERIOR_WALL_MAYORSOFFICE",
["INTERIOR_WALL_PEAGAWK"] = "INTERIOR_WALL_PEAGAWK",
["INTERIOR_WALL_PLAIN_DS"] = "INTERIOR_WALL_PLAIN_DS",
["INTERIOR_WALL_PLAIN_ROG"] = "INTERIOR_WALL_PLAIN_ROG",
["INTERIOR_WALL_ROPE"] = "INTERIOR_WALL_ROPE",
["INTERIOR_WALL_SUNFLOWER"] = "INTERIOR_WALL_SUNFLOWER",
["INTERIOR_WALL_UPHOLSTERED"] = "INTERIOR_WALL_UPHOLSTERED",
["INTERIOR_WALL_WOOD"] = "INTERIOR_WALL_WOOD",

["INTERIOR_FLOOR_CHECK"] = "INTERIOR_FLOOR_CHECK",
["INTERIOR_FLOOR_GARDENSTONE"] = "INTERIOR_FLOOR_GARDENSTONE",
["INTERIOR_FLOOR_GEOMETRICTILES"] = "INTERIOR_FLOOR_GEOMETRICTILES",
["INTERIOR_FLOOR_HERRINGBONE"] = "INTERIOR_FLOOR_HERRINGBONE",
["INTERIOR_FLOOR_HEXAGON"] = "INTERIOR_FLOOR_HEXAGON",
["INTERIOR_FLOOR_HOOF_CURVY"] = "INTERIOR_FLOOR_HOOF_CURVY",
["INTERIOR_FLOOR_MARBLE"] = "INTERIOR_FLOOR_MARBLE",
["INTERIOR_FLOOR_OCTAGON"] = "INTERIOR_FLOOR_OCTAGON",
["INTERIOR_FLOOR_PLAID_TILE"] = "INTERIOR_FLOOR_PLAID_TILE",
["INTERIOR_FLOOR_SHAG_CARPET"] = "INTERIOR_FLOOR_SHAG_CARPET",
["INTERIOR_FLOOR_SHEET_METAL"] = "INTERIOR_FLOOR_SHEET_METAL",
["INTERIOR_FLOOR_TRANSITIONAL"] = "INTERIOR_FLOOR_TRANSITIONAL",
["INTERIOR_FLOOR_WOOD"] = "INTERIOR_FLOOR_WOOD",
["INTERIOR_FLOOR_WOODPANELS"] = "INTERIOR_FLOOR_WOODPANELS",
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
