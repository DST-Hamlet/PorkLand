
require "prefabutil"
require "maputil"

local StaticLayout = require("map/static_layout")

local DIR_STEP = {
    {x=1, z=0},
    {x=0, z=1},
    {x=-1,z=0},
    {x=0, z=-1},
}

local parks = {}
local made_palace = false
local made_cityhall = false
local made_playerhouse = false


local entities = {} -- the list of entities that will fill the whole world. imported from  world gen (forest_map)
-- local world


local spawners = {} -- anything that is added here that needs to be looked at before finally being added to the entites list.


local WIDTH = 0
local HEIGHT = 0

local function setConstants(setentities, setwidth, setheight)
    entities = setentities

    WIDTH = setwidth
    HEIGHT = setheight
end

local function FindTempEnts(data,x,z,range,prefabs)
    local ents = {}

    for i,entity in ipairs(data)do
        local test = false
        if not prefabs then
            test = true
        end
        if prefabs then
            for p,prefab in ipairs(prefabs)do
                if entity.prefab == prefab then
                    test = true
                end
            end
        end
        if test then
            local distsq = (math.abs(x-entity.x)*math.abs(x-entity.x)) + (math.abs(z-entity.z)*math.abs(z-entity.z) )
            if distsq <= range*range then
                table.insert(ents,entity)
            end
        end
    end

    return ents
end

local function AddTempEnts(data,x,z,prefab, city_id)

    local entity = {
        x = x,
        z = z,
        prefab = prefab,
        city = city_id,
    }

    table.insert(data,entity)

    return data
end

local function setEntity(prop, x, z)
    if entities[prop] == nil then
        entities[prop] = {}
    end

    local scenario = nil

    local save_data = {x= (x - WIDTH/2.0)*TILE_SCALE , z= (z - HEIGHT/2.0)*TILE_SCALE, scenario = scenario}
    table.insert(entities[prop], save_data)
end


local function exportSpawnersToEntites()
    for i, spawner in ipairs(spawners)do
        setEntity(spawner.prefab, spawner.x, spawner.z, spawner.city )
    end
end

local function SpawnBrambleSites(jungles)
    local spawn = "city_lamp"
    AddTempEnts(spawners,newpt.x,newpt.z,spawn)
end


local function makeBrambleSites(entities, topology_save, worldsim, map_width, map_height)

    setConstants(entities ,map_width, map_height)

    -- finds if an item is in a list, removes it and returns the item.
    local function isInList(listitem, list, dontremove)
        for i,item in ipairs(list)do
            if item == listitem then
                if not dontremove then
                    table.remove(list,i)
                end
                return item
            end
        end
        return false
    end

    local function inInNestedList(listitem, parentlist)
        for i,items in pairs(parentlist)do
            if isInList(listitem, items, true) then
                return listitem
            end
        end
        return false
    end

    local jungles = {}

    if topology_save.GlobalTags["Bramble"] then
        for task, nodes in pairs(topology_save.GlobalTags["Bramble"]) do

            for i,node in ipairs(nodes)do
                local c_x, c_y = WorldSim:GetSiteCentroid(topology_save.GlobalTags["Bramble"][task][i])
                setEntity("bramblesite", c_x, c_y )
            end
        end
    end

    return entities
end

return makeBrambleSites
