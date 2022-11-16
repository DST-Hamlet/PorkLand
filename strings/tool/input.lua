---@diagnostic disable: lowercase-global

local languages = {
    -- en = "strings.pot",
	de = "german",  -- german
	es = "spanish",  -- spanish
	fr = "french",  -- french
	it = "italian",  -- italian
	ko = "korean",  -- korean
	pt = "portuguese_br",  -- portuguese and brazilian portuguese
	pl = "polish",  -- polish
	ru = "russian",  -- russian
	["zh-CN"] = "chinese_s",  -- chinese
	["zh-TW"] = "chinese_t",  -- traditional chinese
}

ds_path = "F:/STEAM/steamapps/common/dont_starve"  -- don't dont_starve file path, need DLC003
string_key = "peagawk_bush" -- need add string's prefab

new_strings = {
    language = "zh-CN",  -- look languages's key
    CHARACTERS = {
        WINONA = {
            DESCRIBE = {
                PEAGAWK = {
                    GENERIC = "时刻保持警惕啊。",
                    -- DEAD = "A pointless death.",
                    SLEEPING = "它放松了警惕。",  -- 检测孔雀睡着状态
                },

                PEAGAWKFEATHER = "它还在看着我。",  -- 检测孔雀毛
                PEAGAWK_BUSH = "一株会警惕的灌木丛，真是奇怪！",  -- 检测孔雀变成灌木
            },
        },
        WORTOX = {
            DESCRIBE = {
                PEAGAWK = {
                    GENERIC = "你肯定看到过很多吧？",
                    -- DEAD = "A pointless death.",
                    SLEEPING = "哼，咱们闭上眼睛休息会？",
                },

                PEAGAWKFEATHER = "小孔雀的羽毛。",  -- 检测孔雀毛
                PEAGAWK_BUSH = "哼，这点把戏骗不过我。",  -- 检测孔雀变成灌木
            },
        },
        WURT = {
            DESCRIBE = {
                PEAGAWK = {
                    GENERIC = "大怪鸟。",
                    -- DEAD = "A pointless death.",
                    SLEEPING = "大怪鸟睡着了？",
                },

                PEAGAWKFEATHER = "上面有大怪鸟的眼睛。",  -- 检测孔雀毛
                PEAGAWK_BUSH = "漂亮的羽毛灌木。",  -- 检测孔雀变成灌木
            },
        },
        WALTER = {
            DESCRIBE = {
                PEAGAWK = {
                    GENERIC = "哇塞，这有多少只眼睛啊？",
                    -- DEAD = "A pointless death.",
                    SLEEPING = "沃比，我们也许可以在它睡着的时候采集它的羽毛。",
                },

                PEAGAWKFEATHER = "方法是有效的。",  -- 检测孔雀毛
                PEAGAWK_BUSH = "这种鸟不会飞，但是会变成灌木丛！",  -- 检测孔雀变成灌木
            },
        },
        WANDA = {
            DESCRIBE = {
                PEAGAWK = {
                    GENERIC = "非礼勿视！",
                    -- DEAD = "A pointless death.",
                    SLEEPING = "它应该没有在看我了吧？",
                },

                PEAGAWKFEATHER = "真是令人难以直视。",  -- 检测孔雀毛
                PEAGAWK_BUSH = "真是聪明的伪装。",  -- 检测孔雀变成灌木
            },
        },
    }
}

override = false