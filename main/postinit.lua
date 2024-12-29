local modimport = modimport
GLOBAL.setfenv(1, GLOBAL)

-- Update this list when adding files
local behaviour_posts = {
    "chaseandattack",
    "runaway",
    "wander",
}

local camera_posts = {
    "followcamera",
}

local component_posts = {
    "actionqueuer",
    "ambientlighting",
    "amphibiouscreature",
    "areaaware",
    "blinkstaff",
    "builder_replica",
    "builder",
    "burnable",
    "circler",
    "clock",
    "colourcube",
    "combat",
    "crop",
    "deployable",
    "dest",
    "drownable",
    "dryer",
    "edible",
    "equippable_replica",
    "equippable",
    "explosive",
    "fishingrod",
    "floater",
    "grogginess",
    "grower",
    "grue",
    "hauntable",
    "health",
    "inventory",
    "inventory_replica",
    "inventoryitem_replica",
    "inventoryitem",
    "inventoryitemmoisture",
    "kramped",
    "lighter",
    "locomotor",
    "lootdropper",
    "maprecorder",
    "moisture",
    "oceancolor",
    "oldager",
    "pickable",
    "playeractionpicker",
    "playercontroller",
    "playervision",
    "pollinator",
    "positionalwarp",
    "regrowthmanager",
    "repairable",
    "resistance",
    "rider_replica",
    "rider",
    "sanity",
    "seasons",
    "shard_clock",
    "shard_seasons",
    "sheltered",
    "skinner",
    "sleeper",
    "spawner",
    "strafer",
    "teamleader",
    "uianim",
    "undertile",
    "waterproofer",
    "wavemanager",
    "wisecracker",
    "witherable",
    "workable",
    "worldstate",
}

local prefab_posts = {
    "batwing",
    "birdcage",
    "boomerang",
    "buff_workeffectiveness",
    "earmuffshat",
    "grass",
    "inventoryitem_classified",
    "mandrake",
    "meatrack",
    "mosquitosack",
    "multiplayer_portal",
    "orangestaff",
    "pigskin",
    "player",
    "player_classified",
    "player_common_extensions",
    "pocketdimensioncontainer_defs",
    "poop",
    "telebase",
    "thunder_close",
    "torch",
    "waterprojectiles",
    "woodie",
    "world_network",
    "world",
    "shard_network",
    "spoiledfood",
    "statueruins",
    "shadowcreature",
    "walls",
    "waterballoon",
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
    "seeds",
    "stalagmite",
    "tradable",
    "visualvariant",
}

local scenario_posts = {
}

local screens_posts = {
    "mapscreen",
    "playerhud",
    "worldgenscreen",
}

local stategraph_posts = {
    "bird",
    "multiplayerportal",
    "shadowcreature",
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
    "craftingmenu_ingredients",
    "craftingmenu_widget",
    "grid",
    "inventorybar",
    "healthbadge",
    "seasonclock",
    "skilltreetoast",
    "statusdisplay",
    "uiclock",
    "widget",
    "mapwidget",
    "recipepopup",
    "itemtile",
}

local module_posts = {
    ["components/map"] = "map",
    ["shadeeffects"] = "shadeeffects",
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
modimport("postinit/minimapentity")
modimport("postinit/entityscript")
modimport("postinit/bufferedaction")
modimport("postinit/animstate")
modimport("postinit/stategraphs/commonstates")
modimport("postinit/input")
modimport("postinit/vector3")
modimport("postinit/emittermanager")
modimport("postinit/sim")
modimport("postinit/pathfinder")
modimport("postinit/groundcreep")
modimport("postinit/groundcreepentity")
modimport("postinit/soundemitter")
modimport("postinit/preparedfoods")
modimport("postinit/skilltrees")
modimport("postinit/lightwatcher")

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
