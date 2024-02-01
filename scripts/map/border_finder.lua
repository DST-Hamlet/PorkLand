local borders = {}
local entities = {}
local width = 0
local height = 0

local function set_constants(set_entities, set_width, set_height)
    entities = set_entities
    width = set_width
    height = set_height
end

local function set_entity(prop, x, z)
    if entities[prop] == nil then
        entities[prop] = {}
    end
    local save_data = {x = x , z = z}
    table.insert(entities[prop], save_data)
end

local function export_spawners_to_entites()
    for _, item in ipairs(borders)do
        set_entity(item.prefab, item.x, item.z)
    end
end

local function add_temp_ents(data, x, z, prefab)
    local entity = {x = x, z = z, prefab = prefab}
    table.insert(data, entity)

    return data
end

local function test_tile(world_sim, valid_tile_types, x,y)
    local original_tile_type = world_sim:GetTile(math.floor(x), math.floor(y))
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

local function make_border(set_entities, topology_save, world_sim, map_width, map_height, prefab, valid_tile_types, chance)
    borders = {}
    set_constants(set_entities, map_width, map_height)

    for x = -(width / 2) * TILE_SCALE, (width / 2) * TILE_SCALE, TILE_SCALE do
        for z = -(height / 2) * TILE_SCALE, (height / 2) * TILE_SCALE, TILE_SCALE do

            local tilex = math.floor((width / 2) + 0.5 + (x / TILE_SCALE))
            local tilez = math.floor((height / 2) + 0.5 + (z / TILE_SCALE))

            if test_tile(world_sim, valid_tile_types, tilex, tilez) then
                local valid = false

                if not test_tile(world_sim, valid_tile_types, tilex + 1, tilez) then
                    valid = true
                end
                if not valid and not test_tile(world_sim, valid_tile_types, tilex - 1, tilez) then
                    valid = true
                end
                if not valid and not test_tile(world_sim, valid_tile_types, tilex, tilez + 1) then
                    valid = true
                end
                if not valid and not test_tile(world_sim, valid_tile_types, tilex, tilez - 1) then
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
                    add_temp_ents(borders, x, z, prefab)
                end
            end
        end
    end

    export_spawners_to_entites()

    return set_entities
end

return make_border
