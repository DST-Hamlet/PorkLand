-- Update this list when adding files
local components_post = {
    "actionqueuer",
    "clock",
    "combat",
    "health",
    "lootdropper",
    "playercontroller",
    "regrowthmanager",
    "rider_replica",
    "seasons",
    "shard_clock",
    "shard_seasons",
    "wavemanager",
    "worldstate"
}

local prefabs_post = {
    "buff_workeffectiveness",
    "forest_network",
    "forest",
    "player",
    "player_classified",
    "woodie",
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

local class_post = {
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

for _, file_name in ipairs(class_post) do
    modimport("postinit/"  ..  file_name)
end
