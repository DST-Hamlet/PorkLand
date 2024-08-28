ds_path = "D:/Program Files/Steam/steamapps/common/dont_starve"  -- don't dont_starve file path, need DLC003

local dst_string_path = "E:/my/game/Dont starve/Porklandstring"

package.path = package.path .. ";../?.lua"
package.path = package.path .. ";".. dst_string_path .. "/?.lua"
package.path = package.path .. ";".. ds_path .. "/data/scripts" .. "/?.lua"

keys = {  -- copy key = over key
["ANTNAMES"] = "ANTNAMES",
["ANTWARRIORNAMES"] = "ANTWARRIORNAMES",

["SAND"] = "SAND",
["NOOXYGEN"] = "NOOXYGEN",

["ANTQUEEN_CHAMBERS"] = "ANTQUEEN_CHAMBERS",
["ANTMAN_WARRIOR_EGG"] = "ANTMAN_WARRIOR_EGG",
["ANTHILL"] = "ANTHILL",

["ANT_TALK_UNTRANSLATED"] = "ANT_TALK_UNTRANSLATED",
["ANT_TALK_KEEP_AWAY"] = "ANT_TALK_KEEP_AWAY",
["ANT_TALK_WANT_MEAT"] = "ANT_TALK_WANT_MEAT",
["ANT_TALK_WANT_VEGGIE"] = "ANT_TALK_WANT_VEGGIE",
["ANT_TALK_WANT_SEEDS"] = "ANT_TALK_WANT_SEEDS",
["ANT_TALK_WANT_WOOD"] = "ANT_TALK_WANT_WOOD",

["ANT_TALK_FOLLOWWILSON"] = "ANT_TALK_FOLLOWWILSON",
["ANT_TALK_FIGHT"] = "ANT_TALK_FIGHT",
["ANT_TALK_HELP_CHOP_WOOD"] = "ANT_TALK_HELP_CHOP_WOOD",
["ANT_TALK_ATTEMPT_TRADE"] = "ANT_TALK_ATTEMPT_TRADE",
["ANT_TALK_PANIC"] = "ANT_TALK_PANIC",
["ANT_TALK_PANICFIRE"] = "ANT_TALK_PANICFIRE",
["ANT_TALK_FIND_MEAT"] = "ANT_TALK_FIND_MEAT",
["ANT_TALK_RESCUE"] = "ANT_TALK_RESCUE",
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
