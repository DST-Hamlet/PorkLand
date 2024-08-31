ds_path = "D:/Program Files/Steam/steamapps/common/dont_starve"  -- don't dont_starve file path, need DLC003

local dst_string_path = "E:/my/game/Dont starve/Porklandstring"

package.path = package.path .. ";../?.lua"
package.path = package.path .. ";".. dst_string_path .. "/?.lua"
package.path = package.path .. ";".. ds_path .. "/data/scripts" .. "/?.lua"

keys = {  -- copy key = over key
["ROC_SETTING"] = "ROC_SETTING",
["ROC_LEG"] = "ROC_LEG",
["ROC_HEAD"] = "ROC_HEAD",
["ROC_TAIL"] = "ROC_TAIL",

["ROC_NEST_TREE1"] = "ROC_NEST_TREE1",
["ROC_NEST_TREE2"] = "ROC_NEST_TREE2",

["ROC_NEST_BUSH"] = "ROC_NEST_BUSH",
["ROC_NEST_BRANCH1"] = "ROC_NEST_BRANCH1",
["ROC_NEST_BRANCH2"] = "ROC_NEST_BRANCH2",

["ROC_NEST_TRUNK"] = "ROC_NEST_TRUNK",
["ROC_NEST_HOUSE"] = "ROC_NEST_HOUSE",

["ROC_NEST_RUSTY_LAMP"] = "ROC_NEST_RUSTY_LAMP",

["ROC_NEST_EGG1"] = "ROC_NEST_EGG1",
["ROC_NEST_EGG2"] = "ROC_NEST_EGG2",
["ROC_NEST_EGG3"] = "ROC_NEST_EGG3",
["ROC_NEST_EGG4"] = "ROC_NEST_EGG4",

["ROC_ROBIN_EGG"] = "ROC_ROBIN_EGG",

["RO_BIN"] = "RO_BIN",
["RO_BIN_GIZZARD_STONE"] = "RO_BIN_GIZZARD_STONE",

["ROC_NEST_DEBRIS1"] = "ROC_NEST_DEBRIS1",
["ROC_NEST_DEBRIS2"] = "ROC_NEST_DEBRIS2",
["ROC_NEST_DEBRIS3"] = "ROC_NEST_DEBRIS3",
["ROC_NEST_DEBRIS4"] = "ROC_NEST_DEBRIS4",

["PIG_SCEPTER"] = "PIG_SCEPTER",
["PIGCROWNHAT"] = "PIGCROWNHAT",

["CAVE_EXIT_ROC"] = "CAVE_EXIT_ROC",
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
