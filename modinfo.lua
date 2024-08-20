---@param en string
---@param zh string
---@return string
local function en_zh(en, zh) -- Other languages don't work
    return (locale == "zh" or locale == "zhr" or locale == "zht") and zh or en
end

name = "Above the Clouds"
author = "Jerry"
description = "WIP"

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

server_filter_tags = { "Hamlet", "Porkland" }

folder_name = folder_name or "workshop-"
if not folder_name:find("workshop-") then
    name = name .. "-[" .. folder_name .."]"
end

local function Breaker(title_en, title_zh) -- hover does not work, as this item cannot be hovered
    return { name = en_zh(title_en, title_zh), options = { {description = "", data = false} }, default = false }
end

configuration_options = {
    -- Breaker("Misc", "杂项"),
}
