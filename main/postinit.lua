-- Update this list when adding files
local components_post = {
    "regrowthmanager",
    "actionqueuer",
    "rider_replica",
    "playercontroller"
}

local prefabs_post = {
    "buff_workeffectiveness",
    "world"
}


local scenarios_post = {
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
