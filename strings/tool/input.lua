ds_path = "M:/SteamLibrary/steamapps/common/dont_starve"  -- don't dont_starve file path, need DLC003

package.path = package.path .. ";../?.lua"
package.path = package.path .. ";".. ds_path .. "/data/scripts" .. "/?.lua"

keys = {  -- copy key = over key
    ["PIG_RUINS_IDOL"] = "PIG_RUINS_IDOL",
}

input_strings = {
    CHARACTERS = {
        WINONA = {
            DESCRIBE = {
                PIG_RUINS_IDOL = "一定有什么办法把上面那部分卸下来。",
            },
        },
        WORTOX = {
            DESCRIBE = {
                PIG_RUINS_IDOL = "上面的小雕像不错啊，我们把它拿走吧。",
            },
        },
        WURT = {
            DESCRIBE = {
                PIG_RUINS_IDOL = "一个猪人像，而不是鱼人。",
            },
        },
        WALTER = {
            DESCRIBE = {
                PIG_RUINS_IDOL = "看看我们发现了什么，沃比！",
            },
        },
        WANDA = {
            DESCRIBE = {
                PIG_RUINS_IDOL = "我还以为会更深...噢，那是另一个。",
            },
        },
    }
}

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
        input_strings,  -- input string
        "zh-CN",  -- input language , use Google Translate
        override = false,
    }
}
