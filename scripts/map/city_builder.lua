local obj_layout = require("map/object_layout")

local DIR_STEP = {
    {x = 1, z = 0},
    {x = 0, z = 1},
    {x = -1, z = 0},
    {x = 0, z = -1},
}

local made_palace = false
local made_cityhall = false
local made_playerhouse = false

local CITIES = 2

local PARK_CHOICES = {
    "city_park_1",
    "city_park_2",
    "city_park_3",
    "city_park_4",
    "city_park_5",
    "city_park_8",
}

local UNIQUE_PARK_CHOICES = {
    "city_park_6",
    "city_park_7",
    "city_park_9",
    "city_park_10",
}

local REQUIRED_FARMS = {
    "teleportato_hamlet_potato_layout",
}

local FARM_CHOICES = {
    "farm_1",
    "farm_2",
    "farm_3",
    "farm_4",
    "farm_5",
}

local FARM_FILLER_CHOICES = {
    "farm_fill_1",
    "farm_fill_2",
    "farm_fill_3",
}

local BUILDING_QUOTAS = {
    {prefab = "pig_shop_deli", num = 1},
    {prefab = "pig_shop_academy", num = 1},
    {prefab = "pig_shop_florist", num = 1},
    {prefab = "pig_shop_general", num = 1},
    {prefab = "pig_shop_hoofspa", num = 1},
    {prefab = "pig_shop_produce", num = 1},
    {prefab = "pig_shop_bank", num = 1},
    {prefab = "pig_guard_tower", num = 15},
    {prefab = "pighouse_city", num = 50}
}

local BUILDING_QUOTAS_2 = {
    {prefab="pig_shop_antiquities", num = 1},
    {prefab="pig_shop_hatshop", num = 1},
    {prefab="pig_shop_weapons", num = 1},
    {prefab="pig_shop_arcane", num = 1},
    {prefab="pig_shop_tinker", num = 1},
    {prefab="pig_guard_tower", num = 15},
    {prefab="pighouse_city", num = 50}
}

local VALID_TILES = {WORLD_TILES.SUBURB, WORLD_TILES.FOUNDATION}

local function opp_dir(dir)
    if dir == 1 then
        return 3
    elseif dir == 2 then
        return 4
    elseif dir == 3 then
        return 1
    elseif dir == 4 then
        return 2
    end
end

local function get_dir(dir, inc)
    if dir == 1 then
        return inc > 0 and 2 or 4
    elseif dir == 2 then
        return inc > 0 and 3 or 1
    elseif dir == 3 then
        return inc > 0 and 4 or 2
    elseif dir == 4 then
        return inc > 0 and 1 or 3
    end
end

local function find_temp_ents(data, x, z, range, prefabs)
    local ents = {}

    for i, entity in ipairs(data)do
        local test = prefabs == nil
        if not test then
            for p, prefab in ipairs(prefabs)do
                if entity.prefab == prefab then
                    test = true
                end
            end
        end
        if test then
            local distsq = (math.abs(x - entity.x) * math.abs(x - entity.x)) + (math.abs(z - entity.z) * math.abs(z - entity.z))
            if distsq <= range * range then
                table.insert(ents, entity)
            end
        end
    end

    return ents
end

local function add_temp_ents(data, x, z, prefab, city_id, properties)
    local save_data = {
        x = x,
        z = z,
        prefab = prefab,
        city = city_id,
        properties = properties,
    }

    table.insert(data, save_data)
end

local function set_entity(entities, width, height, prop, x, z, city_id, properties)
    if entities[prop] == nil then
        entities[prop] = {}
    end

    local scenario = nil
    if city_id then
        scenario = "set_city_possession_" .. city_id
    end

    local save_data = properties or {}
    save_data.x = (x - width / 2.0) * TILE_SCALE
    save_data.z = (z - height / 2.0) * TILE_SCALE
    save_data.scenario = scenario

    table.insert(entities[prop], save_data)
end

local function find_entities(entities, x, z, range, props)
    local ents = {}

    for p, prop in ipairs(props) do
        for i, testent in ipairs(entities[prop]) do
            local xdist = math.abs(testent.x - x)
            local zdist = math.abs(testent.z - z)
            if (xdist * xdist) + (zdist * zdist) < range * range then
                table.insert(ents, {
                    prop = prop,
                    x = testent.x,
                    y = testent.z
                })
            end
        end
    end

    return ents
end

local function export_spawners_to_entites(entities, width, height, spawners)
    for i, spawner in ipairs(spawners)do
        set_entity(entities, width, height, spawner.prefab, spawner.x, spawner.z, spawner.city, spawner.properties)
    end
end

local function test_tile(pt, types)
    local ground = WorldSim:GetTile(pt.x, pt.z) -- pt is in TILE SPACE

    local test = true

    local original_tile_types = {}
    if ground then
        for x = -1, 1 do
            for z = -1, 1 do
                table.insert(original_tile_types, WorldSim:GetTile(pt.x + x, pt.z + z))
            end
        end
    end

    for i, original_tile_type in ipairs(original_tile_types) do
        if original_tile_type then
            if original_tile_type < 2 then
                test = false
                break
            else
                -- 5 is the centre tile
                if i == 5 and types then
                    local check = false
                    for p, tiletype in ipairs(types) do
                        if tiletype == original_tile_type then
                            check = true
                            break
                        end
                    end
                    if check == false then
                        test = false
                    end
                end
            end
        end
    end

    return test
end

local function place_tile(pt, tile)
    local ground = WorldSim:GetTile(pt.x, pt.z) -- pt is in TILE SPACE

    if ground then
        if not tile then
            tile =  WORLD_TILES.COBBLEROAD
        end
        WorldSim:SetTile(pt.x, pt.z, tile)
        -- maybe do a reseve tile thing here?
    end
end

local function clear_ground(entities, width, height, pt)
    local radius = 6
    for prefab, data_list in pairs(entities) do
        local reserved = false
        for i, rprefab in ipairs(PORKLAND_REQUIRED_PREFABS) do
            if prefab == rprefab then
                reserved = true
                break
            end
        end

        if not reserved then
            for i = #data_list, 1, -1 do
                local x_dist = math.abs(((data_list[i].x / TILE_SCALE) + width / 2.0) - pt.x) + 0.2
                local z_dist = math.abs(((data_list[i].z / TILE_SCALE) + height / 2.0) - pt.z) + 0.2

                if (x_dist * x_dist) + (z_dist * z_dist) <= radius * radius then
                    table.remove(data_list, i)
                end
            end
        end
    end
end

local function place_tile_city(entities, width, height, pt)
    clear_ground(entities, width, height, pt)

    place_tile(pt)
    for i = -6, 6 do
        for t = -6, 6 do
            local new_pt = {
                x = pt.x + i,
                z = pt.z + t
            }
            -- print("TESTING THE TILE TYPE", WorldSim:GetTile(newpt.x, newpt.z))
            if WorldSim:GetTile(new_pt.x, new_pt.z) > 1 then
                if math.random() < 0.15 or (t < math.abs(4) and i < math.abs(4)) then
                    if test_tile(new_pt, VALID_TILES) then
                        place_tile(new_pt, WORLD_TILES.FOUNDATION)
                    end
                end
            end
        end
    end
end

local function spawn_setpiece(entities, width, height, spawners, layout, pt, city)
    if layout == "pig_palace_1" then
        print("SPAWNING A PALACE THROUGH THE CITY BUILDER")
    end

    local setpiece = obj_layout.LayoutForDefinition(layout)
    -- THESE SET PIECES NEED AN ODD NUMBER OF TILES BOTH COL AND ROW,
    -- because they are centered on a single tile.. to be even, it would need code to select the tile that gets placed at the center
    assert(#setpiece.ground % 2 ~= 0, "ERROR, THE SET PIECE HAS AN EVEN NUMBER OF ROWS")
    assert(#setpiece.ground[1] % 2 ~= 0, "ERROR, THE SET PIECE HAS AN EVEN NUMBER OF COLS")

    local reverse = math.random() < 0.5 -- flips the x and y axis
    local flip = math.random() < 0.5 -- reverses the direction along the x axis.

    local offset_x = ((#setpiece.ground - 1) / 2 + 1)
    local offset_z = ((#setpiece.ground[1] - 1) / 2 + 1)

    local x_flip = 1

    if flip then
        offset_x = offset_x * -1
        x_flip = -1
    end

    local radius = math.max(#setpiece.ground, #setpiece.ground[1]) / 2 * 1.4

    for prefab, data_list in pairs(entities) do
        for i = #data_list, 1, -1 do
            local xdist = math.abs(((data_list[i].x / TILE_SCALE) + width / 2.0) - pt.x) + 0.2
            local zdist = math.abs(((data_list[i].z / TILE_SCALE) + height / 2.0) - pt.z) + 0.2

            if (xdist * xdist) + (zdist * zdist) <= radius * radius then
                table.remove(data_list, i)
            end
        end
    end

    local ground_valid = true
    for x = 1, #setpiece.ground do
        for y = 1, #setpiece.ground[x] do
            local new_pt = {}
            local step = x
            if flip then
                step = step * -1
            end
            if reverse then
                new_pt = {
                    x = (pt.x - offset_x + (x * x_flip)),
                    y = 0,
                    z = (pt.z - offset_z + (y))
                }
            else
                new_pt = {
                    x = (pt.x - offset_x + (y * x_flip)),
                    y = 0,
                    z = (pt.z - offset_z + (x))
                }
            end
            local original_tile_type = WorldSim:GetTile(math.floor(new_pt.x), math.floor(new_pt.z))
            if not original_tile_type or original_tile_type <= 1 then
                ground_valid = false
            end
        end
    end
    if ground_valid then
        for x = 1, #setpiece.ground do
            for y = 1, #setpiece.ground[x] do
                local new_pt = {}
                if reverse then
                    new_pt = {
                        x = (pt.x - offset_x + (x * x_flip)),
                        y = 0,
                        z = (pt.z - offset_z + (y))
                    }
                else
                    new_pt = {
                        x = (pt.x - offset_x + (y * x_flip)),
                        y = 0,
                        z = (pt.z - offset_z + (x))
                    }
                end
                local tile = setpiece.ground_types[setpiece.ground[x][y]]

                if tile and tile > 0 then
                    place_tile(new_pt, tile)
                end
            end
        end

        for prefab, list in pairs(setpiece.layout) do
            for t, data in ipairs(list)do
                -- local spawnprop = SpawnPrefab(prop)

                local new_pt = {}
                if reverse then
                    new_pt = {
                        x = (pt.x + (list[t].y * x_flip)),
                        y = 0,
                        z = (pt.z + (list[t].x)),
                    }
                else
                    new_pt = {
                        x = (pt.x + (list[t].x * x_flip)),
                        y = 0,
                        z = (pt.z + (list[t].y)),
                    }
                end

                local city_temp = city.city_id
                if layout == "city_park_7" and prefab == "oinc" then
                    city_temp = nil
                end
                if layout == "pig_playerhouse_1" and prefab ~= "playerhouse_city" then
                    city_temp = nil
                end

                add_temp_ents(spawners, new_pt.x, new_pt.z, prefab, city_temp, data.properties)
            end
        end
        return true
    else
        print("!!!!!! WORLD_TILES WAS NOT VALID !!!!!!!!!!!!")
        return false
    end
end

local function set_shop(spawners, pt, dir, i, offset, nil_wieght, city)
    local spawn = "pig_shop_spawner"
    local OFFSET = 6 / 4
    local new_pt = {
        x = pt.x + (DIR_STEP[dir].x * i * OFFSET) + (OFFSET * DIR_STEP[get_dir(dir, offset)].x),
        y = 0,
        z = pt.z + (DIR_STEP[dir].z * i * OFFSET) + (OFFSET * DIR_STEP[get_dir(dir, offset)].z)
    }

    local pigshops_spawners = find_temp_ents(spawners, new_pt.x, new_pt.z, 1, {spawn})

    -- local ground = WorldSim:GetTile(math.floor(new_pt.x), math.floor(new_pt.z))

    if #pigshops_spawners == 0 and IsLandTile(WorldSim:GetTile(math.floor(new_pt.x), math.floor(new_pt.z))) then
        add_temp_ents(spawners, new_pt.x, new_pt.z, spawn, city.city_id)
    end
end

local function add_pig_shops(spawners, pt, dir, nil_wieght, city) -- pig shops and parks..
    for i = 1, 3 do
        set_shop(spawners, pt, dir, i, 1, nil_wieght, city)
        set_shop(spawners, pt, dir, i, -1, nil_wieght, city)
    end
end

local function set_park_coord(pt, dir, i, offset, city)
    local OFFSET = 6 / 4

    local new_pt = {
        x = pt.x + (DIR_STEP[dir].x * i * OFFSET) + (OFFSET * DIR_STEP[get_dir(dir, offset)].x * math.abs(offset)),
        y = 0,
        z = pt.z + (DIR_STEP[dir].z * i * OFFSET) + (OFFSET * DIR_STEP[get_dir(dir, offset)].z * math.abs(offset))
    }

    -- make sure all 25 tiles are free.
    local pass = true

    for x = -2, 2 do
        for y = -2, 2 do
            local ground = WorldSim:GetTile(math.floor(new_pt.x) + (x), math.floor(new_pt.z) + (y))
            if not ground or ground ~= WORLD_TILES.FOUNDATION then
                pass = false
                break
            end
        end
    end

    if pass then
        local pass = true
        for i, park in ipairs(city.parks) do
            if new_pt.x == park.x and new_pt.z == park.z then
                pass = false
                break
            end
        end
        if pass then
            new_pt.city_id = city.city_id
            table.insert(city.parks, new_pt)
        end
    end
end

local function add_park_zones(pt, dir, city) -- pig shops and parks..
    local i = 2
    set_park_coord(pt, dir, i, 2, city)
    set_park_coord(pt, dir, i, -2, city)
end

local function spawn_city_light(spawners, pt, dir, offset, city_id)
    local spawn = "city_lamp"
    local OFFSET = 5 / 8
    local newpt = {
        x = pt.x + (DIR_STEP[dir].x * OFFSET) + (OFFSET * DIR_STEP[get_dir(dir, offset)].x),
        y = 0,
        z = pt.z + (DIR_STEP[dir].z * OFFSET) + (OFFSET * DIR_STEP[get_dir(dir, offset)].z)
    }

    local lamps = find_temp_ents(spawners, newpt.x, newpt.z, 0.5, {spawn})

    if #lamps == 0 then
        local ground = WorldSim:GetTile(math.floor(newpt.x), math.floor(newpt.z))
        if ground then
            add_temp_ents(spawners, newpt.x, newpt.z, spawn, city_id)
        end
    end
end

local function add_city_lights(spawners, pt, dir, city_id)
    spawn_city_light(spawners, pt, dir, 1, city_id)
    spawn_city_light(spawners, pt, dir, -1, city_id)
end

local function make_road(entities, width, height, spawners, pt, dir, sub_urb, city)
    local step_max = 7
    local step = 1
    local new_pt =  nil
    local offset = 1  -- 4

    local two_way_chance = 0.8
    local bend_chance = 0.4
    local not_t_int_chance = 0.3
    local nil_pig_shop_weight = 6

    if sub_urb then
        two_way_chance = 0.8
        bend_chance = 0.2
        not_t_int_chance = 0.6
        nil_pig_shop_weight = 12
    end

    while step < step_max and step > -1 do
        new_pt = {
            x = pt.x + (DIR_STEP[dir].x * step * offset),
            y = 0,
            z = pt.z + (DIR_STEP[dir].z * step * offset)
        }

        if test_tile(new_pt, VALID_TILES) then
            place_tile_city(entities, width, height, new_pt)
            -- placeTile(newpt)
            step = step + 1
        else
            step = -1
        end
    end

    if step == step_max then
        -- has reached a new intersection
        local dir_set = {false, false, false, false}

        if math.random() < two_way_chance then
            -- just a 2 way
            if math.random() < bend_chance then
                local inc = math.random() < 0.5 and -1 or 1
                dir_set[get_dir(dir, inc)] = true
            else
                -- go strait
                dir_set[dir] = true
            end
        else
            -- a 3 way
            dir_set = {true, true, true, true}
            dir_set[opp_dir(dir)] = false

            if math.random() < not_t_int_chance then
                -- include strait
                local inc = math.random() < 0.5 and -1 or 1
                dir_set[get_dir(dir,inc)] = false
            else
                -- T branch
                dir_set[dir] = false
            end
        end
        add_pig_shops(spawners, pt, dir, nil_pig_shop_weight, city)
        add_park_zones(pt, dir, city)
        add_city_lights(spawners, pt, dir, city.city_id)
    end
end

local function get_div1_tile(x, y, z)
    x = x - (math.fmod(x, 1))
    z = z - (math.fmod(z, 1))

    return x, y, z
end

local function get_div6_tile(x, y, z)
    x = x - (math.fmod(x, 6))
    z = z - (math.fmod(z, 6))
    return x, y, z
end

local function is_pt_in_list(pt, data)
    local idx = nil
    for i,coord in ipairs(data)do
        if coord.x == pt.x and coord.y == pt.y and coord.z == pt.z then
            idx = i
            break
        end
    end
    return idx
end

local function add_dirs(pt, grid, open_dirs)
    for dir,data in ipairs(DIR_STEP) do
        local new_pt = {
            x = pt.x + (data.x * 6),
            y = pt.y,
            z = pt.z + (data.z * 6)
        }

        local idx = is_pt_in_list(new_pt, grid)
        if idx then
            table.insert(open_dirs, {pt = pt, newpt = new_pt, dir = dir})
            table.remove(grid, idx)
        else
            if math.random() < 0.3 then
                table.insert(open_dirs, {pt = pt, dir = dir})
            end
        end
    end
    return grid, open_dirs
end


local function create_city(entities, width, height, spawners, city)
    local start_node = nil

    -- this requires that at least one of the city nodes's center is not outside the land.
    while not start_node do
        local idx = math.random(1, #city.citynodes)
        start_node = city.citynodes[idx]
        local x, z = start_node.cent[1], start_node.cent[2]
        local y = 0
        x, y, z = get_div6_tile(x, 0, z)
        local testpt = {
            x = x,
            y = y,
            z = z
        }
        if not test_tile(testpt, VALID_TILES) then
            start_node = nil
        end
    end


    -- this is to catch if every node center was outside the land
    if not start_node then
        local new_node_list = deepcopy(city.citynodes)
        while not start_node do
            local idx = math.random(1, #new_node_list)
            start_node = new_node_list[idx]
            local ok = false

            for i = 1, #start_node.poly.x, 1 do
                local x, z = start_node.poly.x[i], start_node.poly.y[i]
                local y = 0

                x, y, z = get_div6_tile(x, 0, z)

                local testpt = {
                    x = x,
                    y = y,
                    z = z
                }
                if test_tile(testpt, VALID_TILES) then
                    ok = true
                    break
                end
            end
            if not ok then
                start_node = nil
            end
            table.remove(new_node_list, idx)
        end
    end

    local x, z = start_node.cent[1], start_node.cent[2]
    local y = 0
    x, y, z = get_div6_tile(x, 0, z)

    local grid = {{x = x, y = y, z = z}}

    for nx = -8, 8 do
        for nz = -8, 8 do
            local newpt = {
                x = x + (nx * 6),
                y = y,
                grid,
                z = z + (nz * 6)
            }

            local in_city_node = false
            for i, node in ipairs(city.citynodes) do
                if WorldSim:PointInSite(node.id, newpt.x, newpt.z) then
                    in_city_node = true
                end
            end

            if test_tile(newpt, VALID_TILES) and in_city_node then
                table.insert(grid, newpt)
            end
        end
    end

    local idx = math.random(1, #grid)
    local start = grid[idx]
    table.remove(grid, idx)

    if test_tile(start,VALID_TILES) then
        place_tile_city(entities, width, height, start)
    end

    local maxintersections = 30
    local opendirs = {}

    grid, opendirs = add_dirs(start, grid, opendirs)

    while maxintersections > 0 and #opendirs > 0 do
        local idx = math.random(1, #opendirs)
        local data = opendirs[idx]
        make_road(entities, width, height, spawners, data.pt, data.dir, true, city)
        if data.newpt then
            -- add_temp_ents(spawners, data.newpt.x, data.newpt.z, "onemanband", city.city_id)
            grid, opendirs = add_dirs(data.newpt, grid, opendirs)
            maxintersections = maxintersections - 1
        end
        table.remove(opendirs, idx)
    end
end

local function make_parks(entities, width, height, spawners, city, unique, unique_parks)
    local total_parks = #city.citynodes
    if unique then
        total_parks = unique_parks
    end

    for i = 1, total_parks do
        if #city.parks > 0 then
            local index = math.random(1, #city.parks)
            local park = city.parks[index]

            local pigshops_spawners = find_temp_ents(spawners, park.x, park.z, 3, {"pig_shop_spawner"})

            -- local pigshops_spawners = TheSim:FindEntities(park.x, park.y, park.z, 15, {"pig_shop_spawner"})
            for _, spawner in ipairs(pigshops_spawners) do
                for s = #spawners, 1, -1 do
                    if spawner == spawners[s] then
                        table.remove(spawners, s)
                    end
                end
            end

            print("-------------------------------- SHOULD I SPAWN A PALACE?", made_palace)
            -- Spawn palace first
            if made_palace == false and city.city_id == 2 then
                local choice = "pig_palace_1"
                print("--------------------------------  PLACING PALACE")
                if choice ~= nil then
                    spawn_setpiece(entities, width, height, spawners, choice, {x = park.x, y = park.y, z = park.z}, city)
                    table.remove(city.parks, index)
                    made_palace = true
                end
            elseif made_cityhall == false and city.city_id == 1 then
                local choice = "pig_cityhall_1"
                if choice ~= nil then
                    spawn_setpiece(entities, width, height, spawners, choice, {x = park.x, y = park.y, z = park.z}, city)
                    table.remove(city.parks, index)
                    made_cityhall = true
                end
            elseif made_playerhouse == false and city.city_id == 1 then
                local choice = "pig_playerhouse_1"
                if choice ~= nil then
                    spawn_setpiece(entities, width, height, spawners, choice, {x = park.x, y = park.y, z = park.z}, city)
                    table.remove(city.parks, index)
                    made_playerhouse = true
                end
            else
                local choice = PARK_CHOICES[math.random(1, #PARK_CHOICES)]
                if unique then
                    if #UNIQUE_PARK_CHOICES > 0 then
                        local selection = math.random(1, #UNIQUE_PARK_CHOICES)
                        choice = UNIQUE_PARK_CHOICES[selection]
                        table.remove(UNIQUE_PARK_CHOICES, selection)
                    else
                        choice = nil
                    end
                end
                if choice ~= nil then
                    spawn_setpiece(entities, width, height, spawners, choice, {x = park.x, y = park.y, z = park.z}, city)
                    table.remove(city.parks, index)
                end
            end
        end
    end
end

local function place_farm(entities, width, height, spawners, nodes, city, total, set)
    local placed_farms = 0
    local break_limit = 0
    while total > placed_farms and break_limit < 50 and #nodes > 0 do
        local tested_nodes = {}
        local total_nodes = #nodes
        local finished = false

        while #tested_nodes < total_nodes and finished == false do
            local farm_num = math.random(1, #nodes)
            local untested = true
            for i, checked_node in ipairs(tested_nodes)do
                if checked_node == farm_num then
                    untested = false
                end
            end

            if untested then
                table.insert(tested_nodes, farm_num)

                local location = {
                    x = nodes[farm_num].cent[1],
                    y = 0,
                    z = nodes[farm_num].cent[2],
                }
                location.x, location.y, location.z = get_div1_tile(location.x, location.y, location.z)

                local place_farm = true
                if place_farm then
                    local choice = set[math.random(1, #set)]
                    if spawn_setpiece(entities, width, height, spawners, choice, {x = location.x, y = location.y, z = location.z}, city) then
                        placed_farms = placed_farms + 1
                        table.remove(nodes, farm_num)
                        finished = true
                    end
                end
            end
        end
        if finished == false then
            break_limit = break_limit +1
            print("COULDNT FIND ANY PLACE TO FIT THIS FARM")
        end
    end
    return nodes
end

local function place_unique_farms(entities, width, height, spawners, cities)
    for i, farm in ipairs(REQUIRED_FARMS) do
        local city = math.random(1, CITIES)

        local nodes = cities[city].farmnodes
        place_farm(entities, width, height, spawners, nodes, cities[city], 1, {farm})
    end
end

local function make_farms(entities, width, height, spawners, nodes, city)
    nodes = place_farm(entities, width, height, spawners, nodes, city, 3, FARM_CHOICES)
    nodes = place_farm(entities, width, height, spawners, nodes, city, 9999, FARM_FILLER_CHOICES)

    for i, node in ipairs(nodes) do
        local prefabs = find_temp_ents(spawners, node.cent[1], node.cent[2], 1)

        if #prefabs == 0 then
            if test_tile({x = node.cent[1], z = node.cent[2]}, {WORLD_TILES.FIELDS}) then
                add_temp_ents(spawners, node.cent[1], node.cent[2], "pig_guard_tower", city.city_id)
            end
        end
    end
end

local function set_buildings(spawners, city)
    local building_quotas = {}

    local set = BUILDING_QUOTAS
    if city.city_id == 2 then
        set = BUILDING_QUOTAS_2
    end

    for item, data in pairs(set)do
        building_quotas[item] = data
    end

    local eligable_list = {}
    for i, spawn in ipairs(spawners)do
        if spawn.prefab == "pig_shop_spawner" and spawn.city == city.city_id then
            table.insert(eligable_list, i)
        end
    end

    for _, data_set in pairs(building_quotas) do
        local building_type = data_set.prefab
        local num = data_set.num

        for t = 1, num do
            if #eligable_list > 0 then
                local location = math.random(1, #eligable_list)
                spawners[eligable_list[location]].prefab = building_type
                table.remove(eligable_list, location)
            else
                print("*********** RAN OUT OF ELIGABLE LOCATIONS FOR ", building_type," @ ".. t.." of ".. num)
            end
        end
    end

    for i = #spawners, 1, -1 do
        if spawners[i].prefab == "pig_shop_spawner" and spawners[i].city == city.city_id then
            table.remove(spawners, i)
        end
    end
end

local function remove_shop_spawners(spawners)
    for i = #spawners, 1, -1 do
        if spawners[i].prefab == "pig_shop_spawner" then
            table.remove(spawners, i)
        end
    end
end

-- finds if an item is in a list, removes it and returns the item.
local function is_in_list(list_item, list, dont_remove)
    for i, item in ipairs(list) do
        if item == list_item then
            if not dont_remove then
                table.remove(list, i)
            end
            return item
        end
    end
    return false
end

local function is_in_nested_list(list_item, parent_list)
    for i, items in pairs(parent_list) do
        if is_in_list(list_item, items, true) then
            return list_item
        end
    end
    return false
end

local function make_cities(entities, topology_save, worldsim, width, height, setcurrent_gen_params)
    print("BUILDING PIG CULTURE")

    local spawners = {} -- anything that is added here that needs to be looked at before finally being added to the entites list.

    made_palace = false
    made_cityhall = false
    made_playerhouse = false

    local cities = {}
    for city_id = 1, CITIES do
        cities[city_id] = {}
        cities[city_id].parks = {}
        cities[city_id].citynodes = {}
        cities[city_id].farmnodes = {}
        cities[city_id].city_id = city_id
        -- cities[city_id].spawners = {}

        for task, node in pairs(topology_save.root:GetNodes(true)) do
            if table.contains(node.data.tags, "City" .. city_id) then
                local poly_x, poly_y = WorldSim:GetPointsForSite(node.id)
                local c_x, c_y = WorldSim:GetSiteCentroid(node.id)
                local nodedata = {
                    cent = {c_x, c_y},
                    id = node.id,
                    poly = {x = poly_x, y = poly_y}
                }

                if is_in_nested_list(node.id, topology_save.GlobalTags["City_Foundation"]) then  -- and not nodedata.suburb == true
                    table.insert(cities[city_id].citynodes, nodedata)
                end

                if is_in_nested_list(node.id, topology_save.GlobalTags["Cultivated"]) then
                    table.insert(cities[city_id].farmnodes, nodedata)
                end
            end
        end
    end

    place_unique_farms(entities, width, height, spawners, cities)

    for city_ID, city in ipairs(cities)do
        create_city(entities, width, height, spawners, city)
        make_parks(entities, width, height, spawners, city, true, 2)
        make_parks(entities, width, height, spawners, city)
        set_buildings(spawners, city)
        make_farms(entities, width, height, spawners, city.farmnodes, city)
        -- makeFarms(city.farmnodes,city, 25, FARM_FILLER_CHOICES)
    end

    remove_shop_spawners(spawners)

    export_spawners_to_entites(entities, width, height, spawners)

    return entities
end

return make_cities
