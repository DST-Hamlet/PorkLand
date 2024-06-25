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
    local setwidth = width*widthrange * math.random() - width*widthrange/2
    local setdepth = depth*depthrange * math.random() - depth*depthrange/2
    local place = true
    if fountain then
        -- filters out thigns that would place where the fountain is
        if  math.abs(setwidth * setwidth) + math.abs(setdepth * setdepth) < 4*4 then
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

PROP_DEFS.pig_ruins_dart_trap = function(depth, width, exits_open, exits_vined, room, roomtype, dungeondef)
    local addprops, entranceRoom, exitRoom = PROP_DEFS.pig_ruins_common(depth, width, exits_open, exits_vined, room, roomtype, dungeondef)

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
    -- if the treasure room wants dart traps, then the plates get turned off.
    --if not nopressureplates then
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
    --end

    return addprops, entranceRoom, exitRoom
end

PROP_DEFS.pig_ruins_door_trap = function(depth, width, exits_open, exits_vined, room, roomtype, dungeondef)
    local addprops, entranceRoom, exitRoom = PROP_DEFS.pig_ruins_common(depth, width, exits_open, exits_vined, room, roomtype, dungeondef)

    local setups = {"default","default","default","hor","vert"}

    if dungeondef.deepruins then
        if exits_open.north or exits_open.south then
            table.insert(setups, "longhor")
        end
        if exits_open.east or exits_open.west then
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

    return addprops, entranceRoom, exitRoom
end

PROP_DEFS.pig_ruins_grown_over = function(depth, width, exits_open, exits_vined, room, roomtype, dungeondef)
    local addprops, entranceRoom, exitRoom = PROP_DEFS.pig_ruins_common(depth, width, exits_open, exits_vined, room, roomtype, dungeondef)

    addprops[#addprops + 1] = {name = "lightrays", x_offset = 0, z_offset = 0}

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

    return addprops, entranceRoom, exitRoom
end

PROP_DEFS.pig_ruins_small_treasure = function(depth, width, exits_open, exits_vined, room, roomtype, dungeondef)
    local addprops, entranceRoom, exitRoom = PROP_DEFS.pig_ruins_common(depth, width, exits_open, exits_vined, room, roomtype, dungeondef)

    if math.random() < 0.5 then
        AddGoldStatue(addprops, 0, -width / 6)
        AddGoldStatue(addprops, 0, width / 6)
    else
        AddRelicStatue(addprops, 0, 0)
    end

    return addprops, entranceRoom, exitRoom
end

PROP_DEFS.pig_ruins_snake = function(depth, width, exits_open, exits_vined, room, roomtype, dungeondef)
    local addprops, entranceRoom, exitRoom = PROP_DEFS.pig_ruins_common(depth, width, exits_open, exits_vined, room, roomtype, dungeondef)

    for i = 1, math.random(3, 6) do
        addprops[#addprops + 1] = {
            name = "snake_amphibious",
            x_offset =  depth * 0.8 * math.random() - depth * 0.4,
            z_offset =  width * 0.8 * math.random() - width * 0.4,
        }
    end

    return addprops, entranceRoom, exitRoom
end

PROP_DEFS.pig_ruins_spear_trap = function(depth, width, exits_open, exits_vined, room, roomtype, dungeondef)
    local addprops, entranceRoom, exitRoom = PROP_DEFS.pig_ruins_common(depth, width, exits_open, exits_vined, room, roomtype, dungeondef)

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

        for i=1, math.random(1,3)do
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

    return addprops, entranceRoom, exitRoom
end

PROP_DEFS.pig_ruins_store_room = function(depth, width, exits_open, exits_vined, room, roomtype, dungeondef)
    local addprops, entranceRoom, exitRoom = PROP_DEFS.pig_ruins_common(depth, width, exits_open, exits_vined, room, roomtype, dungeondef)

    for i = 1, math.random(6, 12) do
        local set_width, set_depth = GetSpawnLocation(depth, width, 0.8, 0.8, room.fountain)
        if set_width and set_depth then
            addprops[#addprops + 1] = {name = "smashingpot", x_offset = set_depth, z_offset = set_width}
        end
    end

    return addprops, entranceRoom, exitRoom
end

PROP_DEFS.pig_ruins_treasure = function(depth, width, exits_open, exits_vined, room, roomtype, dungeondef)
    local addprops, entranceRoom, exitRoom = PROP_DEFS.pig_ruins_common(depth, width, exits_open, exits_vined, room, roomtype, dungeondef)

    -- ziwbi: For some reason only relics_dust setup is used

    -- local setups = {"darts_relics","spears_relics", "relics_dust"}
    -- local random =  math.random(1,#setups)
    -- random = 1
    -- if setups[random] == "relics_dust" then
        AddGoldStatue(addprops, -depth / 3, -width / 3)
        AddGoldStatue(addprops, depth / 3, width / 3)
        AddRelicStatue(addprops, 0, 0)
        AddGoldStatue(addprops, depth / 3, -width / 3)
        AddGoldStatue(addprops, -depth / 3, width / 3)
    -- elseif setups[random] == "spears_relics" then
    --     AddRelicStatue(addprops,0,-width/4)
    --     AddRelicStatue(addprops,0,0)
    --     AddRelicStatue(addprops,0,width/4)

    --     AddSpearTrap(addprops, depth, width, 0, -width/4, nil, true, true,12)
    --     addprops[#addprops + 1] = { name = "pig_ruins_light_beam", x_offset = 0, z_offset =  -width/4, addtags={"localtrap"}}
    --     AddSpearTrap(addprops, depth, width, 0, 0, nil, true, true, 12)
    --     addprops[#addprops + 1] = { name = "pig_ruins_light_beam", x_offset = 0, z_offset =  0, addtags={"localtrap"}}
    --     AddSpearTrap(addprops, depth, width, 0, width/4, nil, true, true, 12)
    --     addprops[#addprops + 1] = { name = "pig_ruins_light_beam", x_offset = 0, z_offset =  width/4, addtags={"localtrap"}}
    -- elseif setups[random] == "darts_relics" then
    --     AddRelicStatue(addprops,0,-width/3 +1, {"trggerdarttraps"})
    --     AddRelicStatue(addprops,depth/4-1,0, {"trggerdarttraps"})
    --     AddRelicStatue(addprops,0,width/3 -1, {"trggerdarttraps"})
    --     roomtype = "darts"
    --     nopressureplates = true
    -- end

    return addprops, entranceRoom, exitRoom
end

PROP_DEFS.pig_ruins_treasure_aporkalypse = function(depth, width, exits_open, exits_vined, room, roomtype, dungeondef)
    local addprops, entranceRoom, exitRoom = PROP_DEFS.pig_ruins_common(depth, width, exits_open, exits_vined, room, roomtype, dungeondef)

    addprops[#addprops + 1] = {name = "aporkalypse_clock", x_offset = -1, z_offset = 0}

    return addprops, entranceRoom, exitRoom
end

PROP_DEFS.pig_ruins_treasure_endswell = function(depth, width, exits_open, exits_vined, room, roomtype, dungeondef)
    local addprops, entranceRoom, exitRoom = PROP_DEFS.pig_ruins_common(depth, width, exits_open, exits_vined, room, roomtype, dungeondef)
    return addprops, entranceRoom, exitRoom
end

PROP_DEFS.pig_ruins_treasure_rarerelic = function(depth, width, exits_open, exits_vined, room, roomtype, dungeondef)
    local addprops, entranceRoom, exitRoom = PROP_DEFS.pig_ruins_common(depth, width, exits_open, exits_vined, room, roomtype, dungeondef)

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

    return addprops, entranceRoom, exitRoom
end

PROP_DEFS.pig_ruins_treasure_secret = function(depth, width, exits_open, exits_vined, room, roomtype, dungeondef)
    local addprops, entranceRoom, exitRoom = PROP_DEFS.pig_ruins_common(depth, width, exits_open, exits_vined, room, roomtype, dungeondef)

    local function getitem()
        local items =  {
            redgem =30,
            bluegem =20,
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
        return weighted_random_choice(items)
    end

    if not dungeondef.smallsecret then
        addprops[#addprops + 1] = {name = "shelves_ruins", x_offset = -depth / 7, z_offset = -width / 7, shelfitems = {{1, getitem()}}}
        addprops[#addprops + 1] = {name = "shelves_ruins", x_offset = depth / 7, z_offset = -width / 7, shelfitems = {{1, getitem()}}}
        addprops[#addprops + 1] = {name = "shelves_ruins", x_offset = -depth / 7, z_offset = width / 7, shelfitems = {{1, getitem()}}}
        addprops[#addprops + 1] = {name = "shelves_ruins", x_offset = depth / 7, z_offset = width / 7, shelfitems = {{1, getitem()}}}
    else
        addprops[#addprops + 1] = {name = "shelves_ruins", x_offset = 0, z_offset = -width / 7, shelfitems = {{1, getitem()}}}
        addprops[#addprops + 1] = {name = "shelves_ruins", x_offset = 0, z_offset = width / 7, shelfitems = {{1, getitem()}}}
    end

    return addprops, entranceRoom, exitRoom
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

PROP_DEFS.pig_ruins_common = function(depth, width, exits_open, exits_vined, room, roomtype, dungeondef)
    local addprops = {}

    local addedprops = false

    local entranceRoom
    local exitRoom

    -- all rooms with 1 exit get creatures
    if exitNumbers(room) == 1 then
        for _, prop in pairs(GetRandomItem(room_creatures)) do
            addprops[#addprops + 1] = prop
        end
        addedprops = true
    end
    -- randomly add creatures otherwise
    if not addedprops and math.random() < 0.3 then
        for _, prop in ipairs(GetRandomItem(room_creatures)) do
            addprops[#addprops + 1] = prop
        end
    end

    if room.entrance1 then
        width = 24
        depth = 16
        addprops[#addprops + 1] = {
            name = "prop_door",
            x_offset = -depth/2,
            z_offset = 0,
            animdata = {
                minimapicon = "pig_ruins_exit_int.png",
                bank = "doorway_ruins",
                build = "pig_ruins_door",
                anim = "day_loop",
                light = true
            },
            my_door_id = dungeondef.name.."_EXIT1",
            target_door_id = dungeondef.name.."_ENTRANCE1",
            rotation = -90,
            angle=0,
            addtags = {
                "timechange_anims",
                "ruins_entrance"
            },
        }
        entranceRoom = room
    end

    if room.entrance2 then
        width = 24
        depth = 16
        addprops[#addprops + 1] = {
            name = "prop_door",
            x_offset = -depth/2,
            z_offset = 0,
            animdata = {
                minimapicon = "pig_ruins_exit_int.png",
                bank = "doorway_ruins",
                build = "pig_ruins_door",
                anim = "day_loop",
                light = true
            },
            my_door_id = dungeondef.name.."_EXIT2",
            target_door_id = dungeondef.name.."_ENTRANCE2",
            rotation = -90,
            angle=0,
            addtags = {
                "timechange_anims",
                "ruins_entrance"
            },
        }
        exitRoom = room
    end

    if room.endswell then
        width = 24
        depth = 16
        addprops[#addprops + 1] = {name = "deco_ruins_endswell", x_offset = 0, z_offset = 0, rotation = -90}
        room.fountain = true
    end

    if room.pheromonestone then
        width = 24
        depth = 16
        addprops[#addprops + 1] = {name = "pheromonestone", x_offset = 0, z_offset = 0}
    end

    -- GENERAL RUINS ROOM ART
    if math.random() < 0.8 or roomtype == "darts" then  -- the wall torches get blocked by the big beams
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

    addprops[#addprops + 1] = {name = prop, x_offset = -depth/2, z_offset =  -width/6, rotation = -90}
    addprops[#addprops + 1] = {name = prop, x_offset = -depth/2, z_offset =  width/6, rotation = -90}

    -- Adds fake wall cracks
    if exits_open.north and math.random() < 0.10  then
        addprops[#addprops + 1] = {name = "wallcrack_ruins", x_offset = -depth/2, z_offset = 0, startAnim = "north_closed", animdata = {anim = "north"}}
        exits_open.north = false
    end
    if exits_open.west and math.random() < 0.10  then
        addprops[#addprops + 1] = {name = "wallcrack_ruins", x_offset = 0, z_offset = -width/2, startAnim = "east_closed", animdata = {anim = "east"}}
        exits_open.west = false
    end
    if exits_open.east and math.random() < 0.10  then
        addprops[#addprops + 1] = {name = "wallcrack_ruins", x_offset = 0, z_offset = width/2, startAnim = "west_closed", animdata = {anim = "west"}}
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

    if roomtype ~= "darts" and roomtype ~= "spears" then
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
                local tags = nil

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

    if math.random() < 0.1 and roomtype ~= "spears" then
        local flip = math.random() < 0.5 or nil
        addprops[#addprops + 1] = { name = "deco_ruins_corner_tree", x_offset = -depth/2, z_offset = (flip and -1 or 1) * width/2, rotation = -90, flip = flip}
    end

    --RANDOM POTS
    if roomtype ~= "secret" and roomtype ~= "aporkalypse" and math.random() < 0.25 then
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
        elseif feature == 2 then
            if roomtype ~= "door_trap" and not room.pheromonestone then
                addprops[#addprops + 1] = { name = "deco_ruins_fountain", x_offset = 0, z_offset =  0, rotation = -90 }
                room.fountain = true
                --fountain = true
            end
            if math.random()<0.5 then
                addroomcolumn(-depth/6,  width/3)
                addroomcolumn( depth/6, -width/3)
            else
                addroomcolumn(-depth/4, width/4)
                addroomcolumn(-depth/4,-width/4)
                addroomcolumn( depth/4,-width/4)
                addroomcolumn( depth/4, width/4)
            end
        elseif feature == 3 then
            addroomcolumn(-depth/4,width/6)
            addroomcolumn(0,width/6)
            addroomcolumn(depth/4,width/6)
            addroomcolumn(-depth/4,-width/6)
            addroomcolumn(0,-width/6)
            addroomcolumn(depth/4,-width/6)
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
        for i=1,num do
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
            for i=1,num do
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
        for i=1,num do
            local choice = math.random(#roots_right)
            addprops[#addprops + 1] = roots_right[choice]
            table.remove(roots_right,choice)
        end
    end

    return addprops, entranceRoom, exitRoom
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
