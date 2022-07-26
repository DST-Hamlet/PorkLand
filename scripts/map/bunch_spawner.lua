
require "prefabutil"
require "maputil"

local StaticLayout = require("map/static_layout")

local bunch = {}
local entities = {}
local WIDTH = 0
local HEIGHT = 0

local BUNCH_BLOCKERS = {
    "porkland_intro_basket",
    "porkland_intro_balloon",
    "porkland_intro_trunk",
    "porkland_intro_suitcase",
    "porkland_intro_flags",
    "porkland_intro_sandbag",
    "porkland_intro_scrape",
}

local function setConstants(setentities, setwidth, setheight)
    entities = setentities
    WIDTH = setwidth
    HEIGHT = setheight
end

local function setEntity(prop, x, z)
    if entities[prop] == nil then
        entities[prop] = {}
    end

    local scenario = nil

    --local save_data = {x= (x - WIDTH/2.0)*TILE_SCALE , z= (z - HEIGHT/2.0)*TILE_SCALE}
    local save_data = {x=x , z= z}
    table.insert(entities[prop], save_data)
end

local function exportSpawnersToEntites()
    for i, item in ipairs(bunch)do
        setEntity(item.prefab, item.x, item.z )
    end
end

local function getdiv1tile(x,y,z)
    local fx,fy,fz = x,y,z

    fx = x - ( math.fmod(x,1) )
    fz = z - ( math.fmod(z,1) )

    return fx,fy,fz
end

local function checkIfValidGround(x,z, valid_tile_types, water)
    -- 0.25 was added here because maybe the point thigns are measured from is 1 game unit off? Seems to work?
    x = (WIDTH/2)+0.5 + (x/TILE_SCALE)
    z = (HEIGHT/2)+0.5 + (z/TILE_SCALE)
    --print("PROCESSED",math.floor(x), math.floor(z))
    local original_tile_type = WorldSim:GetTile(math.floor(x), math.floor(z) )

    if original_tile_type then

        if not water and WorldSim:IsWater(original_tile_type) then
            return false
        end

        if valid_tile_types then
            for i, tiletype in ipairs(valid_tile_types)do
                if original_tile_type == tiletype then
                    return true
                end
            end
            return false
        elseif original_tile_type > 1 then
            return original_tile_type
        end
        return false
    else
        return false
    end
end

local function AddTempEnts(data,x,z,prefab)

    local entity = {
        x = x,
        z = z,
        prefab = prefab,
    }

    table.insert(data,entity)

    return data
end

local function findEntsInRange(x,z,range)
    local ents = {}

    local dist = range*range

    for k, item in ipairs(bunch) do
        local xdif = math.abs(x - item.x)
        local zdif = math.abs(z - item.z)
        if (xdif*xdif) + (zdif*zdif) < dist then
            table.insert(ents,item)
        end
    end

    return ents
end

local function checkforblockingitems(x,z,range)
    local spawnOK = true

    for i, prefab in ipairs(BUNCH_BLOCKERS) do
        local dist = 4*4
        if entities[prefab] then
            for t, ent in ipairs( entities[prefab] ) do
                local xdif = math.abs(x - ent.x)
                local zdif = math.abs(z - ent.z)
                if (xdif*xdif) + (zdif*zdif) < dist then
                    spawnOK = false
                end
            end
        else
            print(">>> BUNCH SPAWN ERROR?",prefab)
        end
    end
    return spawnOK
end


local function round(x)
  x = x *10
  local num = x>=0 and math.floor(x+0.5) or math.ceil(x-0.5)
  return num/10
end

local function placeitemoffgrids(x1,z1, range, prefab, valid_tile_types, water)

    local offgrid = false
    local inc = 1
    local x,z = nil,nil
    while offgrid == false do

        local radiusMax = range
        local rad = math.random()*radiusMax
        local xdiff = math.random()*rad
        local zdiff = math.sqrt( (rad*rad) - (xdiff*xdiff))

        if math.random() > 0.5 then
            xdiff= -xdiff
        end

        if math.random() > 0.5 then
            zdiff= -zdiff
        end
        x = x1+ xdiff
        z = z1+ zdiff

        local ents = findEntsInRange(x,z,range)
        local test = true
        for i,ent in ipairs(ents) do

            if round(x) == round(ent.x) or round(z) == round(ent.z) or ( math.abs(round(ent.x-x)) == math.abs(round(ent.z-z)) )  then
                test = false
                break
            end
        end

        offgrid = test
        inc = inc +1
    end
    if x and z and checkIfValidGround(x,z, valid_tile_types, water) and checkforblockingitems(x,z) then
        AddTempEnts(bunch,x,z,prefab)
    end

end

local function makebunch(entities, topology_save, worldsim, map_width, map_height, prefab, range, number, x,z, valid_tile_types, water)
    bunch = {}
    setConstants(entities, map_width, map_height)

    for i=1,number do
        placeitemoffgrids(x,z, range, prefab, valid_tile_types, water)
    end

    exportSpawnersToEntites()
    return entities
end

return makebunch