local unpack = GLOBAL.unpack
local kleifileexists = GLOBAL.kleifileexists
local package = GLOBAL.package
local IAROOT = MODROOT
local modimport = modimport
local IAENV = env

-- Update this list when adding files
local components_post = {
    "actionqueuer",
    "ambientlighting",
    "clock",
    "colourcube",
    "combat",
    "grogginess",
    "health",
    "inventory",
    "inventoryitem",
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
    "wavemanager",
    "worldstate"
}

local prefabs_post = {
    "buff_workeffectiveness",
    "player",
    "player_classified",
    "woodie",
    "world_network",
    "shard_network",
}

local batch_prefabs_post = {
    "poisonable"
}

local scenarios_post = {
    "playerhud"
}

local stategraphs_post = {
    "wilson",
    "wilson_client"
}

local brains_post = {
}

local widgets = {
    "seasonclock",
    "uiclock"
}

local sim_post = {
    "map",  -- Map is not a proper component, so we edit it here instead.
}

local package_post = {
    -- ["components/map"] = "map",
    ["shadeeffects"] = "shadeeffects",
}

modimport("postinit/entityscript")
modimport("postinit/animstate")

for _, file_name in ipairs(components_post) do
    modimport("postinit/components/" .. file_name)
end

for _, file_name in ipairs(prefabs_post) do
    modimport("postinit/prefabs/" .. file_name)
end

for _, file_name in ipairs(batch_prefabs_post) do
    modimport("postinit/batchprefabs/" .. file_name)
end

for _, file_name in ipairs(scenarios_post) do
    modimport("postinit/scenarios/" .. file_name)
end

for _, file_name in ipairs(stategraphs_post) do
    modimport("postinit/stategraphs/SG" .. file_name)
end

for _, file_name in ipairs(brains_post) do
    modimport("postinit/brains/" .. file_name)
end

for _, file_name in ipairs(widgets) do
    modimport("postinit/widgets/"  ..  file_name)
end

-- AddSimPostInit(function()
--     for _, file_name in pairs(sim_post) do
--         modimport("postinit/sim/" .. file_name)
--     end
-- end)
local _require = GLOBAL.require
function GLOBAL.require(modulename, ...)
    local post_modulename = package_post[modulename] or nil
    local should_load = post_modulename and package.loaded[modulename] == nil and kleifileexists("scripts/"..modulename..".lua") and kleifileexists(IAROOT.."postinit/package/"..post_modulename..".lua")
    local rets = {_require(modulename, ...)}
    if should_load then
        print("loading module post", "scripts/"..modulename, IAROOT.."postinit/package/"..post_modulename)
        modimport("postinit/package/" .. post_modulename)
    end
    return unpack(rets)
end
