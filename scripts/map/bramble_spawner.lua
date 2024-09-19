require "prefabutil"
require "maputil"

local entities = {} -- the list of entities that will fill the whole world. imported from  world gen (forest_map)

local WIDTH = 0
local HEIGHT = 0

local function SetConstants(setentities, setwidth, setheight)
    entities = setentities

    WIDTH = setwidth
    HEIGHT = setheight
end

local function SetEntity(prop, x, z)
    if entities[prop] == nil then
        entities[prop] = {}
    end

    local scenario = nil

    local save_data = {x = (x - WIDTH / 2) * TILE_SCALE , z = (z - HEIGHT / 2) * TILE_SCALE, scenario = scenario}
    table.insert(entities[prop], save_data)
end

local function MakeBrambleSites(new_entities, topology_save, map_width, map_height)
    SetConstants(new_entities, map_width, map_height)

    if topology_save.GlobalTags["Bramble"] then
        for task, nodes in pairs(topology_save.GlobalTags["Bramble"]) do
            for i, node in ipairs(nodes) do
                local c_x, c_y = WorldSim:GetSiteCentroid(topology_save.GlobalTags["Bramble"][task][i])
                SetEntity("bramblesite", c_x, c_y)
            end
        end
    end
end

return MakeBrambleSites
