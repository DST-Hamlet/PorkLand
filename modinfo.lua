---@param en string
---@param zh string
---@return string
local function en_zh(en, zh) -- Other languages don't work
    return (locale == "zh" or locale == "zhr" or locale == "zht") and zh or en
end

name = "云霄国度-Above the Clouds"
author = "Jerry, Tony, ziwbi, 亚丹, 鲁鲁, 小巫, 每年睡8760小时, 老王"
description = "*本mod仍处于测试阶段*"

version = "1.0.51"
forumthread = ""
api_version = 10
api_version_dst = 10

priority = -1

dst_compatible = true
client_only_mod = false
all_clients_require_mod = true

icon_atlas = "modicon.xml"
icon = "modicon.tex"

server_filter_tags = { "Hamlet", "Porkland", "哈姆雷特", "猪镇", "Above the Clouds", "云霄国度" }

folder_name = folder_name or "workshop-"
if not folder_name:find("workshop-") then
    name = name .. "-[" .. folder_name .."]"
end

local function Breaker(title_en, title_zh) -- hover does not work, as this item cannot be hovered
    return { name = en_zh(title_en, title_zh), options = { {description = "", data = false} }, default = false }
end

configuration_options = {
    Breaker("Classical", "经典体验"),
    {
        name = "classical_pickupsound",
        label = en_zh("Pickup Sound", "拾取音效"),
        hover = en_zh("Disable the special pickup sound when picking up items.", "是否禁用拾取物品时的特殊音效，全部回归默认。"),
        options =
        {
            { description = en_zh("Disable", "禁用特殊音效"), data = false },
            { description = en_zh("Enable", "保留特殊音效"), data = true },
        },
        default = true,
    },
    {
        name = "classical_skilltree",
        label = en_zh("Skilltree", "技能树"),
        hover = en_zh("Disable the skilltree.", "是否禁用所有角色的技能树。"),
        options =
        {
            { description = en_zh("Disable", "禁用技能树"), data = false },
            { description = en_zh("Enable", "保留技能树"), data = true },
        },
        default = true,
    },
    {
        name = "classical_animations",
        label = en_zh("Animations", "动画"),
        hover = en_zh("Use old animations for some characters state.", "部分角色动作使用旧版本动画。"),
        options =
        {
            { description = en_zh("Old Animation", "旧版动画"), data = false },
            { description = en_zh("New Animation", "新版动画"), data = true },
        },
        default = true,
    },
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
