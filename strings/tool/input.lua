ds_path = "D:/Program Files/Steam/steamapps/common/dont_starve"  -- don't dont_starve file path, need DLC003

local dst_string_path = "E:/my/game/Dont starve/Porklandstring"

package.path = package.path .. ";../?.lua"
package.path = package.path .. ";".. dst_string_path .. "/?.lua"
package.path = package.path .. ";".. ds_path .. "/data/scripts" .. "/?.lua"

keys = {  -- copy key = over key
    ["FROG_POISON"] = "FROG_POISON",
    ["FROGLEGS_POISON"] = "FROGLEGS_POISON",
    ["FROGLEGS_POISON_COOKED"] = "FROGLEGS_POISON_COOKED",
    ["HIPPO_ANTLER"] = "HIPPO_ANTLER",
    ["HIPPOPOTAMOOSE"] = "HIPPOPOTAMOOSE",
    ["FROG_POISON_SETTING"] = "FROG_POISON_SETTING",
    ["PUGALISK_FOUNTAIN"] = "PUGALISK_FOUNTAIN",
    ["ANNOUNCE_PUGALISK_INVULNERABLE"] = "ANNOUNCE_PUGALISK_INVULNERABLE",
    ["PUGALISK"] = "PUGALISK",
    ["PUGALISK_CORPSE"] = "PUGALISK_CORPSE",
    ["PUGALISK_RUINS_PILLAR"] = "PUGALISK_RUINS_PILLAR",
    ["PUGALISK_SKULL"] = "PUGALISK_SKULL",
    ["PUGALISK_TRAP_DOOR"] = "PUGALISK_TRAP_DOOR",
    ["BONESTAFF"] = "BONESTAFF",
    ["SNAKE_BONE"] = "SNAKE_BONE",
    ["SNAKEBONESOUP"] = "SNAKEBONESOUP",
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
