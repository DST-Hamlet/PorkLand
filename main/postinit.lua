local modimport = modimport
GLOBAL.setfenv(1, GLOBAL)

-- Update this list when adding files
local behaviour_posts = {
    "chaseandattack",
    "wander",
}

local camera_posts = {
    "followcamera",
}

local component_posts = {
    "actionqueuer",
    "ambientlighting",
    "areaaware",
    "blinkstaff",
    "builder_replica",
    "builder",
    "circler",
    "clock",
    "colourcube",
    "combat",
    "crop",
    "drownable",
    "edible",
    "equippable_replica",
    "equippable",
    "explosive",
    "fishingrod",
    "floater",
    "grogginess",
    "grue",
    "hauntable",
    "health",
    "inventory",
    "inventoryitem_replica",
    "inventoryitem",
    "inventoryitemmoisture",
    "locomotor",
    "lootdropper",
    "moisture",
    "oceancolor",
    "oldager",
    "playeractionpicker",
    "playercontroller",
    "playervision",
    "pollinator",
    "positionalwarp",
    "regrowthmanager",
    "repairable",
    "rider_replica",
    "rider",
    "seasons",
    "shard_clock",
    "shard_seasons",
    "sleeper",
    "strafer",
    "teamleader",
    "waterproofer",
    "wavemanager",
    "wisecracker",
    "witherable",
    "worldstate",
}

local prefab_posts = {
    "boomerang",
    "buff_workeffectiveness",
    "meatrack",
    "orangestaff",
    "player",
    "player_classified",
    "player_common_extensions",
    "pocketdimensioncontainer_defs",
    "torch",
    "woodie",
    "world_network",
    "world",
    "shard_network",
    "statueruins",
    "walls",
    "wormwood",
    "wortox",
}

local multipleprefab_posts = {
    "blowinhurricane",
    "blowinwindgust",
    "firepit",
    "health",
    "notraptrigger",
    "poisonable",
}

local scenario_posts = {
}

local screens_posts = {
    "mapscreen",
    "playerhud",
}

local stategraph_posts = {
    "bird",
    "wilson",
    "wilson_client",
    "wilsonghost",
    "wilsonghost_client",
}

local brain_posts = {
}

local widget_posts = {
    "bloodover",
    "containerwidget",
    "inventorybar",
    "seasonclock",
    "statusdisplay",
    "uianim",
    "uiclock",
    "widget",
}

local module_posts = {
    ["components/map"] = "map",
}

local _require = require
---@param module_name string
function require(module_name, ...)
    local no_loaded = package.loaded[module_name] == nil
    local ret = { _require(module_name, ...) }
    if module_posts[module_name] and no_loaded then -- only load when first
        modimport("postinit/modules/" .. module_posts[module_name])
    end
    return unpack(ret)
end

modimport("postinit/recipe")
modimport("postinit/equipslotutil")
modimport("postinit/stategraph")
modimport("postinit/entityscript")
modimport("postinit/bufferedaction")
modimport("postinit/animstate")
modimport("postinit/stategraphs/commonstates")
modimport("postinit/input")
modimport("postinit/vector3")
modimport("postinit/emittermanager")
modimport("postinit/minimapentity")
modimport("postinit/sim")
modimport("postinit/pathfinder")
modimport("postinit/groundcreep")
modimport("postinit/groundcreepentity")

for _, file_name in ipairs(behaviour_posts) do
    modimport("postinit/behaviours/" .. file_name)
end

for _, file_name in ipairs(camera_posts) do
    modimport("postinit/cameras/" .. file_name)
end

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

for _, file_name in ipairs(screens_posts) do
    modimport("postinit/screens/" .. file_name)
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
