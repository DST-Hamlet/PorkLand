local borders = {}
local entities = {}
local WIDTH = 0
local HEIGHT = 0

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

    local save_data = {x = x , z = z}
    table.insert(entities[prop], save_data)
end

local function exportSpawnersToEntites()
    for _, item in ipairs(borders)do
        setEntity(item.prefab, item.x, item.z)
    end
end

local function AddTempEnts(data, x, z, prefab)
    local entity = {x = x, z = z, prefab = prefab}
    table.insert(data, entity)

    return data
end

local function testtile(WorldSim, valid_tile_types, x,y)
    local original_tile_type = WorldSim:GetTile(math.floor(x), math.floor(y))
    -- print("TILE", original_tile_type)

    local valid = false
    for _, testtype in ipairs(valid_tile_types)do
        --  print("testing",testtype)
        if original_tile_type == testtype then
            valid = true
            break
        end
    end
    return valid
end

local function makeborder(entities, topology_save, worldsim, map_width, map_height, prefab, valid_tile_types, chance)
    borders = {}
    setConstants(entities, map_width, map_height)

    for x = -(WIDTH / 2) * TILE_SCALE, (WIDTH / 2) * TILE_SCALE, TILE_SCALE do
        for z = -(HEIGHT / 2) * TILE_SCALE, (HEIGHT / 2) * TILE_SCALE, TILE_SCALE do

            local tilex = math.floor((WIDTH / 2) + 0.5 + (x / TILE_SCALE))
            local tilez = math.floor((HEIGHT / 2) + 0.5 + (z / TILE_SCALE))

            if testtile(worldsim, valid_tile_types, tilex, tilez) then
                local valid = false

                if not testtile(worldsim, valid_tile_types, tilex + 1, tilez) then
                    valid = true
                end
                if not valid and not testtile(worldsim, valid_tile_types, tilex - 1, tilez) then
                    valid = true
                end
                if not valid and not testtile(worldsim, valid_tile_types, tilex, tilez + 1) then
                    valid = true
                end
                if not valid and not testtile(worldsim, valid_tile_types, tilex, tilez - 1) then
                    valid = true
                end

                local totalnear = 0
                for _, ent in ipairs(borders) do
                    local distsq = (math.abs(x - ent.x) * math.abs(x - ent.x)) + (math.abs(z - ent.z) * math.abs(z - ent.z))
                    if distsq < 30 * 30 then
                        totalnear = totalnear + 1
                    end
                end

                if valid and (math.random() < chance or totalnear < 2) and totalnear < 6 then
                    AddTempEnts(borders, x, z, prefab)
                end
            end
        end
    end

    exportSpawnersToEntites()

    return entities
end

return makeborder
