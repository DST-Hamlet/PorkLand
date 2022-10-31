---@diagnostic disable: lowercase-global

name = "ProkLand"
author = "Jerry"
description = ""

version = "0.0.1"
forumthread = ""
api_version = 10

dst_compatible = true
all_clients_require_mod = true
priority = 1


icon_atlas = "modicon.xml"
icon = "modicon.tex"

mod_dependencies = {
    {  -- GEMCORE
        workshop = "workshop-1378549454",
        ["GemCore"] = false,
        ["[API] Gem Core - GitLab Version"] = true,
    },
}

server_filter_tags = {"hamltet", "porkland"}