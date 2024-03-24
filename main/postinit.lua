local modimport = modimport
GLOBAL.setfenv(1, GLOBAL)

-- Update this list when adding files
local component_posts = {
    "actionqueuer",
    "ambientlighting",
    "clock",
    "colourcube",
    "combat",
    "edible",
    "floater",
    "grogginess",
    "health",
    "inventory",
    "inventoryitem",
    "locomotor",
    "lootdropper",
    "moisture",
    "playercontroller",
    "pollinator",
    "regrowthmanager",
    "rider_replica",
    "seasons",
    "shard_clock",
    "shard_seasons",
    "sleeper",
    "waterproofer",
    "wavemanager",
    "worldstate",
}

local prefab_posts = {
    "buff_workeffectiveness",
    "player",
    "player_classified",
    "woodie",
    "world_network",
    "shard_network",
    "wormwood",
}

local multipleprefab_posts = {
    "poisonable",
}

local scenario_posts = {
    "playerhud",
}

local stategraph_posts = {
    "wilson",
    "wilson_client",
}

local brain_posts = {
}

local widget_posts = {
    "seasonclock",
    "uiclock"
}

local module_posts = {
    ["components/map"] = "map",
}

local _require = require
---@param module_name string
function require(module_name, ...)
    local ret = { _require(module_name, ...) }
    if module_posts[module_name] and package.loaded[module_name] == nil then -- only load when first
        modimport("postinit/modules/" .. module_posts[module_name])
    end
    return unpack(ret)
end

modimport("postinit/entityscript")
modimport("postinit/animstate")
modimport("postinit/input")

for _, file_name in ipairs(component_posts) do
    modimport("postinit/components/" .. file_name)
end

for _, file_name in ipairs(prefab_posts) do
    modimport("postinit/prefabs/" .. file_name)
end

for _, file_name in ipairs(multipleprefab_posts) do
    modimport("postinit/multipleprefabs/" .. file_name)
end

for _, file_name in ipairs(scenario_posts) do
    modimport("postinit/scenarios/" .. file_name)
end

for _, file_name in ipairs(stategraph_posts) do
    modimport("postinit/stategraphs/SG" .. file_name)
end

for _, file_name in ipairs(brain_posts) do
    modimport("postinit/brains/" .. file_name)
end

for _, file_name in ipairs(widget_posts) do
    modimport("postinit/widgets/" .. file_name)
end
