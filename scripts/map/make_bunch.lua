local SpawnUtil = require("map/spawnutil")

local bunch_blockers = {
    "porkland_intro_basket",
    "porkland_intro_balloon",
    "porkland_intro_trunk",
    "porkland_intro_suitcase",
    "porkland_intro_flags",
    "porkland_intro_sandbag",
    "porkland_intro_scrape",
}

local function set_entity(entities, prop, x, z)
    if entities[prop] == nil then
        entities[prop] = {}
    end
    local save_data = {x = x , z = z}
    table.insert(entities[prop], save_data)
end

local function export_spawners_to_entites(entities, bunch)
    for _, item in ipairs(bunch) do
        set_entity(entities, item.prefab, item.x, item.z)
    end
end

local function check_valid_ground(x, z, width, height, valid_tile_types, water)
    -- 0.25 was added here because maybe the point thigns are measured from is 1 game unit off? Seems to work?
    x = (width / 2) + 0.5 + (x / TILE_SCALE)
    z = (height / 2) + 0.5 + (z / TILE_SCALE)
    -- print("PROCESSED", math.floor(x), math.floor(z))

    local original_tile_type = WorldSim:GetTile(math.floor(x), math.floor(z))
    if original_tile_type then
        if not water and (IsOceanTile(original_tile_type) or SpawnUtil.IsCloseToWaterTile(x, z, 1)) then
            return false
        end

        if valid_tile_types then
            for _, tiletype in ipairs(valid_tile_types) do
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

local function add_temp_ents(data, x, z, prefab)
    local entity = {x = x, z = z, prefab = prefab}
    table.insert(data, entity)

    return data
end

local function find_ents_in_range(bunch, x, z, range)
    local ents = {}

    local dist = range * range

    for _, item in ipairs(bunch) do
        local xdif = math.abs(x - item.x)
        local zdif = math.abs(z - item.z)
        if (xdif * xdif) + (zdif * zdif) < dist then
            table.insert(ents, item)
        end
    end

    return ents
end

local function check_blocking_items(entities, x, z, range)
    local can_spawn = true

    for _, prefab in ipairs(bunch_blockers) do
        local dist = 4 * 4
        if entities[prefab] then
            for t, ent in ipairs(entities[prefab]) do
                local x_dif = math.abs(x - ent.x)
                local z_dif = math.abs(z - ent.z)
                if (x_dif * x_dif) + (z_dif * z_dif) < dist then
                    can_spawn = false
                end
            end
        else
            print(">>> BUNCH SPAWN ERROR?", prefab)
        end
    end
    return can_spawn
end

local function round(x)
    x = x * 10
    local num = x >= 0 and math.floor(x + 0.5) or math.ceil(x - 0.5)
    return num / 10
end

local function place_item_offgrids(entities, width, height, bunch, x1, z1, range, prefab, valid_tile_types, water, min_spacing)
    local offgrid = false
    local inc = 1
    local x, z = nil, nil

    while offgrid == false do
        local max_radius = range
        local rad = math.random() * max_radius
        local x_diff = math.random() * rad
        local z_diff = math.sqrt((rad * rad) - (x_diff * x_diff))

        if math.random() > 0.5 then
            x_diff = -x_diff
        end

        if math.random() > 0.5 then
            z_diff = -z_diff
        end

        x = x1 + x_diff
        z = z1 + z_diff

        local ents = find_ents_in_range(bunch, x, z, range)
        local test = true

        for _, ent in ipairs(ents) do
            if round(x) == round(ent.x) or round(z) == round(ent.z) or (math.abs(round(ent.x - x)) == math.abs(round(ent.z - z)))  then
                test = false
                break
            end
        end

        local closeents = find_ents_in_range(bunch, x,z,min_spacing or 0.5)
        if #closeents > 0 then
            test = false
        end

        offgrid = test
        inc = inc + 1
    end

    if x and z and check_valid_ground(x, z, width, height, valid_tile_types, water) and check_blocking_items(entities, x, z) then
        add_temp_ents(bunch, x, z, prefab)
    end
end

local function make_bunch(entities, topology_save, world_sim, width, height, prefab, range, number, x, z, valid_tile_types, water, min_spacing)
    local bunch = {}

    for i = 1, number do
        place_item_offgrids(entities, width, height, bunch, x, z, range, prefab, valid_tile_types, water, min_spacing)
    end

    export_spawners_to_entites(entities, bunch)
    return entities
end

return make_bunch
