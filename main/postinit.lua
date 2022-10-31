-- Update this list when adding files
local components_post = {
}

local prefabs_post = {
    "world"
}


local scenarios_post = {
}

local stategraphs_post = {
}

local brains_post = {
}

local class_post = {
}

for _,v in pairs(components_post) do
    modimport("postinit/components/"..v)
end

for _,v in pairs(prefabs_post) do
    modimport("postinit/prefabs/"..v)
end

for _,v in pairs(scenarios_post) do
    modimport("postinit/scenarios/"..v)
end

for _,v in pairs(stategraphs_post) do
    modimport("postinit/stategraphs/SG"..v)
end

for _,v in pairs(brains_post) do
    modimport("postinit/brains/"..v)
end

for _,v in pairs(class_post) do
    --These contain a path already, e.g. v= "widgets/inventorybar"
    modimport("postinit/" .. v)
end
