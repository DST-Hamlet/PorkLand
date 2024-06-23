local PROP_DEFS = {}

local function GetPosToCenter(dist, hole, random, invert)
    local pos = math.random() * 0.5 * (dist - hole) + hole / 2
    if invert or (random and math.random() < 0.5) then
        pos = -pos
    end
    return pos
end

PROP_DEFS.roc_cave = function(depth, width, room, open_exits, exterior_door_def)
    local addprops = {
        {name = "deco_cave_cornerbeam", x_offset = -depth / 2, z_offset = -width / 2, rotation = -90},
        {name = "deco_cave_cornerbeam", x_offset = -depth / 2, z_offset = width / 2, rotation = -90, flip = true},
        {name = "deco_cave_pillar_side", x_offset = depth / 2, z_offset = -width / 2, rotation = -90},
        {name = "deco_cave_pillar_side", x_offset = depth / 2, z_offset = width / 2, rotation = -90, flip = true},
        {name = "deco_cave_floor_trim_front", x_offset = depth / 2, z_offset = -width/4, rotation = -90},
        {name = "deco_cave_floor_trim_front", x_offset = depth / 2, z_offset = width/4, rotation = -90},
        {name = "deco_cave_ceiling_trim_2", x_offset = math.random() * depth * 0.5 - depth/2*0.5, z_offset = -width/2, rotation = -90, chance = 0.7},
        {name = "deco_cave_ceiling_trim_2", x_offset = math.random() * depth * 0.5 - depth/2*0.5, z_offset = width/2, rotation = -90, flip = true, chance = 0.7},
        {name = "deco_cave_beam_room", x_offset = math.random() * depth * 0.65 - depth * 0.325 , z_offset = GetPosToCenter(width * 0.65, 7, false, true), rotation = -90, chance = 0.5},
        {name = "deco_cave_beam_room", x_offset = math.random() * depth * 0.65 - depth * 0.325 , z_offset = GetPosToCenter(width * 0.65, 7), rotation = -90, chance = 0.5},
        {name = "flint", x_offset = GetPosToCenter(depth * 0.65, 3, true), z_offset = GetPosToCenter(width * 0.65, 3, true), chance = 0.5},
        {name = "deco_cave_stalactite", x_offset = math.random() * depth / 2 - depth / 4, z_offset = GetPosToCenter(width, 6, true), chance = 0.5},
        {name = "deco_cave_stalactite", x_offset = math.random() * depth / 2 - depth / 4, z_offset = GetPosToCenter(width, 6, true), chance = 0.5},
    }

    if room.is_exit_room then
        table.insert(addprops, {name = "cave_exit_roc", x_offset = -depth / 2, z_offset = 0})
    end

    if room.is_entrance_room then
        table.insert(addprops, {
            name = "prop_door",
            x_offset = 0,
            z_offset = -width / 6,
            animdata = {
                minimapicon = nil,
                bank = "exitrope",
                build = "cave_exit_rope",
                anim = "idle_loop",
            },
            my_door_id =  exterior_door_def.target_door_id,
            target_exterior = exterior_door_def.target_exterior,
            rotation = -90,
            angle = 0,
            is_exit = true
        })
        table.insert(addprops, {name = "roc_cave_light_beam", x_offset = 0, z_offset = -width / 6})
    end

    local roomtypes = {"stalacmites", "stalacmites", "glowplants", "ferns", "mushtree"}
    local roomtype = room.is_entrance_room and "stalacmites" or GetRandomItem(roomtypes)

    for i = 1, math.random(1, 3) do
        table.insert(addprops, {name = "deco_cave_ceiling_trim", x_offset = -depth / 2 , z_offset = GetPosToCenter(width * 0.6, 3, true)})
    end

    for i = 1, math.random(2, 5) do
        table.insert(addprops, {name = "cave_fern", x_offset = GetPosToCenter(depth * 0.7, 3, true), z_offset = GetPosToCenter(width * 0.7, 3, true)})
    end

    if open_exits.south then
        table.insert(addprops, {name = "deco_cave_floor_trim_front", x_offset = depth / 2, z_offset = 0, rotation = -90})
    end

    if open_exits.west then
        table.insert(addprops, {name = "deco_cave_floor_trim_2", x_offset = math.random() * depth / 2 - depth / 4, z_offset = -width / 2, rotation = -90, chance = 0.7})
    end

    if open_exits.east then
        table.insert(addprops, {name = "deco_cave_floor_trim_2", x_offset = math.random() * depth / 2 - depth / 4, z_offset = width / 2, rotation = -90, flip = true, chance = 0.7})
    end

    if roomtype == "stalacmites" then
        table.insert(addprops, {name = "stalagmite", x_offset = GetPosToCenter(depth * 0.65, 4, true), z_offset = GetPosToCenter(width * 0.65, 4, true), chance = 0.3})
        table.insert(addprops, {name = math.random() < 0.5 and "stalagmite" or "stalagmite_tall", x_offset = GetPosToCenter(depth * 0.65, 4, true), z_offset = GetPosToCenter(width * 0.65, 4, true), chance = 0.2})
        table.insert(addprops, {name = "stalagmite_tall", x_offset = GetPosToCenter(depth * 0.65, 3, true), z_offset = GetPosToCenter(width * 0.65, 3, true), chance = 0.3})
        table.insert(addprops, {name = "deco_cave_stalactite", x_offset = math.random() * depth / 2 - depth / 4, z_offset = GetPosToCenter(width, 6, true), chance = 0.5})
        table.insert(addprops, {name = "deco_cave_stalactite", x_offset = math.random() * depth / 2 - depth / 4, z_offset = GetPosToCenter(width, 6, true), chance = 0.5})
    end

    if roomtype == "ferns" then
        for i = 1, math.random(5, 15) do
            table.insert(addprops, {name = "cave_fern", x_offset = math.random() * depth * 0.7 - depth * 0.35, z_offset = math.random() * width * 0.7 - width * 0.35})
        end
    end

    if roomtype == "mushtree" then
        local mushtree
        if math.random() < 0.3 then
            mushtree = "mushtree_tall" -- 30% tall
        elseif math.random() < 0.5 then
            mushtree = "mushtree_medium" -- 35% medium
        else
            mushtree = "mushtree_small" -- 35% small
        end

        for i = 1, math.random(3, 8) do
            table.insert(addprops, {name = mushtree, x_offset = math.random() * depth * 0.7 - depth * 0.35, z_offset = math.random() * width * 0.7 - width * 0.35})
        end
    end

    if roomtype == "glowplants" then
        for i = 1, math.random(4, 12) do
            table.insert(addprops, {name = "flower_cave", x_offset = math.random() * depth * 0.7 - depth * 0.35, z_offset = math.random() * width * 0.7 - width * 0.35})
        end
    end

    return addprops
end

PROP_DEFS.vampirebatcave = function(exterior_door_def, height, width)
    local addprops = {
        {
            name = "prop_door",
            x_offset = -height / 2,
            z_offset = 0,
            animdata = {
                minimapicon = "vamp_bat_cave_exit.tex",
                bank = "doorway_cave",
                build = "bat_cave_door",
                anim = "day_loop",
                light = true,
            },
            is_exit = true,
            my_door_id = exterior_door_def.target_door_id,
            target_door_id = exterior_door_def.my_door_id,
            rotation = -90,
            angle = 0,
            addtags = {"timechange_anims"},
        },

        {name = "deco_cave_cornerbeam", x_offset = -height / 2, z_offset = -width / 2, rotation = -90},
        {name = "deco_cave_cornerbeam", x_offset = -height / 2, z_offset = width / 2, rotation = -90, flip = true},

        {name = "deco_cave_pillar_side", x_offset = height / 2, z_offset = -width / 2, rotation = -90},
        {name = "deco_cave_pillar_side", x_offset = height / 2, z_offset = width / 2, rotation = -90, flip = true},

        {name = "deco_cave_bat_burrow", x_offset = 0, z_offset = 0, rotation = -90},

        {name = "deco_cave_floor_trim_front", x_offset = height/2, z_offset = -width / 4, rotation = -90},
        {name = "deco_cave_floor_trim_front", x_offset = height/2, z_offset = 0, rotation= -90, addtags = {"roc_cave_delete_me"}, roc_cave_delete_me = true},
        {name = "deco_cave_floor_trim_front", x_offset = height/2, z_offset = width / 4, rotation = -90},

        {name = "deco_cave_floor_trim_2", x_offset = math.random() * height / 2 - height / 4, z_offset = -width / 2, rotation = -90, chance = 0.7},
        {name = "deco_cave_floor_trim_2", x_offset = math.random() * height / 2 - height / 4, z_offset = width / 2, rotation = -90, flip = true, chance = 0.7},

        {name = "deco_cave_ceiling_trim_2", x_offset = math.random() * height / 2 - height / 4, z_offset = -width / 2, rotation = -90, chance = 0.7},
        {name = "deco_cave_ceiling_trim_2", x_offset = math.random() * height / 2 - height / 4, z_offset = width / 2, rotation = -90, flip = true, chance = 0.7},

        {name = "deco_cave_beam_room", x_offset = math.random() * height * 0.65 - 0.65 * height / 2, z_offset = GetPosToCenter(width * 0.65, 7, false, true), rotation = -90, chance = 0.5},
        {name = "deco_cave_beam_room", x_offset = math.random() * height * 0.65 - 0.65 * height / 2, z_offset = GetPosToCenter(width * 0.65, 7), rotation = -90, chance = 0.5},

        {name = "flint", x_offset = GetPosToCenter(height * 0.65, 3, true), z_offset = GetPosToCenter(width * 0.65, 3, true)},
        {name = "flint", x_offset = GetPosToCenter(height * 0.65, 3, true), z_offset = GetPosToCenter(width * 0.65, 3, true), chance = 0.5},

        {name = "stalagmite", x_offset = GetPosToCenter(height * 0.65, 4, true), z_offset = GetPosToCenter(width * 0.65, 4, true)},
        {name = math.random() < 0.5 and "stalagmite" or "stalagmite_tall", x_offset = GetPosToCenter(height * 0.65, 4, true), z_offset = GetPosToCenter(width * 0.65, 4, true), chance = 0.5},
        {name = "stalagmite_tall", x_offset = GetPosToCenter(height * 0.65, 3, true), z_offset = GetPosToCenter(width * 0.65, 3, true), chance = 0.5},

        {name = "deco_cave_stalactite", x_offset = math.random() * height / 2 - height / 4, z_offset = GetPosToCenter(width, 6, true), chance = 0.5},
        {name = "deco_cave_stalactite", x_offset = math.random() * height / 2 - height / 4, z_offset = GetPosToCenter(width, 6, true), chance = 0.5},
        {name = "deco_cave_stalactite", x_offset = math.random() * height / 2 - height / 4, z_offset = GetPosToCenter(width, 6, true), chance = 0.5},
        {name = "deco_cave_stalactite", x_offset = math.random() * height / 2 - height / 4, z_offset = GetPosToCenter(width, 6, true), chance = 0.5},
    }

    for i = 1, math.random(1, 3) do
        table.insert(addprops, {name = "deco_cave_ceiling_trim", x_offset = -height / 2, z_offset = GetPosToCenter(width * 0.6, 3, true)})
    end

    for i = 1, math.random(2, 5) do
        table.insert(addprops, {name = "cave_fern", x_offset = GetPosToCenter(height * 0.7, 3, true), z_offset = GetPosToCenter(width * 0.7, 3, true)})
    end

    for _, prefab in pairs({"red_mushroom", "blue_mushroom", "green_mushroom"}) do
        for i = 1, math.random(0, 2) do
            table.insert(addprops, {name = prefab, x_offset = GetPosToCenter(height * 0.8, 3, true), z_offset = GetPosToCenter(width * 0.8, 3, true)})
        end
    end

    return addprops
end

local function GenerateProps(name, ...)
    if not PROP_DEFS[name] then
        print("Undefined interior prop: " .. name)
        return {}
    end

    return PROP_DEFS[name](...)
end

return GenerateProps
