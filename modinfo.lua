---@param en string
---@param zh string
---@return string
local function en_zh(en, zh) -- Other languages don't work
    return (locale == "zh" or locale == "zhr" or locale == "zht") and zh or en
end

name = "porkland"
author = "Jerry"
description = ""

version = "0.0.1"
forumthread = ""
api_version = 10
api_version_dst = 10

priority = -1

dst_compatible = true
client_only_mod = false
all_clients_require_mod = true

icon_atlas = "modicon.xml"
icon = "modicon.tex"

server_filter_tags = { "hamltet", "porkland" }

---@param title_en string
---@param title_zh string
---@return mod_configuration
local function Breaker(title_en, title_zh) -- hover does not work, as this item cannot be hovered
    return { name = en_zh(title_en, title_zh), options = { {description = "", data = false} }, default = false }
end

configuration_options = {
    Breaker("Misc.", "杂项"),
    {
        name = "locale",
        label = en_zh("Translation", "翻译"),
        hover = en_zh("Select a translation to enable it regardless of language packs.", "选择翻译，而不是自动"),
        options =
        {
            {description = "Auto", data = false},
            {description = "English", data = "en"},
            {description = "中文 (简体)", data = "sc"},
        },
        default = false,
    },
}
