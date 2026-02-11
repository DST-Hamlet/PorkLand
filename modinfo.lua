---@param en string
---@param zh string
---@return string
local function en_zh(en, zh) -- Other languages don't work
    return (locale == "zh" or locale == "zhr" or locale == "zht") and zh or en
end

name = "云霄国度-Above the Clouds"
author = "Jerry, Tony, ziwbi, 亚丹, 鲁鲁, 小巫, 每年睡8760小时, 老王"
description = "*本mod仍处于测试阶段*"

version = "1.0.42"
forumthread = ""
api_version = 10
api_version_dst = 10

priority = -1

dst_compatible = true
client_only_mod = false
all_clients_require_mod = true

icon_atlas = "modicon.xml"
icon = "modicon.tex"

server_filter_tags = { "Hamlet", "Porkland", "哈姆雷特", "猪镇" }

folder_name = folder_name or "workshop-"
if not folder_name:find("workshop-") then
    name = name .. "-[" .. folder_name .."]"
end

local function Breaker(title_en, title_zh) -- hover does not work, as this item cannot be hovered
    return { name = en_zh(title_en, title_zh), options = { {description = "", data = false} }, default = false }
end

configuration_options = {
	Breaker("Misc", "杂项"),
    {
        name = "enable_porkland_preset",
        label = en_zh("Force Porkland Preset", "强制使用猪镇预设"),
        hover = en_zh("Force the Porkland worldgen preset when creating a new world.", "创建新世界时强制使用猪镇世界生成预设。"),
        options =
        {
            { description = en_zh("Enabled", "启用"), data = true },
            { description = en_zh("Disabled", "禁用"), data = false },
        },
        default = true,
    }
}
