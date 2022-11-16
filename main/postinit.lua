-- Update this list when adding files
local components_post = {
    "actionqueuer",
    "combat",
    "health",
    "playercontroller",
    "regrowthmanager",
    "rider_replica",
}

local prefabs_post = {
    "buff_workeffectiveness",
    "player_classified",
    "world"
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

for _, file_name in pairs(components_post) do
    modimport("postinit/components/" .. file_name)
end

for _, file_name in pairs(prefabs_post) do
    modimport("postinit/prefabs/" .. file_name)
end

for _, file_name in pairs(batch_prefabs_post) do
    modimport("postinit/batchprefabs/" .. file_name)
end

for _, file_name in pairs(scenarios_post) do
    modimport("postinit/scenarios/" .. file_name)
end

for _, file_name in pairs(stategraphs_post) do
    modimport("postinit/stategraphs/SG" .. file_name)
end

for _, file_name in pairs(brains_post) do
    modimport("postinit/brains/" .. file_name)
end

for _, file_name in pairs(class_post) do
    modimport("postinit/"  ..  file_name)
end
