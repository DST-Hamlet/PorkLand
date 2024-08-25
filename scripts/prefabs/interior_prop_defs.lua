local PROP_DEFS = {}

local function GetPosToCenter(dist, hole, random, invert)
    local pos = math.random() * 0.5 * (dist - hole) + hole / 2
    if invert or (random and math.random() < 0.5) then
        pos = -pos
    end
    return pos
end

local function exitNumbers(room)
    local exits = room.exits
    local total = 0
    for i,exit in pairs(exits) do
        total = total + 1
    end
    if room.entrance1 or room.entrance2 then
        total = total + 1
    end
    return total
end

local function AddSpearTrap(addprops, depth, width, offsetx, offsetz, tags, nocenter, full, scale, pluspattern)
    local scaledist = 15
    if scale then
        scaledist = scale
    end

    if pluspattern then
        addprops[#addprops + 1] = { name = "pig_ruins_spear_trap", x_offset = -depth/scaledist + offsetx, z_offset =  0 + offsetz, addtags = tags}
        addprops[#addprops + 1] = { name = "pig_ruins_spear_trap", x_offset = 0 + offsetx,                z_offset =  - width/scaledist + offsetz,  addtags = tags}
        addprops[#addprops + 1] = { name = "pig_ruins_spear_trap", x_offset = 0 + offsetx,                z_offset =  width/scaledist + offsetz,  addtags = tags}
        addprops[#addprops + 1] = { name = "pig_ruins_spear_trap", x_offset = depth/scaledist - offsetx, z_offset =  0 + offsetz,  addtags = tags}
    else
        addprops[#addprops + 1] = { name = "pig_ruins_spear_trap", x_offset = -depth/scaledist + offsetx, z_offset =  -width/scaledist + offsetz, addtags = tags}
        addprops[#addprops + 1] = { name = "pig_ruins_spear_trap", x_offset = -depth/scaledist + offsetx, z_offset =  width/scaledist + offsetz,  addtags = tags}
        if not nocenter then
            addprops[#addprops + 1] = { name = "pig_ruins_spear_trap", x_offset = 0 + offsetx, z_offset =  0 + offsetz, addtags = tags}
        end
        addprops[#addprops + 1] = { name = "pig_ruins_spear_trap", x_offset = depth/scaledist + offsetx, z_offset =  -width/scaledist + offsetz,  addtags = tags}
        addprops[#addprops + 1] = { name = "pig_ruins_spear_trap", x_offset = depth/scaledist + offsetx, z_offset =  width/scaledist + offsetz,   addtags = tags}

        if full then
            addprops[#addprops + 1] = { name = "pig_ruins_spear_trap", x_offset = -depth/scaledist + offsetx, z_offset =  0+ offsetz,  addtags = tags}
            addprops[#addprops + 1] = { name = "pig_ruins_spear_trap", x_offset = depth/scaledist + offsetx, z_offset =  0+ offsetz,   addtags = tags}
            addprops[#addprops + 1] = { name = "pig_ruins_spear_trap", x_offset = 0+ offsetx, z_offset =  -width/scaledist + offsetz,  addtags = tags}
            addprops[#addprops + 1] = { name = "pig_ruins_spear_trap", x_offset = 0+ offsetx, z_offset =  width/scaledist + offsetz,   addtags = tags}
        end
    end

    return addprops
end

local function AddGoldStatue(addprops,x,z)
    if math.random() <0.5 then
        addprops[#addprops + 1] = { name = "pig_ruins_pig", x_offset = x, z_offset =  z, rotation = -90 }
    else
        addprops[#addprops + 1] = { name = "pig_ruins_ant", x_offset = x, z_offset =  z, rotation = -90 }
    end
    return addprops
end

local function AddRelicStatue(addprops,x,z, tags)
    if math.random() <0.5 then
        addprops[#addprops + 1] = { name = "pig_ruins_idol", x_offset = x, z_offset =  z, rotation = -90, addtags = tags }
    else
        addprops[#addprops + 1] = { name = "pig_ruins_plaque", x_offset = x, z_offset =  z, rotation = -90, addtags = tags }
    end
    return addprops
end

local function GetLootChoice(list)

    local item = nil
    local total = 0
    for i = 1, #list do
        total = total + list[i][2]
    end

    local choice = math.random(1,total)
    total = 0
    local last = 0
    local top = 0
    for i = 1, #list do
        top = top + list[i][2]
        if choice > last and choice <= top then
            item = list[i][1]
            break
        end
        last = top
    end
    assert(item)
    return item
end

local function GetSpawnLocation(depth, width, widthrange, depthrange, fountain)
    local setwidth = width * widthrange * math.random() - width * widthrange/2
    local setdepth = depth * depthrange * math.random() - depth * depthrange/2
    local place = true
    if fountain then
        -- filters out thigns that would place where the fountain is
        if  math.abs(setwidth * setwidth) + math.abs(setdepth * setdepth) < 4 * 4 then
            place = false
        end
    end
    if place == true then
        return setwidth, setdepth
    end
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
        addprops[#addprops + 1] = {name = "cave_exit_roc", x_offset = -depth / 2, z_offset = 0}
    end

    if room.is_entrance_room then
        addprops[#addprops + 1] = {
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
        }
        addprops[#addprops + 1] = {name = "roc_cave_light_beam", x_offset = 0, z_offset = -width / 6}
    end

    local roomtypes = {"stalacmites", "stalacmites", "glowplants", "ferns", "mushtree"}
    local roomtype = room.is_entrance_room and "stalacmites" or GetRandomItem(roomtypes)

    for i = 1, math.random(1, 3) do
        addprops[#addprops + 1] = {name = "deco_cave_ceiling_trim", x_offset = -depth / 2 , z_offset = GetPosToCenter(width * 0.6, 3, true)}
    end

    for i = 1, math.random(2, 5) do
        addprops[#addprops + 1] = {name = "cave_fern", x_offset = GetPosToCenter(depth * 0.7, 3, true), z_offset = GetPosToCenter(width * 0.7, 3, true)}
    end

    if open_exits.south then
        addprops[#addprops + 1] = {name = "deco_cave_floor_trim_front", x_offset = depth / 2, z_offset = 0, rotation = -90}
    end

    if open_exits.west then
        addprops[#addprops + 1] = {name = "deco_cave_floor_trim_2", x_offset = math.random() * depth / 2 - depth / 4, z_offset = -width / 2, rotation = -90, chance = 0.7}
    end

    if open_exits.east then
        addprops[#addprops + 1] = {name = "deco_cave_floor_trim_2", x_offset = math.random() * depth / 2 - depth / 4, z_offset = width / 2, rotation = -90, flip = true, chance = 0.7}
    end

    if roomtype == "stalacmites" then
        addprops[#addprops + 1] = {name = "stalagmite", x_offset = GetPosToCenter(depth * 0.65, 4, true), z_offset = GetPosToCenter(width * 0.65, 4, true), chance = 0.3}
        addprops[#addprops + 1] = {name = math.random() < 0.5 and "stalagmite" or "stalagmite_tall", x_offset = GetPosToCenter(depth * 0.65, 4, true), z_offset = GetPosToCenter(width * 0.65, 4, true), chance = 0.2}
        addprops[#addprops + 1] = {name = "stalagmite_tall", x_offset = GetPosToCenter(depth * 0.65, 3, true), z_offset = GetPosToCenter(width * 0.65, 3, true), chance = 0.3}
        addprops[#addprops + 1] = {name = "deco_cave_stalactite", x_offset = math.random() * depth / 2 - depth / 4, z_offset = GetPosToCenter(width, 6, true), chance = 0.5}
        addprops[#addprops + 1] = {name = "deco_cave_stalactite", x_offset = math.random() * depth / 2 - depth / 4, z_offset = GetPosToCenter(width, 6, true), chance = 0.5}
    end

    if roomtype == "ferns" then
        for i = 1, math.random(5, 15) do
            addprops[#addprops + 1] = {name = "cave_fern", x_offset = math.random() * depth * 0.7 - depth * 0.35, z_offset = math.random() * width * 0.7 - width * 0.35}
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
            addprops[#addprops + 1] = {name = mushtree, x_offset = math.random() * depth * 0.7 - depth * 0.35, z_offset = math.random() * width * 0.7 - width * 0.35}
        end
    end

    if roomtype == "glowplants" then
        for i = 1, math.random(4, 12) do
            addprops[#addprops + 1] = {name = "flower_cave", x_offset = math.random() * depth * 0.7 - depth * 0.35, z_offset = math.random() * width * 0.7 - width * 0.35}
        end
    end

    return addprops
end

PROP_DEFS.pig_ruins_dart_trap = function(depth, width, exits_open, exits_vined, room, roomtype, dungeondef, exterior_door_def, nopressureplates)
    local addprops = PROP_DEFS.pig_ruins_common(depth, width, exits_open, exits_vined, room, roomtype, dungeondef, exterior_door_def)

    if dungeondef.advancedtraps and math.random() < 0.3 then
        local x = depth / 8
        if math.random() < 0.5 then
            x = -x
        end
        local z = width / 8
        if math.random() < 0.5 then
            z = -z
        end

        addprops[#addprops + 1] = {name = "pig_ruins_dart_statue", x_offset = x, z_offset =  z}
    else
        addprops[#addprops + 1] = { name = "pig_ruins_pigman_relief_dart"..math.random(4)..room.color, x_offset = -depth/2, z_offset =  -width/3}
        if exits_open.north then
            addprops[#addprops + 1] = { name = "pig_ruins_pigman_relief_dart"..math.random(4)..room.color, x_offset = -depth/2, z_offset =  0}
        end
        addprops[#addprops + 1] = { name = "pig_ruins_pigman_relief_dart"..math.random(4)..room.color, x_offset = -depth/2, z_offset =  width/3 }

        addprops[#addprops + 1] = { name = "pig_ruins_pigman_relief_leftside_dart"..room.color, x_offset = -depth/4+(math.random()*1 -0.5), z_offset =  -width/2 }
        if exits_open.west then
            addprops[#addprops + 1] = { name = "pig_ruins_pigman_relief_leftside_dart"..room.color, x_offset = 0+(math.random()*1 -0.5), z_offset =  -width/2 }
        end
        addprops[#addprops + 1] = { name = "pig_ruins_pigman_relief_leftside_dart"..room.color, x_offset = depth/4+(math.random()*1 -0.5), z_offset =  -width/2 }

        addprops[#addprops + 1] = { name = "pig_ruins_pigman_relief_rightside_dart"..room.color, x_offset = -depth/4+(math.random()*1 -0.5), z_offset =  width/2 }
        if exits_open.east then
            addprops[#addprops + 1] = { name = "pig_ruins_pigman_relief_rightside_dart"..room.color, x_offset = 0+(math.random()*1 -0.5), z_offset =  width/2 }
        end
        addprops[#addprops + 1] = { name = "pig_ruins_pigman_relief_rightside_dart"..room.color, x_offset = depth/4+(math.random()*1 -0.5), z_offset =  width/2 }
    end

    -- ziwbi: not nopressureplates will always be true, see PROP_DEFS.pig_ruins_treasure
    -- 亚丹：实际上nopressureplates在3雕像吹箭陷阱房间被使用了
    -- if the treasure room wants dart traps, then the plates get turned off.
    if not nopressureplates then
        addprops[#addprops + 1] = { name = "pig_ruins_pressure_plate", x_offset = -depth/6*2+ (math.random()*2 - 1),        z_offset = 0+ (math.random()*2 - 1),        addtags={"trap_dart"} }
        addprops[#addprops + 1] = { name = "pig_ruins_pressure_plate", x_offset = 0 + (math.random(2) - 1),        z_offset = 0+ (math.random()*2 - 1),        addtags={"trap_dart"} }

        if exits_open.south then
            addprops[#addprops + 1] = { name = "pig_ruins_pressure_plate", x_offset = depth/6*2+ (math.random()*2 - 1),        z_offset = 0+ (math.random()*2 - 1),        addtags={"trap_dart"} }
        end

        addprops[#addprops + 1] = { name = "pig_ruins_pressure_plate", x_offset = -depth/6*2+ (math.random()*2 - 1), z_offset = -width/6*2+(math.random()*2 - 1), addtags={"trap_dart"} }
        addprops[#addprops + 1] = { name = "pig_ruins_pressure_plate", x_offset = (math.random()*2 - 1), z_offset = -width/6*2+(math.random()*2 - 1), addtags={"trap_dart"} }
        addprops[#addprops + 1] = { name = "pig_ruins_pressure_plate", x_offset = -depth/6*2+ (math.random()*2 - 1), z_offset =  width/6*2+(math.random()*2 - 1), addtags={"trap_dart"} }

        addprops[#addprops + 1] = { name = "pig_ruins_pressure_plate", x_offset =  depth/6*2+ (math.random()*2 - 1), z_offset = -width/6*2+(math.random()*2 - 1), addtags={"trap_dart"} }
        addprops[#addprops + 1] = { name = "pig_ruins_pressure_plate", x_offset =  (math.random()*2 - 1), z_offset = width/6*2+(math.random()*2 - 1), addtags={"trap_dart"} }
        addprops[#addprops + 1] = { name = "pig_ruins_pressure_plate", x_offset =  depth/6*2+ (math.random()*2 - 1), z_offset =  width/6*2+(math.random()*2 - 1), addtags={"trap_dart"} }
    end

    return addprops
end

PROP_DEFS.pig_ruins_door_trap = function(depth, width, exits_open, exits_vined, room, roomtype, dungeondef, exterior_door_def)
    local addprops = PROP_DEFS.pig_ruins_common(depth, width, exits_open, exits_vined, room, roomtype, dungeondef, exterior_door_def)

    local setups = {"default","default","default","hor","vert"}

    if dungeondef.deepruins then
        if exits_open.north or exits_open.south then
            table.insert(setups, "longhor")
        end
        if (exits_open.east or exits_open.west) and not room.normal_pillars then
            table.insert(setups, "longvert")
        end
    end
    local random =  math.random(1,#setups)

    if setups[random] == "default" then
        addprops[#addprops + 1] = {name = "pig_ruins_pressure_plate", x_offset = -depth/2 +3 + (math.random()*2 - 1), z_offset = (math.random()*2 - 1)}
        addprops[#addprops + 1] = {name = "pig_ruins_pressure_plate", x_offset =  depth/2 -3 + (math.random()*2 - 1), z_offset = (math.random()*2 - 1)}
        addprops[#addprops + 1] = {name = "pig_ruins_pressure_plate", x_offset = (math.random()*2 - 1), z_offset = (math.random()*2 - 1) }
        addprops[#addprops + 1] = {name = "pig_ruins_pressure_plate", x_offset = (math.random()*2 - 1), z_offset =  width/2 -3 + (math.random()*2 - 1)}
        addprops[#addprops + 1] = {name = "pig_ruins_pressure_plate", x_offset = (math.random()*2 - 1), z_offset = -width/2 +3 + (math.random()*2 - 1)}
    elseif setups[random] == "hor" then
        local unit = 1.5
        addprops[#addprops + 1] = { name = "pig_ruins_pressure_plate", x_offset = 0, z_offset = 0 }
        addprops[#addprops + 1] = { name = "pig_ruins_pressure_plate", x_offset = 0, z_offset = 1*unit }
        addprops[#addprops + 1] = { name = "pig_ruins_pressure_plate", x_offset = 0, z_offset = -1*unit }
        addprops[#addprops + 1] = { name = "pig_ruins_pressure_plate", x_offset = 0, z_offset = -2*unit }
        addprops[#addprops + 1] = { name = "pig_ruins_pressure_plate", x_offset = 0, z_offset = 2*unit }
        addprops[#addprops + 1] = { name = "pig_ruins_pressure_plate", x_offset = 0, z_offset = 3*unit }
        addprops[#addprops + 1] = { name = "pig_ruins_pressure_plate", x_offset = 0, z_offset = -3*unit }
    elseif setups[random] == "longvert" then
        local unit = 1.5
        local dir = {}
        if exits_open.east then
            table.insert(dir,1)
        end
        if exits_open.west then
            table.insert(dir,-1)
        end
        dir = dir[math.random(1,#dir)]
        addprops[#addprops + 1] = { name = "pig_ruins_pressure_plate", x_offset = depth/4.5 * dir, z_offset = 0 }
        addprops[#addprops + 1] = { name = "pig_ruins_pressure_plate", x_offset = depth/4.5 * dir, z_offset = 1*unit }
        addprops[#addprops + 1] = { name = "pig_ruins_pressure_plate", x_offset = depth/4.5 * dir, z_offset = -1*unit }
        addprops[#addprops + 1] = { name = "pig_ruins_pressure_plate", x_offset = depth/4.5 * dir, z_offset = -2*unit }
        addprops[#addprops + 1] = { name = "pig_ruins_pressure_plate", x_offset = depth/4.5 * dir, z_offset = 2*unit }
        addprops[#addprops + 1] = { name = "pig_ruins_pressure_plate", x_offset = depth/4.5 * dir, z_offset = 3*unit }
        addprops[#addprops + 1] = { name = "pig_ruins_pressure_plate", x_offset = depth/4.5 * dir, z_offset = -3*unit }
        addprops[#addprops + 1] = { name = "pig_ruins_pressure_plate", x_offset = depth/4.5 * dir, z_offset = 4*unit }
        addprops[#addprops + 1] = { name = "pig_ruins_pressure_plate", x_offset = depth/4.5 * dir, z_offset = -4*unit }
        addprops[#addprops + 1] = { name = "pig_ruins_pressure_plate", x_offset = depth/4.5 * dir, z_offset = 5*unit }
        addprops[#addprops + 1] = { name = "pig_ruins_pressure_plate", x_offset = depth/4.5 * dir, z_offset = -5*unit }
        addprops[#addprops + 1] = { name = "pig_ruins_pressure_plate", x_offset = depth/4.5 * dir, z_offset = 6*unit }
        addprops[#addprops + 1] = { name = "pig_ruins_pressure_plate", x_offset = depth/4.5 * dir, z_offset = -6*unit }
        addprops[#addprops + 1] = { name = "pig_ruins_pressure_plate", x_offset = depth/4.5 * dir, z_offset = 7*unit }
        addprops[#addprops + 1] = { name = "pig_ruins_pressure_plate", x_offset = depth/4.5 * dir, z_offset = -7*unit }

    elseif setups[random] == "vert" then
        local unit = 1.5
        addprops[#addprops + 1] = { name = "pig_ruins_pressure_plate", x_offset = 0, z_offset = 0 }
        addprops[#addprops + 1] = { name = "pig_ruins_pressure_plate", x_offset = 1*unit, z_offset = 0 }
        addprops[#addprops + 1] = { name = "pig_ruins_pressure_plate", x_offset = 2*unit, z_offset = 0 }
        addprops[#addprops + 1] = { name = "pig_ruins_pressure_plate", x_offset = 3*unit, z_offset = 0 }
        addprops[#addprops + 1] = { name = "pig_ruins_pressure_plate", x_offset = -1*unit, z_offset = 0 }
        addprops[#addprops + 1] = { name = "pig_ruins_pressure_plate", x_offset = -2*unit, z_offset = 0 }
        addprops[#addprops + 1] = { name = "pig_ruins_pressure_plate", x_offset = -3*unit, z_offset = 0 }

    elseif setups[random] == "longhor" then
        local unit = 1.5
        local dir = {}
        if exits_open.north then
            table.insert(dir,-1)
        end
        if exits_open.south then
            table.insert(dir,1)
        end
        dir = dir[math.random(1,#dir)]
        addprops[#addprops + 1] = { name = "pig_ruins_pressure_plate", x_offset = 0, z_offset =  width/4.5 * dir }
        addprops[#addprops + 1] = { name = "pig_ruins_pressure_plate", x_offset = 1*unit, z_offset =  width/4.5 * dir }
        addprops[#addprops + 1] = { name = "pig_ruins_pressure_plate", x_offset = 2*unit, z_offset =  width/4.5 * dir }
        addprops[#addprops + 1] = { name = "pig_ruins_pressure_plate", x_offset = 3*unit, z_offset =  width/4.5 * dir }
        addprops[#addprops + 1] = { name = "pig_ruins_pressure_plate", x_offset = 4*unit, z_offset =  width/4.5 * dir }
        addprops[#addprops + 1] = { name = "pig_ruins_pressure_plate", x_offset = 5*unit, z_offset =  width/4.5 * dir }

        addprops[#addprops + 1] = { name = "pig_ruins_pressure_plate", x_offset = -1*unit, z_offset =  width/4.5 * dir }
        addprops[#addprops + 1] = { name = "pig_ruins_pressure_plate", x_offset = -2*unit, z_offset =  width/4.5 * dir }
        addprops[#addprops + 1] = { name = "pig_ruins_pressure_plate", x_offset = -3*unit, z_offset =  width/4.5 * dir }
        addprops[#addprops + 1] = { name = "pig_ruins_pressure_plate", x_offset = -4*unit, z_offset =  width/4.5 * dir }
        addprops[#addprops + 1] = { name = "pig_ruins_pressure_plate", x_offset = -5*unit, z_offset =  width/4.5 * dir }

    end

    return addprops
end

PROP_DEFS.pig_ruins_grown_over = function(depth, width, exits_open, exits_vined, room, roomtype, dungeondef, exterior_door_def)
    local addprops = PROP_DEFS.pig_ruins_common(depth, width, exits_open, exits_vined, room, roomtype, dungeondef, exterior_door_def)

    addprops[#addprops + 1] = {name = "lightrays_jungle", x_offset = 0, z_offset = 0}

    for i = 1, math.random(8, 18) do
        local set_width, set_depth = GetSpawnLocation(depth, width, 0.8, 0.8, room.fountain)
        if set_width and set_depth then
            addprops[#addprops + 1] = {name = "grass", x_offset = set_depth, z_offset = set_width}
        end
    end

    for i = 1, math.random(12, 20) do
        local set_width, set_depth = GetSpawnLocation(depth, width, 0.8, 0.8, room.fountain)
        if set_width and set_depth then
            addprops[#addprops + 1] = {name = "sapling", x_offset = set_depth, z_offset = set_width}
        end
    end

    for i = 1, math.random(10, 20) do
        local set_width, set_depth = GetSpawnLocation(depth, width, 0.8, 0.8, room.fountain)
        if set_width and set_depth then
            addprops[#addprops + 1] = {name = "deep_jungle_fern_noise_plant", x_offset = set_depth, z_offset = set_width}
        end
    end

    return addprops
end

PROP_DEFS.pig_ruins_small_treasure = function(depth, width, exits_open, exits_vined, room, roomtype, dungeondef, exterior_door_def)
    local addprops = PROP_DEFS.pig_ruins_common(depth, width, exits_open, exits_vined, room, roomtype, dungeondef, exterior_door_def)

    if math.random() < 0.5 then
        AddGoldStatue(addprops, 0, -width / 6)
        AddGoldStatue(addprops, 0, width / 6)
    else
        AddRelicStatue(addprops, 0, 0)
    end

    return addprops
end

PROP_DEFS.pig_ruins_snake = function(depth, width, exits_open, exits_vined, room, roomtype, dungeondef, exterior_door_def)
    local addprops = PROP_DEFS.pig_ruins_common(depth, width, exits_open, exits_vined, room, roomtype, dungeondef, exterior_door_def)

    for i = 1, math.random(3, 6) do
        addprops[#addprops + 1] = {
            name = "snake_amphibious",
            x_offset =  depth * 0.8 * math.random() - depth * 0.4,
            z_offset =  width * 0.8 * math.random() - width * 0.4,
        }
    end

    return addprops
end

PROP_DEFS.pig_ruins_spear_trap = function(depth, width, exits_open, exits_vined, room, roomtype, dungeondef, exterior_door_def)
    local addprops = PROP_DEFS.pig_ruins_common(depth, width, exits_open, exits_vined, room, roomtype, dungeondef, exterior_door_def)

    local local_trap_tags = {"localtrap"}
    local pressure_plate_tags = {"trap_spear", "localtrap", "reversetrigger", "startdown"}

    local speartraps = {"spottraps","walltrap","wavetrap","bait"}
    if dungeondef.deepruins and GetTableSize(room.exits) > 1 then
        table.insert(speartraps, "litfloor")
    end
    local random = math.random(1, #speartraps)

    if speartraps[random] == "spottraps" then
        if math.random() < 0.3 then
            AddSpearTrap(addprops, depth, width, depth/3, -width/3)
            addprops[#addprops + 1] = { name = "pig_ruins_light_beam", x_offset = depth/3, z_offset =  -width/3, addtags = local_trap_tags}
        elseif math.random() < 0.5 then
            AddSpearTrap(addprops, depth, width, 0, -width/3)
            addprops[#addprops + 1] = { name = "pig_ruins_light_beam", x_offset = 0, z_offset =  -width/3, addtags = local_trap_tags}
        else
            AddSpearTrap(addprops, depth, width, -depth/3, -width/3)
            addprops[#addprops + 1] = { name = "pig_ruins_light_beam", x_offset = -depth/3, z_offset = -width/3, addtags = local_trap_tags}
        end

        if math.random() < 0.3 then
            AddSpearTrap(addprops, depth, width, -depth/3, width/3)
            addprops[#addprops + 1] = { name = "pig_ruins_light_beam", x_offset = -depth/3, z_offset =  width/3, addtags = local_trap_tags}
        elseif math.random() < 0.5 then
            AddSpearTrap(addprops, depth, width, 0, width/3)
            addprops[#addprops + 1] = { name = "pig_ruins_light_beam", x_offset = 0, z_offset =  width/3, addtags = local_trap_tags}
        else
            AddSpearTrap(addprops, depth, width, depth/3, width/3)
            addprops[#addprops + 1] = { name = "pig_ruins_light_beam", x_offset = depth/3, z_offset =  width/3, addtags = local_trap_tags}
        end

        if math.random() < 0.3 then
            AddSpearTrap(addprops, depth, width, -depth / 3, 0)
            addprops[#addprops + 1] = {name = "pig_ruins_light_beam", x_offset = -depth / 3, z_offset = 0, addtags = local_trap_tags}
        elseif math.random() < 0.5 then
            AddSpearTrap(addprops, depth, width, 0, 0)
            addprops[#addprops + 1] = {name = "pig_ruins_light_beam", x_offset = 0, z_offset = 0, addtags = local_trap_tags}
        else
            AddSpearTrap(addprops, depth, width, depth / 3, 0)
            addprops[#addprops + 1] = {name = "pig_ruins_light_beam", x_offset = depth / 3, z_offset = 0, addtags = local_trap_tags}
        end
    elseif speartraps[random] == "bait" then
        local baits = {
            {"goldnugget",5},
            {"rocks",20},
            {"flint",20},
            {"redgem",1},
            {"relic_1",1},
            {"relic_2",1},
            {"relic_3",1},
            {"boneshard",5},
            {"meat_dried",5},
        }

        local offsets = {
            {-depth / 5, -width / 5},
            { depth / 5, -width / 5},
            {-depth / 5,  width / 5},
            { depth / 5,  width / 5}
        }

        for i=1, math.random(1,3) do
            local rand = math.random(1, #offsets)
            local choice_x = offsets[rand][1]
            local choice_z = offsets[rand][2]
            table.remove(offsets,rand)

            local loot = GetLootChoice(deepcopy(baits))

            AddSpearTrap(addprops, depth, width, choice_x, choice_z, nil, true, true, 12)
            addprops[#addprops + 1] = {name = "pig_ruins_pressure_plate", x_offset = choice_x, z_offset = choice_z, addtags = pressure_plate_tags}
            addprops[#addprops + 1] = {name = loot, x_offset = choice_x, z_offset = choice_z}
        end

    elseif speartraps[random] == "walltrap" then
        local num_traps = 14
        local angle = 0
        local angle_step = TWOPI / num_traps
        local radius = 4

        for i = 1, num_traps do
            local offset = Vector3(math.cos(angle), 0, math.sin(-angle)) * radius
            addprops[#addprops + 1] = {name = "pig_ruins_spear_trap", x_offset = offset.x, z_offset = offset.z}
            angle = angle + angle_step
        end

        angle = 0
        num_traps = 24
        angle_step = TWOPI /num_traps
        radius = 5

        for i = 1, num_traps do
            local offset = Vector3(math.cos(angle), 0, math.sin(-angle)) * radius
            addprops[#addprops + 1] = {name = "pig_ruins_spear_trap", x_offset = offset.x, z_offset = offset.z}
            angle = angle + angle_step
        end

        addprops[#addprops + 1] = {name = "relic_1", x_offset = 0, z_offset = 0}
        addprops[#addprops + 1] = {name = "pig_ruins_light_beam", x_offset = 0, z_offset = 0}

    elseif speartraps[random] == "wavetrap" then
        if math.random() < 0.2 then
            local function getrandomset()
                local set = {}
                local random = math.random(1,3)
                if random == 1 then
                    set = {"timed","up_3","down_6","delay_3"}
                elseif random == 2 then
                    set = {"timed","up_3","down_6","delay_6"}
                elseif random == 3 then
                    set = {"timed","up_3","down_6","delay_9"}
                end

                return set
            end

            local function AddRandomSpearTraps(xmod, ymod, plus)
                local scaledist = 15
                if plus then
                    addprops[#addprops + 1] = { name = "pig_ruins_spear_trap", x_offset = -depth/scaledist + xmod, z_offset =  ymod, addtags = getrandomset()}
                    addprops[#addprops + 1] = { name = "pig_ruins_spear_trap", x_offset =  xmod, z_offset =  width/scaledist + ymod, addtags = getrandomset()}

                    addprops[#addprops + 1] = { name = "pig_ruins_spear_trap", x_offset = depth/scaledist + xmod, z_offset =  ymod, addtags = getrandomset()}
                    addprops[#addprops + 1] = { name = "pig_ruins_spear_trap", x_offset = xmod, z_offset =  -width/scaledist + ymod, addtags = getrandomset()}
                else
                    addprops[#addprops + 1] = { name = "pig_ruins_spear_trap", x_offset = -depth/scaledist + xmod, z_offset =  -width/scaledist + ymod, addtags = getrandomset()}
                    addprops[#addprops + 1] = { name = "pig_ruins_spear_trap", x_offset = -depth/scaledist + xmod, z_offset =  width/scaledist + ymod, addtags = getrandomset()}

                    addprops[#addprops + 1] = { name = "pig_ruins_spear_trap", x_offset = depth/scaledist + xmod, z_offset =  -width/scaledist + ymod, addtags = getrandomset()}
                    addprops[#addprops + 1] = { name = "pig_ruins_spear_trap", x_offset = depth/scaledist + xmod, z_offset =  width/scaledist + ymod, addtags = getrandomset()}
                end
            end

            AddRandomSpearTraps(0, -width/4)
            AddRandomSpearTraps(0, 0, true)
            AddRandomSpearTraps(0, width/4)

            AddRandomSpearTraps(-depth/4, -width/4, true)
            AddRandomSpearTraps(-depth/4, 0)
            AddRandomSpearTraps(-depth/4, width/4, true)

            AddRandomSpearTraps(depth/4, -width/4, true)
            AddRandomSpearTraps(depth/4, 0)
            AddRandomSpearTraps(depth/4, width/4, true)

        elseif math.random() < 0.5 then
            AddSpearTrap(addprops, depth, width, 0, -width/4, {"timed","up_3","down_6","delay_3"}, true)
            AddSpearTrap(addprops, depth, width, 0, 0,        {"timed","up_3","down_6","delay_6"}, true)
            AddSpearTrap(addprops, depth, width, 0, width/4,  {"timed","up_3","down_6","delay_9"}, true)

            AddSpearTrap(addprops, depth, width, -depth/4, -width/4, {"timed","up_3","down_6","delay_3"}, true)
            AddSpearTrap(addprops, depth, width, -depth/4, 0,        {"timed","up_3","down_6","delay_6"}, true)
            AddSpearTrap(addprops, depth, width, -depth/4, width/4,  {"timed","up_3","down_6","delay_9"}, true)

            AddSpearTrap(addprops, depth, width, depth/4, -width/4, {"timed","up_3","down_6","delay_3"}, true)
            AddSpearTrap(addprops, depth, width, depth/4, 0,        {"timed","up_3","down_6","delay_6"}, true)
            AddSpearTrap(addprops, depth, width, depth/4, width/4,  {"timed","up_3","down_6","delay_9"}, true)
        else
            AddSpearTrap(addprops, depth, width, 0, -width/4, {"timed","up_3","down_6","delay_6"}, true)
            AddSpearTrap(addprops, depth, width, 0, 0,        {"timed","up_3","down_6","delay_6"}, true)
            AddSpearTrap(addprops, depth, width, 0, width/4,  {"timed","up_3","down_6","delay_6"}, true)

            AddSpearTrap(addprops, depth, width, -depth/4, -width/4, {"timed","up_3","down_6","delay_9"}, true)
            AddSpearTrap(addprops, depth, width, -depth/4, 0,        {"timed","up_3","down_6","delay_9"}, true)
            AddSpearTrap(addprops, depth, width, -depth/4, width/4,  {"timed","up_3","down_6","delay_9"}, true)

            AddSpearTrap(addprops, depth, width, depth/4, -width/4, {"timed","up_3","down_6","delay_3"}, true)
            AddSpearTrap(addprops, depth, width, depth/4, 0,        {"timed","up_3","down_6","delay_3"}, true)
            AddSpearTrap(addprops, depth, width, depth/4, width/4,  {"timed","up_3","down_6","delay_3"}, true)
        end
    elseif speartraps[random] == "litfloor" then
        AddSpearTrap(addprops, depth, width, depth/2.7, -width/2.7)
        addprops[#addprops + 1] = { name = "pig_ruins_light_beam", x_offset = depth/2.5, z_offset =  -width/2.5, addtags = local_trap_tags}

        AddSpearTrap(addprops, depth, width, depth/6, -width/2.7, nil, nil, nil, nil, true)
        addprops[#addprops + 1] = { name = "pig_ruins_light_beam", x_offset = depth/6, z_offset =  -width/2.5, addtags = local_trap_tags}

        AddSpearTrap(addprops, depth, width, -depth/6, -width/2.7, nil, nil, nil, nil, true)
        addprops[#addprops + 1] = { name = "pig_ruins_light_beam", x_offset = -depth/6, z_offset =  -width/2.5, addtags = local_trap_tags}

        AddSpearTrap(addprops, depth, width, -depth/2.7, -width/2.7)
        addprops[#addprops + 1] = { name = "pig_ruins_light_beam", x_offset = -depth/2.5, z_offset =  -width/2.5, addtags = local_trap_tags}

        AddSpearTrap(addprops, depth, width, depth/2.5, -width/6, nil, nil, nil, nil, true)
        addprops[#addprops + 1] = { name = "pig_ruins_light_beam", x_offset = depth/2.5, z_offset =  -width/6, addtags = local_trap_tags}

        AddSpearTrap(addprops, depth, width, depth/6, -width/6)
        addprops[#addprops + 1] = { name = "pig_ruins_light_beam", x_offset = depth/6, z_offset =  -width/6, addtags = local_trap_tags}

        AddSpearTrap(addprops, depth, width, 0, -width/6, nil, nil, nil, nil, true)
        addprops[#addprops + 1] = { name = "pig_ruins_light_beam", x_offset = 0, z_offset =  -width/6, addtags = local_trap_tags}

        AddSpearTrap(addprops, depth, width, -depth/6, -width/6)
        addprops[#addprops + 1] = { name = "pig_ruins_light_beam", x_offset = -depth/6, z_offset =  -width/6, addtags = local_trap_tags}

        AddSpearTrap(addprops, depth, width, -depth/2.5, -width/6, nil, nil, nil, nil, true)
        addprops[#addprops + 1] = { name = "pig_ruins_light_beam", x_offset = -depth/2.5, z_offset =  -width/6, addtags = local_trap_tags}

        AddSpearTrap(addprops, depth, width, depth/6, 0, nil, nil, nil, nil, true)
        addprops[#addprops + 1] = { name = "pig_ruins_light_beam", x_offset = depth/6, z_offset = 0, addtags = local_trap_tags}

        AddSpearTrap(addprops, depth, width, 0, 0)
        addprops[#addprops + 1] = { name = "pig_ruins_light_beam", x_offset = 0, z_offset = 0, addtags = local_trap_tags}

        AddSpearTrap(addprops, depth, width, -depth/6, 0, nil, nil, nil, nil, true)
        addprops[#addprops + 1] = { name = "pig_ruins_light_beam", x_offset = -depth/6, z_offset = 0, addtags = local_trap_tags}

        AddSpearTrap(addprops, depth, width, depth/2.5, width/6, nil, nil, nil, nil, true)
        addprops[#addprops + 1] = { name = "pig_ruins_light_beam", x_offset = depth/2.5, z_offset = width/6, addtags = local_trap_tags}

        AddSpearTrap(addprops, depth, width, depth/6, width/6)
        addprops[#addprops + 1] = { name = "pig_ruins_light_beam", x_offset = depth/6, z_offset = width/6, addtags = local_trap_tags}

        AddSpearTrap(addprops, depth, width, 0, width/6, nil, nil, nil, nil, true)
        addprops[#addprops + 1] = { name = "pig_ruins_light_beam", x_offset = 0, z_offset =  width/6, addtags = local_trap_tags}

        AddSpearTrap(addprops, depth, width, -depth/6, width/6)
        addprops[#addprops + 1] = { name = "pig_ruins_light_beam", x_offset = -depth/6, z_offset = width/6, addtags = local_trap_tags}

        AddSpearTrap(addprops, depth, width, -depth/2.5, width/6, nil, nil, nil, nil, true)
        addprops[#addprops + 1] = { name = "pig_ruins_light_beam", x_offset = -depth/2.5, z_offset = width/6, addtags = local_trap_tags}


        AddSpearTrap(addprops, depth, width, depth/2.7, width/2.7)
        addprops[#addprops + 1] = { name = "pig_ruins_light_beam", x_offset = depth/2.5, z_offset = width/2.5, addtags = local_trap_tags}

        AddSpearTrap(addprops, depth, width, depth/6, width/2.7, nil, nil, nil, nil, true)
        addprops[#addprops + 1] = { name = "pig_ruins_light_beam", x_offset = depth/6, z_offset = width/2.5, addtags = local_trap_tags}

        AddSpearTrap(addprops, depth, width, -depth/6, width/2.7, nil, nil, nil, nil, true)
        addprops[#addprops + 1] = { name = "pig_ruins_light_beam", x_offset = -depth/6, z_offset = width/2.5, addtags = local_trap_tags}

        AddSpearTrap(addprops, depth, width, -depth/2.7, width/2.7)
        addprops[#addprops + 1] = { name = "pig_ruins_light_beam", x_offset = -depth/2.5, z_offset = width/2.5, addtags = local_trap_tags}
    end

    return addprops
end

PROP_DEFS.pig_ruins_store_room = function(depth, width, exits_open, exits_vined, room, roomtype, dungeondef, exterior_door_def)
    local addprops = PROP_DEFS.pig_ruins_common(depth, width, exits_open, exits_vined, room, roomtype, dungeondef, exterior_door_def)

    for i = 1, math.random(6, 12) do
        local set_width, set_depth = GetSpawnLocation(depth, width, 0.8, 0.8, room.fountain)
        if set_width and set_depth then
            addprops[#addprops + 1] = {name = "smashingpot", x_offset = set_depth, z_offset = set_width}
        end
    end

    return addprops
end

PROP_DEFS.pig_ruins_treasure = function(depth, width, exits_open, exits_vined, room, roomtype, dungeondef, exterior_door_def)
    local addprops = {}

    local setups = {"darts_relics","darts_relics","darts_relics","darts_relics","darts_relics","darts_relics",
    "spears_relics","spears_relics","spears_relics",
    "relics_dust"} -- 亚丹：出于奇怪的私心，我让这些在单机版因为random = 1而没有被启用的房间重新存在生成的可能
    --我暂时将8金子1遗物房间的概率设置为10%，3遗物长矛陷阱房间的概率设置为30%，3遗物吹箭陷阱房间的概率设置为60%
    --然而，关于它们的游戏逻辑需要进一步的讨论
    local random =  math.random(1,#setups)
    -- random = 1 -- 不是，哥们

    if setups[random] == "darts_relics" then
        roomtype = "dart_trap"
        local nopressureplates = true
        addprops = PROP_DEFS.pig_ruins_dart_trap(depth, width, exits_open, exits_vined, room, roomtype, dungeondef, exterior_door_def, nopressureplates)
    else
        if setups[random] == "relics_dust" then
            room.nocornertree = true
        end
        addprops = PROP_DEFS.pig_ruins_common(depth, width, exits_open, exits_vined, room, roomtype, dungeondef, exterior_door_def)
    end

    -- ziwbi: For some reason only relics_dust setup is used
    -- 亚丹：事实上，在单机版只有darts_relics被使用了


    if setups[random] == "relics_dust" then
        AddGoldStatue(addprops, -depth / 3, -width / 3)
        AddGoldStatue(addprops, depth / 3, width / 3)
        AddRelicStatue(addprops, 0, 0)
        AddGoldStatue(addprops, depth / 3, -width / 3)
        AddGoldStatue(addprops, -depth / 3, width / 3)
    elseif setups[random] == "spears_relics" then
        AddRelicStatue(addprops,0,-width/4)
        AddRelicStatue(addprops,0,0)
        AddRelicStatue(addprops,0,width/4)

        AddSpearTrap(addprops, depth, width, 0, -width/4, nil, true, true,12)
        addprops[#addprops + 1] = { name = "pig_ruins_light_beam", x_offset = 0, z_offset =  -width/4, addtags={"localtrap"}}
        AddSpearTrap(addprops, depth, width, 0, 0, nil, true, true, 12)
        addprops[#addprops + 1] = { name = "pig_ruins_light_beam", x_offset = 0, z_offset =  0, addtags={"localtrap"}}
        AddSpearTrap(addprops, depth, width, 0, width/4, nil, true, true, 12)
        addprops[#addprops + 1] = { name = "pig_ruins_light_beam", x_offset = 0, z_offset =  width/4, addtags={"localtrap"}}
    elseif setups[random] == "darts_relics" then
        AddRelicStatue(addprops,0,-width/3 +1, {"trggerdarttraps"})
        AddRelicStatue(addprops,depth/4-1,0, {"trggerdarttraps"})
        AddRelicStatue(addprops,0,width/3 -1, {"trggerdarttraps"})
    end

    return addprops
end

PROP_DEFS.pig_ruins_treasure_aporkalypse = function(depth, width, exits_open, exits_vined, room, roomtype, dungeondef, exterior_door_def)
    local addprops = PROP_DEFS.pig_ruins_common(depth, width, exits_open, exits_vined, room, roomtype, dungeondef, exterior_door_def)

    addprops[#addprops + 1] = {name = "aporkalypse_clock", x_offset = -1, z_offset = 0}

    return addprops
end

PROP_DEFS.pig_ruins_treasure_endswell = function(depth, width, exits_open, exits_vined, room, roomtype, dungeondef, exterior_door_def)
    local addprops = PROP_DEFS.pig_ruins_common(depth, width, exits_open, exits_vined, room, roomtype, dungeondef, exterior_door_def)
    return addprops
end

PROP_DEFS.pig_ruins_treasure_rarerelic = function(depth, width, exits_open, exits_vined, room, roomtype, dungeondef, exterior_door_def)
    local addprops = PROP_DEFS.pig_ruins_common(depth, width, exits_open, exits_vined, room, roomtype, dungeondef, exterior_door_def)

    room.color = "_blue"

    local relic = "pig_ruins_truffle"
    if room.relicsow then
        relic = "pig_ruins_sow"
    end

    local trap_trigger_tag = {"trggerdarttraps"}
    local dart_trap_tag = {"trap_dart"}

    if not exits_open.north and exits_open.south then
        addprops[#addprops + 1] = {name = relic, x_offset = depth / 2 - 2, z_offset = 0, addtags = trap_trigger_tag}
        addprops[#addprops + 1] = {name = "pig_ruins_light_beam", x_offset = depth / 2 - 2, z_offset = 0}
    elseif not exits_open.south and exits_open.north then
        addprops[#addprops + 1] = {name = relic, x_offset = -depth / 2 + 2, z_offset = 0, addtags = trap_trigger_tag}
        addprops[#addprops + 1] = {name = "pig_ruins_light_beam", x_offset = -depth / 2 + 2, z_offset = 0}
    elseif not exits_open.west and exits_open.east then
        addprops[#addprops + 1] = {name = relic, x_offset = 0, z_offset = width / 2 - 2, addtags = trap_trigger_tag}
        addprops[#addprops + 1] = {name = "pig_ruins_light_beam", x_offset = 0, z_offset = width / 2 - 2}
    elseif not exits_open.east and exits_open.west then
        addprops[#addprops + 1] = {name = relic, x_offset = 0, z_offset = -width / 2 + 2, addtags = trap_trigger_tag}
        addprops[#addprops + 1] = {name = "pig_ruins_light_beam", x_offset = 0, z_offset = -width / 2 + 2}
    else
        -- Place it in the middle of the room as a fallback.
        addprops[#addprops + 1] = {name = relic, x_offset = 0, z_offset = 0, addtags = trap_trigger_tag}
        addprops[#addprops + 1] = {name = "pig_ruins_light_beam", x_offset = 0, z_offset = 0}
    end

    for i = 0, 3 do
        for ii = 0, 3 do
            local x = -depth / 2 + i * depth / 4
            local z = -width / 2 + i * width / 4
            if math.random() < 0.6 then
                addprops[#addprops + 1] = {name = "pig_ruins_light_beam", x_offset = x, z_offset = z}
            end
        end
    end

    local function Add4Plates(x, y)
        if math.random() < 0.5 then
            local offset_x = x + depth / 16
            local offset_y = y - width / 16
            if math.abs(offset_x) < depth / 2 and math.abs(offset_y) < width / 2 then
                addprops[#addprops + 1] = {name = "pig_ruins_pressure_plate", x_offset = offset_x, z_offset = offset_y, addtags = dart_trap_tag}
            end
        end

        if math.random() < 0.5 then
            local offset_x = x - depth / 16
            local offset_y = y - width / 16
            if math.abs(offset_x) < depth / 2 and math.abs(offset_y) < width / 2 then
                addprops[#addprops + 1] = {name = "pig_ruins_pressure_plate", x_offset = offset_x, z_offset = offset_y, addtags = dart_trap_tag}
            end
        end

        if math.random()<0.5 then
            local offset_x = x - depth / 16
            local offset_y = y + width / 16
            if math.abs(offset_x) < depth / 2 and math.abs(offset_y) < width / 2 then
                addprops[#addprops + 1] = {name = "pig_ruins_pressure_plate", x_offset = offset_x, z_offset = offset_y, addtags = dart_trap_tag}
            end
        end

        if math.random()<0.5 then
            local offset_x = x + depth / 16
            local offset_y = y + width / 16
            if math.abs(offset_x) < depth / 2 and math.abs(offset_y) < width / 2 then
                addprops[#addprops + 1] = {name = "pig_ruins_pressure_plate", x_offset = offset_x, z_offset = offset_y, addtags = dart_trap_tag}
            end
        end
    end

    if math.random() < 0.5 then
        addprops[#addprops + 1] = {name = "pig_ruins_dart_statue", x_offset = depth / 4, z_offset = width / 4}
        addprops[#addprops + 1] = {name = "pig_ruins_dart_statue", x_offset = -depth / 4, z_offset = -width / 4}
    else
        addprops[#addprops + 1] = {name = "pig_ruins_dart_statue", x_offset = -depth / 4, z_offset = width / 4}
        addprops[#addprops + 1] = {name = "pig_ruins_dart_statue", x_offset = depth / 4, z_offset = -width / 4}
    end

    Add4Plates(depth / 4, width / 4)
    Add4Plates(depth / 4, 0)
    Add4Plates(depth / 4, -width / 4)

    Add4Plates(0, width / 4)
    Add4Plates(0, 0)
    Add4Plates(0, -width / 4)

    Add4Plates(-depth / 4, width / 4)
    Add4Plates(-depth / 4, 0)
    Add4Plates(-depth / 4, -width / 4)

    Add4Plates(-depth / 2, width / 4)
    Add4Plates(-depth / 2, -width / 4)

    Add4Plates(depth / 2, width / 4)
    Add4Plates(depth / 2, -width / 4)

    Add4Plates(depth / 4, width / 2)
    Add4Plates(depth / 4, -width / 2)

    Add4Plates(-depth / 4, -width / 2)
    Add4Plates(-depth / 4, width / 2)

    return addprops
end

PROP_DEFS.pig_ruins_treasure_secret = function(depth, width, exits_open, exits_vined, room, roomtype, dungeondef, exterior_door_def)
    local addprops = PROP_DEFS.pig_ruins_common(depth, width, exits_open, exits_vined, room, roomtype, dungeondef, exterior_door_def)

    local function getitem()
        local items =  {
            redgem = 30,
            bluegem = 20,
            relic_1 = 10,
            relic_2 = 10,
            relic_3 = 10,
            nightsword = 1,
            ruins_bat = 1,
            ruinshat = 1,
            orangestaff = 1,
            armorruins = 1,
            multitool_axe_pickaxe = 1,
        }
        return { {1, weighted_random_choice(items)} }
    end

    if not dungeondef.smallsecret then
        addprops[#addprops + 1] = {name = "shelf_ruins", x_offset = -depth / 7, z_offset = -width / 7, shelfitems = getitem()}
        addprops[#addprops + 1] = {name = "shelf_ruins", x_offset = depth / 7, z_offset = -width / 7, shelfitems = getitem()}
        addprops[#addprops + 1] = {name = "shelf_ruins", x_offset = -depth / 7, z_offset = width / 7, shelfitems = getitem()}
        addprops[#addprops + 1] = {name = "shelf_ruins", x_offset = depth / 7, z_offset = width / 7, shelfitems = getitem()}
    else
        addprops[#addprops + 1] = {name = "shelf_ruins", x_offset = 0, z_offset = -width / 7, shelfitems = getitem()}
        addprops[#addprops + 1] = {name = "shelf_ruins", x_offset = 0, z_offset = width / 7, shelfitems = getitem()}
    end

    return addprops
end

local no_general_decor = {dart_trap = true, spear_trap = true, treasure_rarerelic = true, small_treasure = true,
    treasure = true, treasure_secret = true, treasure_aporkalypse = true, treasure_endswell = true}
local room_creatures  = {
    {
        {name = "bat", x_offset = (math.random()*7) - (7/2), z_offset = (math.random()*13) - (13/2) },
        {name = "bat", x_offset = (math.random()*7) - (7/2), z_offset = (math.random()*13) - (13/2) },
    },
    {
        {name = "bat", x_offset = (math.random()*7) - (7/2), z_offset = (math.random()*13) - (13/2) },
        {name = "bat", x_offset = (math.random()*7) - (7/2), z_offset = (math.random()*13) - (13/2) },
        {name = "bat", x_offset = (math.random()*7) - (7/2), z_offset = (math.random()*13) - (13/2) },
    },
    {
        {name = "scorpion", x_offset = (math.random()*7) - (7/2), z_offset = (math.random()*13) - (13/2) },
        {name = "scorpion", x_offset = (math.random()*7) - (7/2), z_offset = (math.random()*13) - (13/2) },
    },
    {
        {name = "scorpion", x_offset = math.random() * 7 - 7 / 2, z_offset = math.random() * 13 - 13 / 2},
    },
}

PROP_DEFS.pig_ruins_common = function(depth, width, exits_open, exits_vined, room, roomtype, dungeondef, exterior_door_def)
    local addprops = {}

    local addedprops = false

    -- all rooms with 1 exit get creatures
    if exitNumbers(room) == 1 then
        for _, prop in pairs(GetRandomItem(room_creatures)) do
            addprops[#addprops + 1] = prop
        end
        addedprops = true
    end
    -- randomly add creatures otherwise
    if roomtype ~= "treasure_aporkalypse" and not addedprops and math.random() < 0.3 then
        for _, prop in ipairs(GetRandomItem(room_creatures)) do
            addprops[#addprops + 1] = prop
        end
    end

    if room.entrance1 then
        addprops[#addprops + 1] = {
            name = "prop_door",
            x_offset = -depth / 2,
            z_offset = 0,
            animdata = {
                minimapicon = "pig_ruins_exit_int.tex",
                bank = "doorway_ruins",
                build = "pig_ruins_door",
                anim = "day_loop",
                light = true,
                background = true,
            },
            is_exit = true,
            my_door_id = exterior_door_def.target_door_id,
            target_door_id = exterior_door_def.my_door_id,
            rotation = -90,
            angle = 0,
            addtags = {
                "timechange_anims",
                "ruins_exit"
            },
        }
    end

    if room.entrance2 then
        addprops[#addprops + 1] = {
            name = "prop_door",
            x_offset = -depth/2,
            z_offset = 0,
            animdata = {
                minimapicon = "pig_ruins_exit_int.tex",
                bank = "doorway_ruins",
                build = "pig_ruins_door",
                anim = "day_loop",
                light = true,
                background = true,
            },
            is_exit = true,
            my_door_id = dungeondef.name .. "_EXIT2",
            target_door_id = dungeondef.name .. "_ENTRANCE2",
            rotation = -90,
            angle = 0,
            addtags = {
                "timechange_anims",
                "ruins_exit"
            },
        }
    end

    if room.endswell then
        addprops[#addprops + 1] = {name = "deco_ruins_endswell", x_offset = 0, z_offset = 0, rotation = -90}
        room.fountain = true
    end

    if room.pheromonestone then
        addprops[#addprops + 1] = {name = "pheromonestone", x_offset = 0, z_offset = 0}
    end

    -- GENERAL RUINS ROOM ART
    if math.random() < 0.8 or roomtype == "dart_trap" then  -- the wall torches get blocked by the big beams
        addprops[#addprops + 1] = {name = "deco_ruins_cornerbeam"..room.color, x_offset = -depth/2, z_offset =  -width/2, rotation = -90}
        addprops[#addprops + 1] = {name = "deco_ruins_cornerbeam"..room.color, x_offset = -depth/2, z_offset =  width/2, rotation = -90, flip = true}
        addprops[#addprops + 1] = {name = "deco_ruins_cornerbeam"..room.color, x_offset = depth/2, z_offset =  -width/2, rotation = -90}
        addprops[#addprops + 1] = {name = "deco_ruins_cornerbeam"..room.color, x_offset = depth/2, z_offset =  width/2, rotation = -90, flip = true}
    else
        addprops[#addprops + 1] = {name = "deco_ruins_cornerbeam_heavy"..room.color, x_offset = -depth/2, z_offset =  -width/2, rotation = -90}
        addprops[#addprops + 1] = {name = "deco_ruins_cornerbeam_heavy"..room.color, x_offset = -depth/2, z_offset =  width/2, rotation = -90, flip = true}
        addprops[#addprops + 1] = {name = "deco_ruins_beam_heavy"..room.color, x_offset = depth/2, z_offset =  -width/2, rotation = -90}
        addprops[#addprops + 1] = {name = "deco_ruins_beam_heavy"..room.color, x_offset = depth/2, z_offset =  width/2, rotation = -90, flip = true}
    end

    local prop = "deco_ruins_beam" .. (math.random() < 0.2 and "_broken" or "") .. room.color

    addprops[#addprops + 1] = {name = prop, x_offset = -depth / 2, z_offset =  -width / 6, rotation = -90}
    addprops[#addprops + 1] = {name = prop, x_offset = -depth / 2, z_offset =  width / 6, rotation = -90}

    -- Adds fake wall cracks
    if exits_open.north and math.random() < 0.10  then
        addprops[#addprops + 1] = {name = "wallcrack_ruins", x_offset = -depth/2, z_offset = 0, animation = "north_closed", animdata = {anim = "north"}}
        exits_open.north = false
    end
    if exits_open.west and math.random() < 0.10  then
        addprops[#addprops + 1] = {name = "wallcrack_ruins", x_offset = 0, z_offset = -width/2, animation = "west_closed", animdata = {anim = "west"}}
        exits_open.west = false
    end
    if exits_open.east and math.random() < 0.10  then
        addprops[#addprops + 1] = {name = "wallcrack_ruins", x_offset = 0, z_offset = width/2, animation = "east_closed", animdata = {anim = "east"}}
        exits_open.east = false
    end

    if exits_vined.north then
        addprops[#addprops + 1] = { name = "pig_ruins_wall_vines_north", x_offset = -depth/2, z_offset = -width/2 + 0.75}
        addprops[#addprops + 1] = { name = "pig_ruins_wall_vines_north", x_offset = -depth/2, z_offset = -width/3 + 0.75}
        addprops[#addprops + 1] = { name = "pig_ruins_wall_vines_north", x_offset = -depth/2, z_offset = -width/3 - 0.75}
        addprops[#addprops + 1] = { name = "pig_ruins_wall_vines_north", x_offset = -depth/2, z_offset = -width/6 + 0.75}
        addprops[#addprops + 1] = { name = "pig_ruins_wall_vines_north", x_offset = -depth/2, z_offset = -width/6 - 0.75}
        addprops[#addprops + 1] = { name = "pig_ruins_wall_vines_north", x_offset = -depth/2, z_offset = width/6 + 0.75}
        addprops[#addprops + 1] = { name = "pig_ruins_wall_vines_north", x_offset = -depth/2, z_offset = width/6 - 0.75}
        addprops[#addprops + 1] = { name = "pig_ruins_wall_vines_north", x_offset = -depth/2, z_offset = width/3 + 0.75}
        addprops[#addprops + 1] = { name = "pig_ruins_wall_vines_north", x_offset = -depth/2, z_offset = width/3 - 0.75}
        addprops[#addprops + 1] = { name = "pig_ruins_wall_vines_north", x_offset = -depth/2, z_offset = width/2 - 0.75}
    end

    if exits_vined.west then
        addprops[#addprops + 1] = { name = "pig_ruins_wall_vines_east", x_offset = -depth/2 + 0.75, z_offset = -width/2}
        addprops[#addprops + 1] = { name = "pig_ruins_wall_vines_east", x_offset = -depth/3 - 0.75, z_offset = -width/2}
        addprops[#addprops + 1] = { name = "pig_ruins_wall_vines_east", x_offset = -depth/6 - 0.75, z_offset = -width/2}
        addprops[#addprops + 1] = { name = "pig_ruins_wall_vines_east", x_offset = depth/6 + 0.75, z_offset = -width/2}
        addprops[#addprops + 1] = { name = "pig_ruins_wall_vines_east", x_offset = depth/3 - 0.75, z_offset = -width/2}
        addprops[#addprops + 1] = { name = "pig_ruins_wall_vines_east", x_offset = depth/2 - 0.75, z_offset = -width/2}
    end

    if exits_vined.east then
        addprops[#addprops + 1] = { name = "pig_ruins_wall_vines_west", x_offset = -depth/2 + 0.75, z_offset = width/2}
        addprops[#addprops + 1] = { name = "pig_ruins_wall_vines_west", x_offset = -depth/3 - 0.75, z_offset = width/2}
        addprops[#addprops + 1] = { name = "pig_ruins_wall_vines_west", x_offset = -depth/6 - 0.75, z_offset = width/2}
        addprops[#addprops + 1] = { name = "pig_ruins_wall_vines_west", x_offset = depth/6 + 0.75, z_offset = width/2}
        addprops[#addprops + 1] = { name = "pig_ruins_wall_vines_west", x_offset = depth/3 + 0.75, z_offset = width/2}
        addprops[#addprops + 1] = { name = "pig_ruins_wall_vines_west", x_offset = depth/2 - 0.75, z_offset = width/2}
    end

    if roomtype ~= "dart_trap" and roomtype ~= "spear_trap" then
        if math.random() < 0.6 then
            if math.random() < 0.8 then
                addprops[#addprops + 1] = { name = "deco_ruins_pigman_relief"..math.random(3)..room.color, x_offset = -depth/2, z_offset =  -width/6*2, rotation = -90 }
            else
                addprops[#addprops + 1] = { name = "deco_ruins_crack_roots"..math.random(4), x_offset = -depth/2, z_offset =  -width/6*2, rotation = -90 }
            end

            if exits_open.north then
                if math.random()<0.8 then
                    if math.random()<0.1 then
                        addprops[#addprops + 1] = { name = "deco_ruins_pigqueen_relief"..room.color, x_offset = -depth/2, z_offset =  -width/18, rotation = -90, }
                        addprops[#addprops + 1] = { name = "deco_ruins_pigking_relief"..room.color, x_offset = -depth/2, z_offset =  width/18, rotation = -90, }
                    else
                        addprops[#addprops + 1] = { name = "deco_ruins_pigman_relief"..math.random(3)..room.color, x_offset = -depth/2, z_offset =  0, rotation = -90, }
                    end
                else
                    addprops[#addprops + 1] = { name = "deco_ruins_crack_roots"..math.random(4), x_offset = -depth/2, z_offset =  0, rotation = -90, }
                end
            end
            if math.random()<0.8 then
                addprops[#addprops + 1] = { name = "deco_ruins_pigman_relief"..math.random(3)..room.color, x_offset = -depth/2, z_offset =  width/6*2, rotation = -90, }
            else
                addprops[#addprops + 1] = { name = "deco_ruins_crack_roots"..math.random(4), x_offset = -depth/2, z_offset =  width/6*2, rotation = -90, }
            end
        else
            if math.random()< 0.5 then
                addprops[#addprops + 1] = { name = "pig_ruins_torch_wall"..room.color, x_offset = -depth/2, z_offset =  -width/6*2, rotation = -90 }
                if exits_open.north then
                    addprops[#addprops + 1] = { name = "pig_ruins_torch_wall"..room.color, x_offset = -depth/2, z_offset =  0, rotation = -90, }
                end
                addprops[#addprops + 1] = { name = "pig_ruins_torch_wall"..room.color, x_offset = -depth/2, z_offset =  width/6*2, rotation = -90, }

                addprops[#addprops + 1] = { name = "pig_ruins_torch_sidewall"..room.color, x_offset = -depth/3-0.5, z_offset =  -width/2, rotation = -90 }
                if exits_open.west then
                    addprops[#addprops + 1] = { name = "pig_ruins_torch_sidewall"..room.color, x_offset = 0-0.5, z_offset =  -width/2, rotation = -90 }
                end
                addprops[#addprops + 1] = { name = "pig_ruins_torch_sidewall"..room.color, x_offset =  depth/3-0.5, z_offset =  -width/2, rotation = -90 }

                addprops[#addprops + 1] = { name = "pig_ruins_torch_sidewall"..room.color, x_offset = -depth/3-0.5, z_offset =  width/2, rotation = -90, flip=true }
                if exits_open.east then
                    addprops[#addprops + 1] = { name = "pig_ruins_torch_sidewall"..room.color, x_offset = 0-0.5, z_offset =  width/2, rotation = -90, flip=true }
                end
                addprops[#addprops + 1] = { name = "pig_ruins_torch_sidewall"..room.color, x_offset =  depth/3-0.5, z_offset =  width/2, rotation = -90, flip=true }
            end
        end
    end

    if math.random() < 0.1 and roomtype ~= "spear_trap" and not room.nocornertree then
        local flip = math.random() < 0.5 or nil
        addprops[#addprops + 1] = { name = "deco_ruins_corner_tree", x_offset = -depth/2, z_offset = (flip and 1 or -1) * width/2, rotation = -90, flip = flip}
    end

    --RANDOM POTS
    if roomtype ~= "treasure_secret" and roomtype ~= "treasure_aporkalypse" and math.random() < 0.25 then
        for i = 1, math.random(2, 3) do
            local set_width, set_depth = GetSpawnLocation(depth, width, 0.8, 0.8, room.fountain)
            if set_width and set_depth then
                addprops[#addprops + 1] = {name = "smashingpot", x_offset = set_depth, z_offset = set_width}
            end
        end
    end

    local function addroomcolumn(x,z)
        if math.random() <0.2 then
            addprops[#addprops + 1] = { name = "deco_ruins_beam_room_broken"..room.color, x_offset = x, z_offset =  z, rotation = -90 }
        else
            addprops[#addprops + 1] = { name = "deco_ruins_beam_room"..room.color, x_offset = x, z_offset =  z, rotation = -90 }
        end
    end

    -- put in the general decor... may dictate where other things go later, like due to the fountain.
    if not no_general_decor[roomtype] then
        local feature = math.random(8)
        if feature == 1 then
            addroomcolumn(-depth/6, -width/6)
            addroomcolumn( depth/6,  width/6)
            addroomcolumn( depth/6, -width/6)
            addroomcolumn(-depth/6,  width/6)
            room.close_pillars = true
        elseif feature == 2 then
            if roomtype ~= "door_trap" and not room.pheromonestone then
                addprops[#addprops + 1] = { name = "deco_ruins_fountain", x_offset = 0, z_offset =  0, rotation = -90 }
                room.fountain = true
                --fountain = true
            end
            if math.random()<0.5 then
                addroomcolumn(-depth/6,  width/3)
                addroomcolumn( depth/6, -width/3)
                room.wide_pillars = true
            else
                addroomcolumn(-depth/4, width/4)
                addroomcolumn(-depth/4,-width/4)
                addroomcolumn( depth/4,-width/4)
                addroomcolumn( depth/4, width/4)
                room.normal_pillars = true
            end
        elseif feature == 3 then
            addroomcolumn(-depth/4,width/6)
            addroomcolumn(0,width/6)
            addroomcolumn(depth/4,width/6)
            addroomcolumn(-depth/4,-width/6)
            addroomcolumn(0,-width/6)
            addroomcolumn(depth/4,-width/6)
            room.close_pillars = true
        end
    end

    local hangingroots = math.random()
    if hangingroots < 0.3 then

        local function jostle()
            return math.random() - 0.5
        end

        local function flip()
            local test = true
            if math.random()<0.5 then
                test = false
            end
            return test
        end

        local roots_left = {
            { name = "deco_ruins_roots"..math.random(3), x_offset = -depth/2, z_offset =  -width/6 - width/12 + jostle(), rotation = -90,flip=flip() },
            { name = "deco_ruins_roots"..math.random(3), x_offset = -depth/2, z_offset =  -width/6 - width/12*2+ jostle(), rotation = -90,flip=flip() },
            { name = "deco_ruins_roots"..math.random(3), x_offset = -depth/2, z_offset =  -width/6 - width/12*3+ jostle(), rotation = -90,flip=flip() }
        }

        local num = math.random(#roots_left)
        for i = 1, num do
            local choice = math.random(#roots_left)
            addprops[#addprops + 1] = roots_left[choice]
            table.remove(roots_left,choice)
        end

        if exits_open.north then
            local roots_center = {
                { name = "deco_ruins_roots"..math.random(3), x_offset = -depth/2, z_offset =  0 + width/12+ jostle(), rotation = -90,flip=flip() },
                { name = "deco_ruins_roots"..math.random(3), x_offset = -depth/2, z_offset =  0 + jostle(), rotation = -90,flip=flip() },
                { name = "deco_ruins_roots"..math.random(3), x_offset = -depth/2, z_offset =  0 - width/12+ jostle(), rotation = -90,flip=flip() }
            }

            local num = math.random(#roots_center)
            for i = 1, num do
                local choice = math.random(#roots_center)
                addprops[#addprops + 1] = roots_center[choice]
                table.remove(roots_center,choice)
            end
        end

        local roots_right = {
            { name = "deco_ruins_roots"..math.random(3), x_offset = -depth/2, z_offset =  width/6 + width/12+ jostle(), rotation = -90,flip=flip() },
            { name = "deco_ruins_roots"..math.random(3), x_offset = -depth/2, z_offset =  width/6 + width/12*2+ jostle(), rotation = -90,flip=flip() },
            { name = "deco_ruins_roots"..math.random(3), x_offset = -depth/2, z_offset =  width/6 + width/12*3+ jostle(), rotation = -90,flip=flip() }
        }

        local num = math.random(#roots_right)
        for i = 1, num do
            local choice = math.random(#roots_right)
            addprops[#addprops + 1] = roots_right[choice]
            table.remove(roots_right,choice)
        end
    end

    return addprops
end

local EXIT_SHOP_SOUND = "dontstarve_DLC003/common/objects/store/door_close"

PROP_DEFS.pig_shop_academy = function (depth, width, exterior_door_def)
    return {
        {
            name = "prop_door",
            x_offset = 5,
            z_offset = 0,
            animdata = {
                bank = "pig_shop_doormats",
                build = "pig_shop_doormats",
                anim = "idle_giftshop",
                background = true
            },
            is_exit = true,
            my_door_id = exterior_door_def.target_door_id,
            target_door_id = exterior_door_def.my_door_id,
            addtags = {"guard_entrance", "shop_music"},
            usesounds = {EXIT_SHOP_SOUND},
        },

        {name = "deco_roomglow", x_offset = 0, z_offset = 0},
        {name = "pigman_professor_shopkeep", x_offset = -2.3, z_offset = 4, startstate = "desk_pre"},
        {name = "shelf_midcentury", x_offset = -4.5, z_offset = -3.3, shelfitems = {{1, "trinket_1"}, {5, "trinket_2"}, {6, "trinket_3"}}},

        {name = "deco_accademy_beam", x_offset = -5, z_offset = width / 2, flip = true},
        {name = "deco_accademy_beam", x_offset = -5, z_offset = -width / 2},
        {name = "deco_accademy_cornerbeam", x_offset = 4.7, z_offset = width / 2, flip = true},
        {name = "deco_accademy_cornerbeam", x_offset = 4.7, z_offset = -width / 2},
        {name = "swinging_light_floral_bulb", x_offset = -3, z_offset = -0},
        {name = "deco_cityhall_picture1", x_offset = 0, z_offset =  width / 2, flip = true},
        {name = "deco_cityhall_picture2", x_offset = 0, z_offset = -width / 2},
        {name = "deco_accademy_pig_king_painting", x_offset = -5, z_offset = 3, flip = true},
        {name = "deco_accademy_barrier_vert", x_offset = 2, z_offset = -5.5},
        {name = "deco_accademy_vause", x_offset =  2, z_offset = -6.5},
        {name = "deco_accademy_barrier_vert", x_offset = -2, z_offset = -5.5},
        {name = "deco_accademy_graniteblock", x_offset = -2, z_offset = -6.5},
        {name = "deco_accademy_table_books", x_offset = 0, z_offset = -3},
        {name = "deco_accademy_potterywheel_urn", x_offset = -3.5, z_offset = 0},
        {name = "deco_accademy_barrier", x_offset = -2.5, z_offset = 0},

        {name = "shop_buyer", x_offset = 1, z_offset = 0.5, saleitem = {"oinc10", "relic_1", 1}, animation = "idle_stoneslab"},
        {name = "shop_buyer", x_offset = 1.5, z_offset = 3, saleitem = {"oinc10", "relic_2", 1}, animation = "idle_stoneslab"},
        {name = "shop_buyer", x_offset = 2, z_offset = 5.5, saleitem = {"oinc10", "relic_3", 1}, animation = "idle_stoneslab"},
    }
end

PROP_DEFS.pig_shop_antiquities = function (depth, width, exterior_door_def)
    return {
        {
            name = "prop_door",
            x_offset = 5,
            z_offset = 0,
            animdata = {
                bank = "pig_shop_doormats",
                build = "pig_shop_doormats",
                anim = "idle_antiquities",
                background = true
            },
            is_exit = true,
            my_door_id = exterior_door_def.target_door_id,
            target_door_id = exterior_door_def.my_door_id,
            addtags = {"guard_entrance", "shop_music"},
            usesounds = {EXIT_SHOP_SOUND},
        },

        {name = "pigman_collector_shopkeep", x_offset = -3, z_offset = 4, startstate = "desk_pre"},
        {name = "deco_roomglow", x_offset = 0, z_offset = 0},
        {name = "shelf_midcentury", x_offset = -4.5, z_offset = 0, shelfitems = {{1, "trinket_1"}, {5, "trinket_2"}, {6, "trinket_3"}}},
        {name = "shelf_cinderblocks", x_offset = -4.5, z_offset = -5},

        {name = "rug_porcupuss", x_offset = 0, z_offset = 0},

        {name = "deco_antiquities_wallfish", x_offset = -5, z_offset = 3.9},
        {name = "deco_antiquities_cornerbeam", x_offset = -5, z_offset = width / 2, flip = true},
        {name = "deco_antiquities_cornerbeam", x_offset = -5, z_offset = -width / 2},
        {name = "deco_antiquities_cornerbeam2", x_offset = 4.7, z_offset = width / 2, flip = true},
        {name = "deco_antiquities_cornerbeam2", x_offset = 4.7, z_offset = -width / 2},
        {name = "swinging_light_rope_1", x_offset = -3, z_offset = width/6},
        {name = "deco_antiquities_screamcatcher", x_offset =-2, z_offset = -6.5},
        {name = "deco_antiquities_windchime", x_offset = -2, z_offset = 6.5},
        {name = "deco_antiquities_beefalo_side", x_offset = 0, z_offset = width / 2, flip = true},

        {name = "window_round_curtains_nails", x_offset = 0, z_offset = -width / 2},
        {name = "window_round_light", x_offset = 0, z_offset = -width / 2},

        {name = "shop_buyer", x_offset = -2, z_offset = width / 2 - 3, animation = "idle_barrel_dome"},
        {name = "shop_buyer", x_offset = 1.7, z_offset = width / 2 - 2.5, animation = "idle_barrel_dome"},
        {name = "shop_buyer", x_offset = -2, z_offset = 2, animation = "idle_barrel_dome"},
        {name = "shop_buyer", x_offset = 2.9, z_offset = 3, animation = "idle_barrel_dome"},
        {name = "shop_buyer", x_offset = -2, z_offset = -width / 2 + 3, animation = "idle_barrel_dome"},
        {name = "shop_buyer", x_offset = 1.9, z_offset = -width / 2 + 2.5, animation = "idle_barrel_dome"},
        {name = "shop_buyer", x_offset = -2, z_offset = -2, animation = "idle_barrel_dome"},
        {name = "shop_buyer", x_offset = 2.9, z_offset = -3, animation = "idle_barrel_dome"},
    }
end

PROP_DEFS.pig_shop_hatshop = function(depth, width, exterior_door_def)
    return {
        {
            name = "prop_door",
            x_offset = 5,
            z_offset = 0,
            animdata = {
                bank = "pig_shop_doormats",
                build = "pig_shop_doormats",
                anim = "idle_giftshop",
                background = true
            },
            is_exit = true,
            my_door_id = exterior_door_def.target_door_id,
            target_door_id = exterior_door_def.my_door_id,
            addtags = {"guard_entrance", "shop_music"},
            usesounds = {EXIT_SHOP_SOUND}
        },

        {name = "shelf_floating", x_offset = -5,   z_offset = 0, shelfitems={{1,"petals"},{2,"petals"},{3,"petals"}, {4,"cutgrass"}, {5,"cutgrass"},{6,"petals"}} },

        {name = "deco_roomglow", x_offset = 0, z_offset = 0},
        {name = "pigman_hatmaker_shopkeep", x_offset = -3.5, z_offset = 5, startstate = "desk_pre"},

        {name = "shelf_pipe", x_offset = -4.5, z_offset = -3.5},

        {name = "rug_rectangle", x_offset =  0, z_offset = 0, rotation = 90},
        {name = "hat_lamp_side", x_offset =  2, z_offset = -width / 2},
        {name = "wall_mirror", x_offset = -1, z_offset = -width / 2},
        {name = "sewingmachine", x_offset = 4, z_offset = 5.5},
        {name = "hatbox1", x_offset = -2, z_offset = 6.5},
        {name = "hatbox1", x_offset = 4, z_offset = -6.5},
        {name = "hatbox2", x_offset = 4.5, z_offset = -5.75},

        {name = "deco_millinery_cornerbeam2", x_offset = -5, z_offset = -width / 2},
        {name = "deco_millinery_beam3", x_offset = 4.7, z_offset = -width / 2},
        {name = "deco_millinery_beam2", x_offset = 4.7, z_offset = width / 2, flip = true},
        {name = "deco_millinery_cornerbeam3", x_offset = -5, z_offset = width / 2, flip = true},
        {name = "swinging_light_rope_1", x_offset = -3, z_offset = width / 6},

        {name = "window_round_burlap_backwall", x_offset =  -width/2, z_offset = -5 },
        {name = "window_round_light_backwall",  x_offset =  -width/2, z_offset = -5 },
        {name = "window_round_burlap_backwall", x_offset =  -width/2, z_offset =  5 },
        {name = "window_round_light_backwall",  x_offset =  -width/2, z_offset =  5 },

        {name = "hat_lamp_side", x_offset = 0, z_offset = width / 2, flip = true},
        {name = "picture_1", x_offset = -2.5, z_offset = width / 2, flip = true},
        {name = "picture_2", x_offset = 2.5, z_offset = width / 2, flip = true},

        {name = "shop_buyer", x_offset = -1, z_offset = -3.5, animation = "idle_hatbox2"},
        {name = "shop_buyer", x_offset = -1, z_offset = -1, animation = "idle_hatbox4"},
        {name = "shop_buyer", x_offset = -1, z_offset = 1.5, animation = "idle_hatbox2"},
        {name = "shop_buyer", x_offset = 1.5, z_offset = -4.5, animation = "idle_hatbox3"},
        {name = "shop_buyer", x_offset = 1.5, z_offset = -2, animation = "idle_hatbox1"},
        {name = "shop_buyer", x_offset = 1.5, z_offset = 0.5, animation = "idle_hatbox1"},
        {name = "shop_buyer", x_offset = 1.5, z_offset = 3, animation = "idle_hatbox3"},
    }
end

PROP_DEFS.pig_shop_weapons = function(depth, width, exterior_door_def)
    return {
        {
            name = "prop_door",
            x_offset = 5,
            z_offset = 0,
            animdata = {
                bank ="pig_shop_doormats",
                build ="pig_shop_doormats",
                anim = "idle_basic",
                background = true
            },
            is_exit = true,
            my_door_id = exterior_door_def.target_door_id,
            target_door_id = exterior_door_def.my_door_id,
            addtags = {"guard_entrance", "shop_music"},
            usesounds = {EXIT_SHOP_SOUND}
        },

        {name = "shelf_midcentury", x_offset = -4.5, z_offset = 4, shelfitems={{5, "twigs"}, {6, "twigs"}, {3, "twigs"}, {4, "twigs"}}},
        {name = "deco_roomglow", x_offset =  0,    z_offset =  0 },
        {name = "pigman_hunter_shopkeep", x_offset = -3,    z_offset =  0, startstate = "desk_pre" },
        {name = "shield_axes", x_offset = -width/2, z_offset =  0 },

        {name = "rug_porcupuss", x_offset =  0, z_offset = -2, rotation = -90 },
        {name = "rug_fur", x_offset =  2, z_offset =  4, rotation =  90 },
        {name = "rug_catcoon", x_offset = -2, z_offset =  4, rotation =  90 },

        {name = "deco_weapon_beam1", x_offset = -5,   z_offset =  width/2, rotation = -90, flip=true },
        {name = "deco_weapon_beam1", x_offset = -5,   z_offset = -width/2, rotation = -90 },
        {name = "deco_weapon_beam2", x_offset =  4.7, z_offset =  width/2, rotation = -90, flip=true },
        {name = "deco_weapon_beam2", x_offset =  4.7, z_offset = -width/2, rotation = -90 },

        {name = "window_square_weapons", x_offset = 1,  z_offset = -width/2, rotation = -90  },
        {name = "swinging_light_basic_metal", x_offset = -2, z_offset =  -4.5, rotation = -90 },
        {name = "swinging_light_basic_metal", x_offset = -6, z_offset =  3, rotation = -90 },
        {name = "swinging_light_basic_metal", x_offset = 3,  z_offset =  6.5, rotation = -90 },

        {name = "deco_antiquities_beefalo_side", x_offset = -2, z_offset = width/2,  rotation = -90, flip=true },
        {name = "closed_chest", x_offset = 4.5, z_offset = (-width/2)+1.5},
        {name = "deco_displaycase", x_offset = -4,  z_offset = -5.5},
        {name = "deco_displaycase", x_offset = -4,  z_offset = -4},

        {name = "shop_buyer", x_offset =  2.5, z_offset = -2,   saveID = true, animation = "idle_cablespool"},
        {name = "shop_buyer", x_offset = -0.5, z_offset = -2.5, saveID = true, animation = "idle_cablespool"},
        {name = "shop_buyer", x_offset =  1.5, z_offset = -5,   saveID = true, animation = "idle_cablespool"},
        {name = "shop_buyer", x_offset = -1.5, z_offset = -5.5, saveID = true, animation = "idle_cablespool"},
        {name = "shop_buyer", x_offset =  0,   z_offset =  3.5, saveID = true, animation = "idle_cablespool"},
        {name = "shop_buyer", x_offset =  3.5, z_offset =  2.5, saveID = true, animation = "idle_cablespool"},
        {name = "shop_buyer", x_offset =  2.5, z_offset =  5.5, saveID = true, animation = "idle_cablespool"},
    }
end

PROP_DEFS.pig_shop_arcane = function (depth, width, exterior_door_def)
    return {
        {
            name = "prop_door",
            x_offset = 5,
            z_offset = 0,
            animdata = {bank = "pig_shop_doormats", build = "pig_shop_doormats", anim = "idle_florist", background = true},
            is_exit = true,
            my_door_id = exterior_door_def.target_door_id,
            target_door_id = exterior_door_def.my_door_id,
            addtags = {"guard_entrance", "shop_music"},
            usesounds = {EXIT_SHOP_SOUND},
        },

        { name = "pigman_erudite_shopkeep", x_offset = -3,   z_offset = 4, startstate = "desk_pre" },
        { name = "deco_roomglow",           x_offset = 0,    z_offset = 0 },
        { name = "shelf_glass",           x_offset = -4.5, z_offset = -4, rotation=-90, shelfitems={{1,"trinket_1"},{5,"trinket_2"},{6,"trinket_3"}} },
        { name = "deco_arcane_bookshelf",   x_offset = -4.5, z_offset = 0},

        { name = "rug_round",  x_offset = 0, z_offset = 0},
        { name = "containers", x_offset = width/2 - 3, z_offset = -width/2 + 1.5},

        { name = "deco_accademy_cornerbeam", x_offset =  4.7, z_offset =   width/2, rotation = -90, flip=true },
        { name = "deco_accademy_cornerbeam", x_offset =  4.7, z_offset =  -width/2, rotation = -90 },
        { name = "deco_accademy_beam",       x_offset = -5,   z_offset =   width/2, rotation = -90, flip=true },
        { name = "deco_accademy_beam",       x_offset = -5,   z_offset =  -width/2, rotation = -90 },
        { name = "swinging_light_rope_1",    x_offset = -3,   z_offset =   width/6, rotation = -90 },

        { name = "deco_antiquities_screamcatcher", x_offset =-2,    z_offset =  -6.5, rotation = -90 },
        { name = "deco_antiquities_windchime",     x_offset = -2,   z_offset =   6.5, rotation = -90 },

        { name = "deco_antiquities_beefalo_side",  x_offset = 0,    z_offset =  width/2, rotation = -90, flip=true },

        { name = "window_round_arcane",            x_offset = 0,    z_offset = -width/2, rotation = -90  },
        { name = "window_round_light",             x_offset = 0,    z_offset = -width/2, rotation = -90  },

        { name = "shop_buyer", x_offset = -0.5, z_offset =  2.5,  saveID = true, animation="idle_marble"},
        { name = "shop_buyer", x_offset = -0.5, z_offset = -2.5,  saveID = true, animation="idle_marblesilk"},
        { name = "shop_buyer", x_offset =  2.5, z_offset =  2.5,  saveID = true, animation="idle_marble"},
        { name = "shop_buyer", x_offset =  2.5, z_offset = -2.5,  saveID = true, animation="idle_marblesilk"},
        { name = "shop_buyer", x_offset =  0.5, z_offset = (width/2) - 2.5,  saveID = true, animation="idle_marblesilk"},
        { name = "shop_buyer", x_offset =  0.5, z_offset = (-width/2) + 2.5, saveID = true, animation="idle_marble"},
    }
end

PROP_DEFS.pig_shop_florist = function (depth, width, exterior_door_def)
    return {
        { name = "prop_door", x_offset = 5, z_offset = 0,
            animdata = {bank ="pig_shop_doormats", build ="pig_shop_doormats", anim="idle_florist", background=true},
            is_exit = true,
            my_door_id = exterior_door_def.target_door_id, target_door_id = exterior_door_def.my_door_id,
            addtags = {"guard_entrance", "shop_music"},
            usesounds={EXIT_SHOP_SOUND} },

        { name = "pigman_florist_shopkeep", x_offset = -1,   z_offset =  4,    startstate = "desk_pre" },
        { name = "deco_roomglow",           x_offset =  0,   z_offset =  0 },
        { name = "shelf_hutch",           x_offset = -4.5, z_offset = -2.6, shelfitems={{3,"seeds"},{4,"seeds"},{5,"seeds"},{6,"seeds"}} },

        { name = "rug_rectangle", x_offset = -2.3, z_offset = -width/4+1,   rotation = 92},
        { name = "rug_rectangle", x_offset =  1.5, z_offset = -width/4+0.5, rotation = 86},

        { name = "deco_wallpaper_florist_rip1", x_offset = -5,    z_offset =  0 },
        { name = "deco_florist_latice_front",   x_offset = -4.5,  z_offset =  3 },
        { name = "deco_florist_latice_side",    x_offset = 0,     z_offset =  width/2, flip = true},
        { name = "deco_florist_pillar_front",   x_offset = -4.5,  z_offset = -width/2 + 0.8 },
        { name = "deco_florist_pillar_front",   x_offset = -4.5,  z_offset =  width/2 - 0.8 },
        { name = "deco_florist_pillar_side",    x_offset = 4.3,   z_offset = -width/2 },
        { name = "deco_florist_pillar_side",    x_offset = 4.3,   z_offset =  width/2, flip = true },
        { name = "deco_florist_plantholder",    x_offset = 3,     z_offset = -width/2 + 0.8},
        { name = "deco_florist_vines2",         x_offset =  -4.5, z_offset = -5 },
        { name = "deco_florist_vines3",         x_offset =  -3,   z_offset = -width/2 },
        { name = "deco_florist_hangingplant1",  x_offset = -1,    z_offset = -width/2+2.5 },
        { name = "deco_florist_hangingplant2",  x_offset = -1,    z_offset =  width/2-2 },

        { name = "window_round",       x_offset = 0, z_offset = -width/2 },
        { name = "window_round_light", x_offset = 0, z_offset = -width/2 },

        { name = "swinging_light_floral_scallop", x_offset = -2, z_offset =  2 },

        { name = "shop_buyer", x_offset = -2,   z_offset =  (-width/2) + 3.5, animation="idle_cart"},
        { name = "shop_buyer", x_offset =  1.5, z_offset =  (-width/2) + 3,   animation="idle_cart"},
        { name = "shop_buyer", x_offset = -2,   z_offset = -1.5,              animation="idle_traystand"},
        { name = "shop_buyer", x_offset = 1.5, z_offset =  -2,                animation="idle_traystand"},
        { name = "shop_buyer", x_offset = 1.5,  z_offset =  2,                animation="idle_traystand"},
        { name = "shop_buyer", x_offset = 1.5,  z_offset =  (width/2) - 3,    animation="idle_wagon"},
    }
end

PROP_DEFS.pig_shop_hoofspa = function (depth, width, exterior_door_def)
    return {
        {
            name = "prop_door", x_offset = 5,
            z_offset = 0, animdata = {bank ="pig_shop_doormats", build ="pig_shop_doormats", anim="idle_hoofspa", background=true},
            is_exit = true,
            my_door_id = exterior_door_def.target_door_id, target_door_id = exterior_door_def.my_door_id,
            addtags = {"guard_entrance", "shop_music"},
            usesounds={EXIT_SHOP_SOUND}},

        { name = "pigman_beautician_shopkeep", x_offset = -3, z_offset = 3, startstate = "desk_pre" },
        { name = "deco_roomglow",              x_offset = 0,  z_offset = 0 },

        { name = "shelf_marble", x_offset = -4.5, z_offset = -3,  rotation=-90, shelfitems={{3,"petals"},{4,"petals"},{5,"petals"},{6,"petals"}}},

        { name = "deco_marble_cornerbeam",  x_offset = -5,    z_offset = -width/2 },
        { name = "deco_marble_cornerbeam",  x_offset = -5,    z_offset =  width/2,         flip = true },
        { name = "deco_marble_beam",        x_offset =  4.7,  z_offset = -width/2 + 0.3 },
        { name = "deco_marble_beam",        x_offset =  4.7,  z_offset =  width/2 - 0.3,   flip = true  },
        { name = "deco_chaise",             x_offset = -1.4,  z_offset = -3.5 },
        { name = "deco_lamp_hoofspa",       x_offset = -1.9,  z_offset = -5.2 },
        { name = "deco_plantholder_marble", x_offset = -4.6,  z_offset =  (width/2)-2 },
        { name = "deco_valence",            x_offset = -5.01, z_offset =  -width/2 },
        { name = "deco_valence",            x_offset = -5.01, z_offset =  width/2,         flip = true },

        { name = "wall_mirror",                x_offset = -1, z_offset = -width/2 },
        { name = "swinging_light_floral_bulb", x_offset = -2, z_offset = 0 },

        { name = "shop_buyer", x_offset = 2.3,  z_offset =  -4.5,   animation = "idle_cakestand" },
        { name = "shop_buyer", x_offset = 2.3,  z_offset =  -2.6,   animation = "idle_cakestand" },
        { name = "shop_buyer", x_offset = -0.5, z_offset =  0,      animation = "idle_marble" },
        { name = "shop_buyer", x_offset = -0.5, z_offset =  3,      animation = "idle_marble" },
        { name = "shop_buyer", x_offset = 2,    z_offset =  4.4,    animation = "idle_marblesilk" },
    }
end

PROP_DEFS.pig_shop_general = function (depth, width, exterior_door_def)
    return {
        {
            name = "prop_door",
            x_offset = 5,
            z_offset = 0,
            animdata = {
                bank = "pig_shop_doormats",
                build = "pig_shop_doormats",
                anim = "idle_general",
                background = true,
            },
            is_exit = true,
            my_door_id = exterior_door_def.target_door_id, target_door_id = exterior_door_def.my_door_id,
            addtags = {"guard_entrance", "shop_music"},
            usesounds = {EXIT_SHOP_SOUND},
        },

        { name = "pigman_banker_shopkeep", x_offset = -1, z_offset = 4, startstate = "desk_pre" },
        { name = "shelf_wood", x_offset = -4.5, z_offset = -4, shelfitems={{3,"rocks"},{4,"rocks"},{5,"rocks"},{6,"rocks"}} },
        { name = "shelf_wood", x_offset = -4.5, z_offset =  4, shelfitems={{3,"cutgrass"},{4,"cutgrass"},{5,"cutgrass"},{6,"cutgrass"}} },
        { name = "rug_hedgehog", x_offset = -0.2, z_offset =  4, rotation = 90},

        { name = "deco_roomglow",             x_offset =  0, z_offset =  0 },
        { name = "deco_wood_cornerbeam",      x_offset = -5, z_offset = width/2, flip=true },
        { name = "deco_wood_cornerbeam",      x_offset = -5, z_offset = -width/2 },
        { name = "deco_wood_cornerbeam",      x_offset =  5, z_offset =  width/2, flip=true },
        { name = "deco_wood_cornerbeam",      x_offset =  5, z_offset = -width/2,},
        { name = "deco_general_hangingpans",  x_offset =  0, z_offset = -width/2+2},
        { name = "deco_general_hangingscale", x_offset = -2, z_offset =  6 },
        { name = "deco_general_trough",       x_offset =  1, z_offset = -width/2 },
        { name = "deco_general_trough",       x_offset =  3, z_offset = -width/2 },

        { name = "window_round",       x_offset = -2, z_offset = -width/2 },
        { name = "window_round_light", x_offset = -2, z_offset = -width/2 },

        { name = "window_round",       x_offset = 1.5, z_offset = width/2, rotation = 90 },
        { name = "window_round_light", x_offset = 1.5, z_offset = width/2, rotation = 90 },

        { name = "swinging_light_chandalier_candles", x_offset = -1.3, z_offset = 0 },

        { name = "shop_buyer", x_offset = -1.8, z_offset = -4.1, animation="idle_cablespool" },
        { name = "shop_buyer", x_offset = -1.8, z_offset = -1.9, animation="idle_barrel" },
        { name = "shop_buyer", x_offset = -2,   z_offset =  0.3, animation="idle_barrel" },

        { name = "shop_buyer", x_offset = 1.1, z_offset = -4.4,  animation = "idle_barrel" },
        { name = "shop_buyer", x_offset = 1.3, z_offset = -2.2,  animation = "idle_barrel" },
        { name = "shop_buyer", x_offset = 1.1, z_offset =  0,    animation = "idle_cablespool" },

        { name = "shop_buyer", x_offset = 1.5, z_offset = 5,     animation = "idle_barrel" },
        { name = "shop_buyer", x_offset = 1.5, z_offset = 2.5,   animation = "idle_barrel" },
    }
end

PROP_DEFS.pig_shop_produce = function (depth, width, exterior_door_def)
    return {
        {
            name = "prop_door",
            x_offset = 5, z_offset = 0, animdata = {bank ="pig_shop_doormats", build ="pig_shop_doormats", anim="idle_produce", background=true},
            is_exit = true,
            my_door_id = exterior_door_def.target_door_id, target_door_id = exterior_door_def.my_door_id,
            addtags = {"guard_entrance", "shop_music"},
            usesounds={EXIT_SHOP_SOUND} },

        { name = "pigman_storeowner_shopkeep", x_offset = -2.5,         z_offset = 4, startstate = "desk_pre" },
        { name = "rug_rectangle",              x_offset = depth/6+1,    z_offset = width/6+1, rotation =  95},
        { name = "rug_rectangle",              x_offset = -depth/6+1,   z_offset = width/6+1, rotation =  91},
        { name = "rug_rectangle",              x_offset = depth/6+0.5,  z_offset = -width/6,  rotation = -95},
        { name = "rug_rectangle",              x_offset = -depth/6-0.5, z_offset = -width/6,  rotation =  91},

        { name = "deco_roomglow",                 x_offset =  0,       z_offset = 0 },
        { name = "deco_general_hangingscale",     x_offset = -4,       z_offset = 4.7 },
        { name = "deco_produce_stone_cornerbeam", x_offset = -5,       z_offset =  width/2, flip = true },
        { name = "deco_produce_stone_cornerbeam", x_offset = -5,       z_offset = -width/2 },
        { name = "deco_wood_cornerbeam",          x_offset =  5,       z_offset = -width/2, },
        { name = "deco_wood_cornerbeam",          x_offset =  5,       z_offset =  width/2, flip = true },
        { name = "deco_produce_menu_side",        x_offset =  0,       z_offset = -width/2 },
        { name = "deco_produce_menu",             x_offset = -depth/2, z_offset = -width/6 },
        { name = "deco_produce_menu",             x_offset = -depth/2, z_offset =  width/6 },

        { name = "window_round",       x_offset =  depth/6, z_offset = width/2, rotation = 90 },
        { name = "window_round",       x_offset = -depth/6, z_offset = width/2, rotation = 90 },
        { name = "window_round_light", x_offset =  depth/6, z_offset = width/2, rotation = 90 },
        { name = "window_round_light", x_offset = -depth/6, z_offset = width/2, rotation = 90 },

        { name = "swinging_light_pendant_cherries", x_offset = -1, z_offset =  -width/6 },


        { name = "shop_buyer", x_offset = -2.5, z_offset = -4.9, animation = "idle_ice_box" },
        { name = "shop_buyer", x_offset = -2.5, z_offset = -2.7, animation = "idle_ice_box" },
        { name = "shop_buyer", x_offset = -2.8, z_offset = -0.5, animation = "idle_ice_box" },
        { name = "shop_buyer", x_offset = -0.3, z_offset =  2.2, animation = "idle_ice_box" },
        { name = "shop_buyer", x_offset = -0.3, z_offset =  4.4, animation = "idle_ice_box" },
        { name = "shop_buyer", x_offset =  1,   z_offset = -5.1, animation = "idle_ice_box" },
        { name = "shop_buyer", x_offset =  1,   z_offset = -2.7, animation = "idle_ice_box" },
        { name = "shop_buyer", x_offset =  1,   z_offset = -0.5, animation = "idle_ice_box" },
        { name = "shop_buyer", x_offset =  2.7, z_offset =  2.2, animation = "idle_ice_box" },
        { name = "shop_buyer", x_offset =  2.7, z_offset =  4.4, animation = "idle_ice_box" },
        { name = "shop_buyer", x_offset =  4,   z_offset = -4,   animation = "idle_ice_bucket", saleitem={"ice","oinc",1},},
    }
end

PROP_DEFS.pig_shop_deli = function (depth, width, exterior_door_def)
    return {
        { name = "prop_door", x_offset = 5, z_offset = 0, animdata = {bank ="pig_shop_doormats", build ="pig_shop_doormats", anim="idle_deli", background=true},
        is_exit = true,
            my_door_id = exterior_door_def.target_door_id, target_door_id = exterior_door_def.my_door_id,
            addtags = {"guard_entrance", "shop_music"},
            usesounds={EXIT_SHOP_SOUND} },

        { name = "pigman_storeowner_shopkeep", x_offset = -1, z_offset = 4, startstate = "desk_pre" },
        { name = "shelf_fridge", x_offset = -4.5, z_offset = -4, rotation=-90,  shelfitems={{1,"fishmeat_small"},{2,"fishmeat_small"},{3,"bird_egg"},{4,"bird_egg"},{5,"froglegs"},{6,"froglegs"}} },

        { name = "deco_general_hangingscale",     x_offset = -2, z_offset =  4.7 },
        { name = "deco_roomglow",                 x_offset =  0, z_offset =  0 },
        { name = "deco_wood_cornerbeam",          x_offset = -5, z_offset =  width/2, flip = true },
        { name = "deco_wood_cornerbeam",          x_offset = -5, z_offset = -width/2 },
        { name = "deco_wood_cornerbeam",          x_offset =  5, z_offset =  width/2, flip = true },
        { name = "deco_wood_cornerbeam",          x_offset =  5, z_offset = -width/2 },
        { name = "deco_deli_meatrack",            x_offset =  0, z_offset = -width/2+2 },
        { name = "deco_deli_basket",              x_offset =  3, z_offset = -width/2+1 },
        { name = "deco_deli_stove_metal_side",    x_offset = -3, z_offset =  width/2, flip = true },
        { name = "deco_deli_wallpaper_rip_side1", x_offset = -1, z_offset = -width/2 },
        { name = "deco_deli_wallpaper_rip_side2", x_offset =  2, z_offset =  width/2, flip = true },

        { name = "window_round_burlap_backwall", x_offset = -5, z_offset = 2  },
        { name = "window_round_light_backwall",  x_offset = -5, z_offset = 2  },

        { name = "swinging_light_basic_metal", x_offset = -1.3, z_offset = -width/6+0.5 },

        { name = "shop_buyer", x_offset = -1.8, z_offset = -5.1,  animation = "idle_cakestand_dome" },
        { name = "shop_buyer", x_offset = -1.8, z_offset = -2.4,  animation = "idle_cakestand_dome" },
        { name = "shop_buyer", x_offset = -2,   z_offset =  0.3,  animation = "idle_cakestand_dome" },
        { name = "shop_buyer", x_offset = 3.1,  z_offset = -5.4,  animation = "idle_ice_box" },
        { name = "shop_buyer", x_offset = 1,    z_offset = -4.6,  animation = "idle_ice_box" },
        { name = "shop_buyer", x_offset = 2.1,  z_offset = -2,    animation = "idle_ice_bucket" },
        { name = "shop_buyer", x_offset = 2.5,  z_offset = 5,     animation = "idle_fridge_display" },
        { name = "shop_buyer", x_offset = 2.5,  z_offset = 2.5,   animation = "idle_fridge_display" },
    }
end

PROP_DEFS.pig_shop_cityhall = function (depth, width, exterior_door_def)
    return {
        { name = "prop_door", x_offset = 5, z_offset = 0, animdata = {bank ="pig_shop_doormats", build ="pig_shop_doormats", anim="idle_flag", background=true},
            is_exit = true,
            my_door_id = exterior_door_def.target_door_id, target_door_id = exterior_door_def.my_door_id,
            addtags={"guard_entrance"},
            usesounds={EXIT_SHOP_SOUND} },

        { name = "pigman_mayor_shopkeep",    x_offset = -3, z_offset = 4 },
        { name = "deco_roomglow",            x_offset = 0,  z_offset = 0 },

        { name = "deco_cityhall_desk",       x_offset = -1.3,     z_offset =  0 },
        { name = "deco_cityhall_bookshelf",  x_offset = -depth/2, z_offset =  width/3 },
        { name = "deco_cityhall_bookshelf",  x_offset = -depth/2, z_offset = -width/3, flip=true  },

        { name = "deco_cityhall_cornerbeam", x_offset = -4.99, z_offset =  width/2, flip=true },
        { name = "deco_cityhall_cornerbeam", x_offset = -4.99, z_offset = -width/2 },
        { name = "deco_cityhall_pillar",     x_offset =  4.7,  z_offset =  width/2, flip=true },
        { name = "deco_cityhall_pillar",     x_offset =  4.7,  z_offset = -width/2 },

        { name = "deco_cityhall_picture1",   x_offset =  1.3,  z_offset =  width/2, flip=true },
        { name = "deco_cityhall_picture2",   x_offset = -1.3,  z_offset =  width/2, flip=true },

        { name = "rug_hoofprint",            x_offset =  0,    z_offset =  0,    rotation = 90  },

        { name = "rug_cityhall_corners", x_offset = -depth/2, z_offset =  width/2, rotation = 90  },
        { name = "rug_cityhall_corners", x_offset =  depth/2, z_offset =  width/2, rotation = 180 },
        { name = "rug_cityhall_corners", x_offset =  depth/2, z_offset = -width/2, rotation = 270 },
        { name = "rug_cityhall_corners", x_offset = -depth/2, z_offset = -width/2, rotation = 0   },

        { name = "window_round_light_backwall", x_offset = -5,    z_offset = 2 },
        { name = "window_mayorsoffice",         x_offset = -depth/2, z_offset = 0, rotation =  90 },

        { name = "wall_mirror", x_offset = -1, z_offset = -width/2 },

        { name = "shop_buyer", x_offset = 1.75,   z_offset =  width/2-5, saleitem = {"deed","oinc", 50},                  animation = "idle_globe_bar", justsellonce = true},
        { name = "shop_buyer", x_offset = 3.5, z_offset =  width/2-2, saleitem = {"construction_permit", "oinc", 50 }, animation = "idle_globe_bar"  },
        { name = "shop_buyer", x_offset = -1, z_offset =  width/2-2, saleitem = {"demolition_permit",   "oinc", 10 }, animation = "idle_globe_bar"  },

        { name = "shop_buyer", x_offset = 2,   z_offset = -width/2+3, saleitem = {"securitycontract",    "oinc", 10 }, animation = "idle_marble_dome"},
    }
end

PROP_DEFS.pig_shop_cityhall_player = function (depth, width, exterior_door_def)
    return {
        { name = "prop_door", x_offset = 5, z_offset = 0, animdata = {bank ="pig_shop_doormats", build ="pig_shop_doormats", anim="idle_flag", background=true},
        is_exit = true,
            my_door_id = exterior_door_def.target_door_id, target_door_id = exterior_door_def.my_door_id, addtags={"guard_entrance"}, usesounds={EXIT_SHOP_SOUND} },

        { name = "deco_roomglow",            x_offset = 0,  z_offset = 0 },

        { name = "deco_cityhall_desk",       x_offset = -1.3,     z_offset =  0 },
        { name = "deco_cityhall_bookshelf",  x_offset = -depth/2, z_offset =  width/3 },
        { name = "deco_cityhall_bookshelf",  x_offset = -depth/2, z_offset = -width/3, flip=true  },

        { name = "deco_cityhall_cornerbeam", x_offset = -4.99, z_offset =  width/2, flip=true },
        { name = "deco_cityhall_cornerbeam", x_offset = -4.99, z_offset = -width/2 },
        { name = "deco_cityhall_pillar",     x_offset =  4.7,  z_offset =  width/2, flip=true },
        { name = "deco_cityhall_pillar",     x_offset =  4.7,  z_offset = -width/2 },

        { name = "deco_cityhall_picture1",   x_offset =  1.3,  z_offset =  width/2, flip=true },
        { name = "deco_cityhall_picture2",   x_offset = -1.3,  z_offset =  width/2, flip=true },

        { name = "rug_hoofprint",            x_offset =  0,    z_offset =  0,    rotation = 90  },

        { name = "rug_cityhall_corners", x_offset = -depth/2, z_offset =  width/2, rotation = 90  },
        { name = "rug_cityhall_corners", x_offset =  depth/2, z_offset =  width/2, rotation = 180 },
        { name = "rug_cityhall_corners", x_offset =  depth/2, z_offset = -width/2, rotation = 270 },
        { name = "rug_cityhall_corners", x_offset = -depth/2, z_offset = -width/2, rotation = 0   },

        { name = "window_round_light_backwall", x_offset = -5,    z_offset = 2 },
        { name = "window_mayorsoffice",         x_offset = -depth/2, z_offset = 0, rotation =  90 },

        { name = "wall_mirror", x_offset = -1, z_offset = -width/2 },

    }
end

PROP_DEFS.pig_shop_bank = function (depth, width, exterior_door_def)
    return {
        { name = "prop_door", x_offset = 5, z_offset = 0, animdata = {bank ="pig_shop_doormats", build ="pig_shop_doormats", anim="idle_bank", background=true},
        is_exit = true,
            my_door_id = exterior_door_def.target_door_id, target_door_id = exterior_door_def.my_door_id,
            addtags = {"guard_entrance", "shop_music"}, usesounds={EXIT_SHOP_SOUND} },

        { name = "pigman_banker_shopkeep",     x_offset = -2.5,         z_offset = 0, startstate = "desk_pre" },

        { name = "deco_roomglow",            x_offset = 0,  z_offset = 0 },


        { name = "deco_bank_marble_cornerbeam", x_offset = -4.99, z_offset =  width/2, flip=true },
        { name = "deco_bank_marble_cornerbeam", x_offset = -4.99, z_offset = -width/2 },
        { name = "deco_bank_marble_beam",     x_offset =  4.7,  z_offset =  width/2, flip=true },
        { name = "deco_bank_marble_beam",     x_offset =  4.7,  z_offset = -width/2 },

        { name = "deco_bank_clock1_side",   x_offset = -depth/4,  z_offset =  width/2, flip=true },
        { name = "deco_bank_clock2_side",   x_offset = 0,  z_offset =  width/2, flip=true },
        { name = "deco_bank_clock3_side",   x_offset = depth/4,  z_offset =  width/2, flip=true },

        { name = "deco_bank_clock3_side",   x_offset = -depth/4,  z_offset =  -width/2},
        { name = "deco_bank_clock1_side",   x_offset = 0,  z_offset =  -width/2 },
        { name = "deco_bank_clock2_side",   x_offset = depth/4,  z_offset =  -width/2},

        { name = "shop_buyer", x_offset = 2.3,  z_offset = -width/4.5,    animation = "idle_marble_dome", saleitem={"oinc10","oinc",10} },
        { name = "shop_buyer", x_offset = -1.7,  z_offset = -width/4.5,   animation = "idle_marble_dome", saleitem={"oinc100","oinc",100} },
        { name = "shop_buyer", x_offset = -1.7,  z_offset = width/4.5,     animation = "idle_marble_dome", saleitem={"goldnugget","oinc",10} },

        { name = "deco_bank_vault",            x_offset = -depth/2,    z_offset =  0  },

        { name = "deco_accademy_barrier",           x_offset = -3,   z_offset =  -width/4.5 },
        { name = "deco_accademy_barrier",           x_offset = -3,   z_offset =  width/4.5 },
        { name = "deco_accademy_barrier_vert",  x_offset = -2,  z_offset =  -5 },
        { name = "deco_accademy_barrier_vert",  x_offset =  2.3,  z_offset =  -5 },

        { name = "deco_accademy_barrier_vert",  x_offset = -2,  z_offset =  5, flip = true },
        { name = "deco_accademy_barrier_vert",  x_offset =  2.3,  z_offset =  5, flip = true },

        { name = "shelf_displaycase_metal", x_offset = -2, z_offset = -width/2+0.75, rotation = 90, flip = true, shelfitems={{1,"flint"},{2,"rocks"},{3,"flint"}} },
        { name = "shelf_displaycase_metal", x_offset = -2, z_offset = width/2-0.75, rotation = 90, shelfitems={{1,"rocks"},{2,"rocks"},{3,"rocks"}} },
        { name = "shelf_displaycase_metal", x_offset = 2.3, z_offset = -width/2+0.75, rotation = 90, flip = true, shelfitems={{1,"nitre"},{2,"nitre"},{3,"rocks"}} },
        { name = "shelf_displaycase_metal", x_offset = 2.3, z_offset = width/2-0.75, rotation = 90, shelfitems={{1,"rocks"},{2,"charcoal"},{3,"charcoal"}} },

        { name = "swinging_light_bank", x_offset = -1.7, z_offset = -width/4.5 },

        { name = "swinging_light_bank", x_offset = -1.7, z_offset = width/4.5},

    }
end

PROP_DEFS.pig_shop_tinker = function (depth, width, exterior_door_def)
    return {
        {
            name = "prop_door",
            x_offset = 5,
            z_offset = 0,
            animdata = {
                bank = "pig_shop_doormats",
                build = "pig_shop_doormats",
                anim = "idle_tinker",
                background = true
            },
            is_exit = true,
            my_door_id = exterior_door_def.target_door_id,
            target_door_id = exterior_door_def.my_door_id,
            addtags = {"guard_entrance", "shop_music"},
            usesounds = {EXIT_SHOP_SOUND}
        },

        { name = "pigman_mechanic_shopkeep",     x_offset = -2,         z_offset = -3, startstate = "desk_pre" },

        { name = "deco_roomglow",            x_offset = 0,  z_offset = 0 },

        { name = "deco_tinker_cornerbeam", x_offset = -4.99, z_offset =  width/2, flip=true },
        { name = "deco_tinker_cornerbeam", x_offset = -4.99, z_offset = -width/2 },
        { name = "deco_tinker_beam",     x_offset =  4.7,  z_offset =  width/2, flip=true },
        { name = "deco_tinker_beam",     x_offset =  4.7,  z_offset = -width/2 },

        { name = "deco_bank_clock1_side",   x_offset = -depth/4,  z_offset =  width/2, flip=true },
        { name = "deco_bank_clock2_side",   x_offset = 0,  z_offset =  -width/2},

        { name = "shop_buyer", x_offset = 1.3,  z_offset = -width/6 -1.75,     animation = "idle_metal" },
        { name = "shop_buyer", x_offset = 1.3,  z_offset = -1.75,            animation = "idle_metal" },
        { name = "shop_buyer", x_offset = -1.7,  z_offset = width/6 +0.5,     animation = "idle_metal" },
        { name = "shop_buyer", x_offset = -1.7,  z_offset = 0.5,            animation = "idle_metal" },

        { name = "shelf_metal", x_offset = -4.0, z_offset = 4,  rotation=-90, shelfitems={{3,"charcoal"},{4,"nitre"},{5,"papyrus"},{6,"charcoal"}}},

        { name = "window_round_backwall",   x_offset = -depth/2, z_offset = 0 },

        { name = "rug_fur",       x_offset =  -1.5, z_offset =  2, rotation =  100 },
        { name = "rug_fur",       x_offset = 1.5, z_offset =  -3, rotation =  90 },

        { name = "swinging_light_bank", x_offset = -3, z_offset = -width/4.5+0.5 },
        { name = "swinging_light_bank", x_offset = 0, z_offset = width/4.5+2 },

        { name = "deco_rollchest",              x_offset = 4,  z_offset = -5 },
        { name = "deco_worktable",              x_offset = 2.5,  z_offset = 4, rotation=90, flip = true  },
        { name = "deco_filecabinet",            x_offset = -2.5,  z_offset = -width/2 },
        { name = "deco_rollholder",            x_offset = 2,  z_offset = -width/2+0.7 },
        { name = "deco_rollholder",            x_offset = 0,  z_offset = width/2-0.7, rotation=90},
        { name = "deco_rollholder_front",            x_offset = -depth/2+0.3,  z_offset =-4 },
    }
end

PROP_DEFS.pig_palace = function (depth, width, exterior_door_def, togallery_door_def)
    return {
        {
            name = "prop_door",
            x_offset = 9,
            z_offset = 0,
            animdata = {bank = "palace_door", build = "palace_door", anim = "south", background = false},
            is_exit = true,
            my_door_id = exterior_door_def.target_door_id,
            target_door_id = exterior_door_def.my_door_id,
            rotation = -90,
            addtags = {"guard_entrance"},
            usesounds = {EXIT_SHOP_SOUND},
        },

        { name = "prop_door_shadow", x_offset = 9, z_offset = 0, animdata = {bank = "palace_door", build = "palace_door", anim = "south_floor"} },

        { name = "deco_roomglow_large", x_offset = 0, z_offset = 0 },


        {
            name = "prop_door",
            x_offset = 0,
            z_offset = -26 / 2,
            animdata = {bank = "wall_decals_palace", build = "interior_wall_decals_palace", anim = "door_sidewall", background = true},
            my_door_id = togallery_door_def.my_door_id,
            target_door_id = togallery_door_def.target_door_id,
            target_interior = togallery_door_def.target_interior,
            addtags = {"lockable_door","door_west"}
        },

        { name = "deco_palace_beam_room_tall_corner",       x_offset = -18/2, z_offset = -26/2, rotation = 90, flip = true },
        { name = "deco_palace_beam_room_tall_corner",       x_offset = -18/2, z_offset =  26/2, rotation = 90 },
        { name = "deco_palace_beam_room_tall_corner_front", x_offset =  18/2, z_offset = -26/2, rotation = 90, flip = true },
        { name = "deco_palace_beam_room_tall_corner_front", x_offset =  18/2, z_offset =  26/2, rotation = 90 },

        { name = "deco_palace_beam_room_tall", x_offset = -18/2, z_offset = -26/6-1, rotation = 90, flip = true },
        { name = "deco_palace_beam_room_tall", x_offset = -18/2, z_offset =  26/6+1, rotation = 90 },

        { name = "deco_palace_beam_room_tall_lights", x_offset = -18/6, z_offset = -26/6 -1, rotation = 90, flip = true },
        { name = "deco_palace_beam_room_tall_lights", x_offset = -18/6, z_offset =  26/6 +1, rotation = 90 },

        { name = "deco_palace_beam_room_tall_lights", x_offset = 18/6, z_offset = -26/6 -1, rotation = 90, flip = true },
        { name = "deco_palace_beam_room_tall_lights", x_offset = 18/6, z_offset =  26/6 +1, rotation = 90 },

        { name = "deco_palace_banner_big_front", x_offset = -18/6, z_offset = -26/3-0.5, rotation = 90 },
        { name = "deco_palace_banner_big_front", x_offset = -18/6, z_offset =  26/3+0.5, rotation = 90 },
        { name = "deco_palace_banner_big_front", x_offset =  18/6, z_offset = -26/3-0.5, rotation = 90 },
        { name = "deco_palace_banner_big_front", x_offset =  18/6, z_offset =  26/3+0.5, rotation = 90 },

        { name = "deco_palace_banner_small_front", x_offset = -18/2, z_offset = -26/18-3, rotation = 90 },
        { name = "deco_palace_banner_small_front", x_offset = -18/2, z_offset =  26/18+3, rotation = 90 },

        { name = "deco_palace_banner_small_front", x_offset = -18/2, z_offset = -26/18 - 26/3, rotation = 90 },
        { name = "deco_palace_banner_small_front", x_offset = -18/2, z_offset =  26/18 - 26/3, rotation = 90 },

        { name = "deco_palace_banner_small_sidewall", x_offset = -18/14, z_offset = -26/2, rotation = 90, flip = true },
        { name = "deco_palace_banner_small_sidewall", x_offset = -18/14, z_offset =  26/2, rotation = 90 },
        { name = "deco_palace_banner_small_sidewall", x_offset =  18/14, z_offset = -26/2, rotation = 90, flip = true },
        { name = "deco_palace_banner_small_sidewall", x_offset =  18/14, z_offset =  26/2, rotation = 90 },

        { name = "deco_palace_banner_small_sidewall", x_offset = -18/14 * 3, z_offset = -26/2, rotation = 90, flip = true },
        { name = "deco_palace_banner_small_sidewall", x_offset = -18/14 * 3, z_offset =  26/2, rotation = 90 },
        { name = "deco_palace_banner_small_sidewall", x_offset =  18/14 * 3, z_offset = -26/2, rotation = 90, flip = true },
        { name = "deco_palace_banner_small_sidewall", x_offset =  18/14 * 3, z_offset =  26/2, rotation = 90 },

        { name = "deco_palace_banner_small_sidewall", x_offset = -18/14 * 5, z_offset =  -26/2, rotation = 90, flip = true },
        { name = "deco_palace_banner_small_sidewall", x_offset = -18/14 * 5, z_offset =   26/2, rotation = 90 },
        { name = "deco_palace_banner_small_sidewall", x_offset =  18/14 * 5, z_offset =  -26/2, rotation = 90, flip = true },
        { name = "deco_palace_banner_small_sidewall", x_offset =  18/14 * 5, z_offset =   26/2, rotation = 90 },

        { name = "deco_palace_beam_room_tall_corner", x_offset = -18/6, z_offset = -26/2, rotation = 90, flip = true },
        { name = "deco_palace_beam_room_tall_corner", x_offset =  18/6, z_offset = -26/2, rotation = 90, flip = true },
        { name = "deco_palace_beam_room_tall_corner", x_offset = -18/6, z_offset =  26/2, rotation = 90 },
        { name = "deco_palace_beam_room_tall_corner", x_offset =  18/6, z_offset =  26/2, rotation = 90 },

        { name = "deco_palace_plant", x_offset = -18/2 +0.3, z_offset = -26/6.5, rotation = 90, flip = true },
        { name = "deco_palace_plant", x_offset = -18/2 +0.3, z_offset =  26/6.5, rotation = 90 },

        { name = "wall_mirror", x_offset =  18/3, z_offset = -26/2, rotation = -90 },
        { name = "wall_mirror", x_offset = -18/3, z_offset = -26/2, rotation = -90 },

        -- { name = "wall_mirror", x_offset =  18/3, z_offset = 26/2, rotation = 90, flip=true },
        -- { name = "wall_mirror", x_offset = -18/3, z_offset = 26/2, rotation = 90, flip=true },

        { name = "deco_cityhall_picture1", x_offset =  18/3, z_offset = 26/2, rotation = 90 },
        { name = "deco_cityhall_picture2", x_offset =  -0.5, z_offset = 26/2, rotation = 90 },
        { name = "deco_cityhall_picture1", x_offset =  -18/3, z_offset = 26/2, rotation = 90 },

        { name = "pigman_queen",       x_offset = -3, z_offset = 0 },
        { name = "deco_palace_throne", x_offset = -6, z_offset = 0, rotation = 90 },

        -- floor corner pieces
        { name = "rug_palace_corners", x_offset = -18/2, z_offset =  26/2, rotation = 90  },
        { name = "rug_palace_corners", x_offset =  18/2, z_offset =  26/2, rotation = 180 },
        { name = "rug_palace_corners", x_offset =  18/2, z_offset = -26/2, rotation = 270 },
        { name = "rug_palace_corners", x_offset = -18/2, z_offset = -26/2, rotation = 0   },

        -- front wall floor lights
        { name = "swinglightobject", x_offset = 18/2, z_offset = -26/3, rotation = -90 },
        { name = "swinglightobject", x_offset = 18/2, z_offset =  26/3, rotation = -90 },

        -- back wall lights and floor lights
        { name = "window_round_light_backwall", x_offset = -18/2, z_offset = -26/3, rotation = -90 },
        { name = "window_palace",               x_offset = -18/2, z_offset = -26/3, rotation =  90 },
        { name = "window_round_light_backwall", x_offset = -18/2, z_offset =  26/3, rotation = -90 },
        { name = "window_palace",               x_offset = -18/2, z_offset =  26/3, rotation =  90 },
        { name = "window_round_light_backwall", x_offset = -18/2, z_offset =     0, rotation = -90 },
        { name = "window_palace_stainglass",    x_offset = -18/2, z_offset =     0, rotation =  90 },

        -- aisle rug
        { name = "rug_palace_runner", x_offset =   -3.38, z_offset = 0, rotation = 90 },
        { name = "rug_palace_runner", x_offset = -3.38*2, z_offset = 0, rotation = 90 },
        { name = "rug_palace_runner", x_offset =       0, z_offset = 0, rotation = 90 },
        { name = "rug_palace_runner", x_offset =    3.38, z_offset = 0, rotation = 90 },
        { name = "rug_palace_runner", x_offset =  3.38*2, z_offset = 0, rotation = 90 },
    }
end

PROP_DEFS.pig_palace_gallery = function (depth, width, togiftshop_door_def, topalace_door_def)
    return {
        { name = "deco_roomglow", x_offset = 0, z_offset = 0 },

        {
            name = "prop_door",
            x_offset = 0,
            z_offset = -18 / 2,
            animdata = {
                bank = "wall_decals_palace",
                build = "interior_wall_decals_palace",
                anim = "door_sidewall",
                background = true
            },
            my_door_id = togiftshop_door_def.my_door_id,
            target_door_id = togiftshop_door_def.target_door_id,
            target_interior = togiftshop_door_def.target_interior,
            addtags = {"lockable_door", "door_west"}
        },

        {
            name = "prop_door",
            x_offset = 0,
            z_offset = 18 / 2,
            animdata = {
                bank = "wall_decals_palace",
                build = "interior_wall_decals_palace",
                anim = "door_sidewall",
                background = true,
            },
            my_door_id = topalace_door_def.my_door_id,
            target_door_id = topalace_door_def.target_door_id,
            target_interior = topalace_door_def.target_interior,
            flip = true,
            addtags = {"lockable_door","door_east"},
        },

        { name = "rug_palace_corners", x_offset = -12/2, z_offset =  18/2, rotation = 90  },
        { name = "rug_palace_corners", x_offset =  12/2, z_offset =  18/2, rotation = 180 },
        { name = "rug_palace_corners", x_offset =  12/2, z_offset = -18/2, rotation = 270 },
        { name = "rug_palace_corners", x_offset = -12/2, z_offset = -18/2, rotation = 0   },

        { name = "window_round_light_backwall", x_offset = -12/2, z_offset = -18/3, rotation = -90 },
        { name = "window_palace",               x_offset = -12/2, z_offset = -18/3, rotation =  90 },
        { name = "window_round_light_backwall", x_offset = -18/2, z_offset =  26/3, rotation = -90 },
        { name = "window_palace",               x_offset = -12/2, z_offset =  18/3, rotation =  90 },

        { name = "deco_palace_beam_room_tall_corner",       x_offset = -12/2, z_offset =  -18/2, rotation = 90, flip = true },
        { name = "deco_palace_beam_room_tall_corner",       x_offset = -12/2, z_offset =   18/2, rotation = 90 },
        { name = "deco_palace_beam_room_tall_corner_front", x_offset =  12/2, z_offset =  -18/2, rotation = 90, flip = true },
        { name = "deco_palace_beam_room_tall_corner_front", x_offset =  12/2, z_offset =   18/2, rotation = 90 },

        { name = "deco_palace_beam_room_tall", x_offset = -12/6, z_offset =  -18/6, rotation = 90, flip = true },
        { name = "deco_palace_beam_room_tall", x_offset = -12/6, z_offset =  18/6, rotation = 90 },

        { name = "deco_palace_beam_room_tall", x_offset = 12/6, z_offset =  -18/6, rotation = 90, flip = true },
        { name = "deco_palace_beam_room_tall", x_offset = 12/6, z_offset =  18/6, rotation = 90 },


        { name = "shelf_queen_display_1", x_offset = -12/4, z_offset =  -18/3, rotation = 90, shelfitems={{1,"key_to_city"}} },
        { name = "shelf_queen_display_2", x_offset =     0, z_offset =      0, rotation = 90, shelfitems={{1,"trinket_giftshop_4"}} },
        { name = "shelf_queen_display_3", x_offset = -12/4, z_offset =   18/3, rotation = 90, flip = true, shelfitems={{1,"city_hammer"}} },
        --{ name = "shelf_queen_display_1", x_offset =  12/4, z_offset =  -18/3, rotation = 90, flip = true, shelfitems={{1,"trinket_giftshop_3"}} },
        --{ name = "shelf_queen_display_4", x_offset =  12/4, z_offset =   18/3, rotation = 90, flip = true, shelfitems={{1,"trinket_giftshop_3"}} },

       -- { name = "shop_buyer", x_offset = -12/4, z_offset =  -18/3,  saveID = true, animation = "lock19_east" },
       -- { name = "shop_buyer", x_offset =     0, z_offset =      0,  saveID = true, animation = "lock17_east" },
       -- { name = "shop_buyer", x_offset = -12/4, z_offset =   18/3,  saveID = true, animation = "lock12_west" },
       -- { name = "shop_buyer", x_offset =  12/4, z_offset =  -18/3,  saveID = true, animation = "lock19_east" },
       -- { name = "shop_buyer", x_offset =  12/4, z_offset =   18/3,  saveID = true, animation = "lock12_west" },

        { name = "deco_palace_banner_small_sidewall", x_offset = -12/14 * 3, z_offset =  -18/2, rotation = 90, flip = true },
        { name = "deco_palace_banner_small_sidewall", x_offset = -12/14 * 3, z_offset =   18/2, rotation = 90 },
        { name = "deco_palace_banner_small_sidewall", x_offset =  12/14 * 3, z_offset =  -18/2, rotation = 90, flip = true },
        { name = "deco_palace_banner_small_sidewall", x_offset =  12/14 * 3, z_offset =   18/2, rotation = 90 },

        { name = "shelf_marble", x_offset = -12/2, z_offset = 0, shelfitems={{5,"trinket_20"},{6,"trinket_14"},{3,"trinket_4"},{4,"trinket_2"}}  },
    }
end

PROP_DEFS.pig_palace_giftshop = function (depth, width, toexit_door_def, togallery_door_def)
    return {
        { name = "deco_roomglow", x_offset = 0, z_offset = 0 },

        {
            name = "prop_door",
            x_offset = 10 / 2,
            z_offset = 0,
            animdata = {bank = "pig_shop_doormats", build = "pig_shop_doormats", anim = "idle_giftshop", background = true },
            is_exit = true,
            my_door_id = toexit_door_def.my_door_id,
            target_door_id = toexit_door_def.target_door_id,
            target_exterior = toexit_door_def.target_exterior,
            rotation = -90,
            addtags = {"guard_entrance"},
            usesounds = {EXIT_SHOP_SOUND},
        },

        {
            name = "prop_door",
            x_offset = 0,
            z_offset = 15 / 2,
            animdata = {bank = "wall_decals_palace", build = "interior_wall_decals_palace", anim = "door_sidewall", background = true },
            my_door_id = togallery_door_def.my_door_id,
            target_door_id = togallery_door_def.target_door_id,
            target_interior = togallery_door_def.target_interior,
            flip = true,
            addtags = {"lockable_door", "door_east"}
        },

        { name = "rug_palace_corners", x_offset = -10/2, z_offset =  15/2, rotation = 90  },
        { name = "rug_palace_corners", x_offset =  10/2, z_offset =  15/2, rotation = 180 },
        { name = "rug_palace_corners", x_offset =  10/2, z_offset = -15/2, rotation = 270 },
        { name = "rug_palace_corners", x_offset = -10/2, z_offset = -15/2, rotation = 0   },

        { name = "deco_palace_beam_room_short_corner_lights",       x_offset = -10/2, z_offset =  -15/2, rotation = 90, flip = true },
        { name = "deco_palace_beam_room_short_corner_lights",       x_offset = -10/2, z_offset =   15/2, rotation = 90 },
        { name = "deco_palace_beam_room_short_corner_front_lights", x_offset =  10/2, z_offset =  -15/2, rotation = 90, flip = true },
        { name = "deco_palace_beam_room_short_corner_front_lights", x_offset =  10/2, z_offset =   15/2, rotation = 90 },

        { name = "deco_cityhall_picture2", x_offset = -10/5, z_offset = -15/2, rotation = 90, flip = true },
        { name = "deco_cityhall_picture1", x_offset =  10/5, z_offset = -15/2, rotation = 90, flip = true },

        { name = "shelf_wood", x_offset = -10/2, z_offset = -15/5, rotation =- 90, shelfitems={{1,"trinket_giftshop_3"},{2,"trinket_giftshop_3"},{3,"trinket_giftshop_3"},{5,"trinket_giftshop_3"},{6,"trinket_giftshop_3"}} },
        { name = "shelf_wood", x_offset = -10/2, z_offset =  15/5, rotation =- 90, shelfitems={{1,"trinket_giftshop_3"},{3,"trinket_giftshop_3"},{4,"trinket_giftshop_3"},{5,"trinket_giftshop_3"},{6,"trinket_giftshop_3"}} },

        { name = "swinging_light_floral_bloomer", x_offset = 0, z_offset = 0 },

        { name = "shelf_displaycase_wood", x_offset = -10/5, z_offset = -15/3, rotation = 90, flip = true, shelfitems={{1,"trinket_giftshop_1"},{2,"trinket_giftshop_1"},{3,"trinket_giftshop_1"}} },
        { name = "shelf_displaycase_wood", x_offset =  10/5, z_offset =  15/3, rotation = 90,              shelfitems={{1,"trinket_giftshop_1"},{3,"trinket_giftshop_1"}} },
        { name = "shelf_displaycase_wood", x_offset =  10/5, z_offset = -15/3, rotation = 90, flip = true, shelfitems={{2,"trinket_giftshop_1"},{3,"trinket_giftshop_1"}} },
        { name = "shelf_displaycase_wood", x_offset = -10/5, z_offset =  15/3, rotation = 90,              shelfitems={{1,"trinket_giftshop_1"},{2,"trinket_giftshop_1"}} },
    }
    -- if not Profile:IsCharacterUnlocked("wilba") then
    --     table.insert(addprops, { name = "grounded_wilba", x_offset = 0, z_offset = 0 })
    -- end
end

PROP_DEFS.playerhouse_city = function(exterior_door_def)
    return {
        {
            name = "prop_door",
            x_offset = 5,
            z_offset = 0,
            animdata = {bank ="pig_shop_doormats", build ="pig_shop_doormats", anim="idle_old", background=true},
            my_door_id = exterior_door_def.target_door_id,
            target_door_id = exterior_door_def.my_door_id,
            addtags={"guard_entrance"},
            usesounds={EXIT_SHOP_SOUND},
            is_exit = true,
        },

        { name = "deco_roomglow", x_offset = 0, z_offset = 0 },

        { name = "shelf_cinderblocks",      x_offset = -4.5, z_offset = -15/3.5, rotation= -90, addtags={"playercrafted"} },
        { name = "deco_antiquities_wallfish", x_offset = -5,   z_offset =  3.9,    rotation = 90, addtags={"playercrafted"} },

        { name = "deco_antiquities_cornerbeam",  x_offset = -5,  z_offset =  -15/2, rotation =  90, flip=true, addtags={"playercrafted"} },
        { name = "deco_antiquities_cornerbeam",  x_offset = -5,  z_offset =   15/2, rotation =  90,            addtags={"playercrafted"} },
        { name = "deco_antiquities_cornerbeam2", x_offset = 4.7, z_offset =  -15/2, rotation =  90, flip=true, addtags={"playercrafted"} },
        { name = "deco_antiquities_cornerbeam2", x_offset = 4.7, z_offset =   15/2, rotation =  90,            addtags={"playercrafted"} },
        { name = "swinging_light_rope_1",        x_offset = -2,  z_offset =  0,     rotation = -90,            addtags={"playercrafted"} },

        { name = "charcoal", x_offset = -3, z_offset = -2 },
        { name = "charcoal", x_offset =  2, z_offset =  3 },

        { name = "window_round_curtains_nails", x_offset = 0, z_offset = 15/2, rotation = 90, addtags={"playercrafted"} },
    }
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
                background = true,
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
        addprops[#addprops + 1] = {name = "deco_cave_ceiling_trim", x_offset = -height / 2, z_offset = GetPosToCenter(width * 0.6, 3, true)}
    end

    for i = 1, math.random(2, 5) do
        addprops[#addprops + 1] = {name = "cave_fern", x_offset = GetPosToCenter(height * 0.7, 3, true), z_offset = GetPosToCenter(width * 0.7, 3, true)}
    end

    for _, prefab in pairs({"red_mushroom", "blue_mushroom", "green_mushroom"}) do
        for i = 1, math.random(0, 2) do
            addprops[#addprops + 1] = {name = prefab, x_offset = GetPosToCenter(height * 0.8, 3, true), z_offset = GetPosToCenter(width * 0.8, 3, true)}
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
