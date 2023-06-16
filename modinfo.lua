local function en_zh(en, zh)  -- Other languages don't work
    return (locale == "zh" or locale == "zhr" or locale == "zht") and zh or en
end

name = "Pork Land"
author = "Jerry"
description = ""

version = "0.0.1"
forumthread = ""
api_version = 10
api_version_dst = 10

dst_compatible = true
client_only_mod = false
all_clients_require_mod = true
priority = -1

icon_atlas = "modicon.xml"
icon = "modicon.tex"

server_filter_tags = {"hamltet", "porkland"}

mod_dependencies = {
    {--GEMCORE
        workshop = "workshop-1378549454",
        ["GemCore"] = false,
        ["[API] Gem Core - GitLab Version"] = true,
    },
}

local function Breaker(title_en, title_zh)  --hover does not work, as this item cannot be hovered
    return {name = en_zh(title_en, title_zh) , options = {{description = "", data = false}}, default = false}
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
            {description = "Deutsch", data = "de"},
            {description = "Español", data = "es"},
            {description = "Français", data = "fr"},
            {description = "Italiano", data = "it"},
            {description = "한국어", data = "ko"},
            {description = "Polski", data = "pl"},
            {description = "Português", data = "pt"},
            {description = "Русский", data = "ru"},
            {description = "中文 (简体)", data = "sc"},
            {description = "中文 (繁体)", data = "tc"},
        },
        default = false,
    }
}
