local PROP_DEFS = {}

local function GetPosToCenter(dist, hole, random, invert)
    local pos = math.random() * 0.5 * (dist - hole) + hole / 2
    if invert or (random and math.random() < 0.5) then
        pos = -pos
    end
    return pos
end

PROP_DEFS.vampirebatcave = function(exterior_door_def, height, width)
    local addprops = {
        {
            name = "prop_door",
            x_offset = -height / 2,
            z_offset = 0,
            animdata = {
                minimapicon = "vamp_bat_cave_exit.png",
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

local function GetPropDef(name, exterior_door_def, height, width)
    if not PROP_DEFS[name] then
        print("Undefined interior prop: " .. name)
        return {}
    end

    return PROP_DEFS[name](exterior_door_def, height, width)
end

return GetPropDef
