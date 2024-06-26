local GenerateProps = require("prefabs/interior_prop_defs")

local PIG_RUINS_WIDTH = 24
local PIG_RUINS_DEPTH = 16
local PIG_RUINS_FLOOR_TEXTURE = "levels/textures/interiors/ground_ruins_slab.tex"
local PIG_RUINS_WALL_TEXTURE = "levels/textures/interiors/pig_ruins_panel.tex"
local PIG_RUINS_MINIMAP_TEXTURE = "levels/textures/map_interior/mini_ruins_slab.tex"
local PIG_RUINS_FLOOR_TEXTURE_BLUE = "levels/textures/interiors/ground_ruins_slab_blue.tex"
local PIG_RUINS_WALL_TEXTURE_BLUE = "levels/textures/interiors/pig_ruins_panel_blue.tex"
local PIG_RUINS_COLOUR_CUBE = "images/colour_cubes/pigshop_interior_cc.tex"
local PIG_RUINS_CAVE_REVERB = "ruins"
local PIG_RUINS_CAVE_AMBIENT = WORLD_TILES.RUINS
local PIG_RUINS_CAVE_GROUND_SOUND = WORLD_TILES.DIRT

local assets =
{
    Asset("ANIM", "anim/pig_ruins_entrance.zip"),
    Asset("ANIM", "anim/pig_door_test.zip"),
    Asset("ANIM", "anim/pig_ruins_entrance_build.zip"),
    Asset("ANIM", "anim/pig_ruins_entrance_top_build.zip"),
}

local prefabs =
{
    "deco_roomglow",
    "light_dust_fx",
    "deco_ruins_wallcrumble_1",
    "deco_ruins_wallcrumble_side_1",
    "deco_ruins_cornerbeam",
    "deco_ruins_beam",
    "deco_ruins_wallstrut",
    "deco_ruins_beam_broken",
    "deco_ruins_cornerbeam_heavy",
    "deco_ruins_beam_room",
    "deco_ruins_fountain",
    "pig_ruins_torch_sidewall",
    "deco_ruins_pigman_relief_side",
    "deco_ruins_writing1",

    "pig_ruins_dart",

    "pig_ruins_pressure_plate",

    "pig_ruins_torch_wall",

    "deco_ruins_crack_roots1",
    "deco_ruins_crack_roots2",
    "deco_ruins_crack_roots3",
    "deco_ruins_crack_roots4",

    "deco_ruins_pigqueen_relief",
    "deco_ruins_pigking_relief",

    "deco_ruins_pigman_relief1",
    "deco_ruins_pigman_relief2",
    "deco_ruins_pigman_relief3",

    "pig_ruins_creeping_vines",
    "pig_ruins_wall_vines_north",
    "pig_ruins_wall_vines_east",
    "pig_ruins_wall_vines_west",

    "smashingpot",
    "aporkalypse_clock",
    "wallcrack_ruins"
}

local function RefreshBuild(inst,push)
    local anim = "idle_closed"
    if inst.stage == 2 then
        anim = "idle_med"
    elseif inst.stage == 1 then
        anim = "idle_low"
    elseif inst.stage == 0 then
        anim = "idle_open"
    end

    if inst:HasTag("top_ornament") then
        inst.AnimState:AddOverrideBuild("pig_ruins_entrance_top_build")
        inst.AnimState:Hide("swap_ornament2")
        inst.AnimState:Hide("swap_ornament3")
        inst.AnimState:Hide("swap_ornament4")
    elseif inst:HasTag("top_ornament2") then
        inst.AnimState:AddOverrideBuild("pig_ruins_entrance_top_build")
        inst.AnimState:Hide("swap_ornament3")
        inst.AnimState:Hide("swap_ornament4")
        inst.AnimState:Hide("swap_ornament")
    elseif inst:HasTag("top_ornament3") then
        inst.AnimState:AddOverrideBuild("pig_ruins_entrance_top_build")
        inst.AnimState:Hide("swap_ornament2")
        inst.AnimState:Hide("swap_ornament4")
        inst.AnimState:Hide("swap_ornament")
    elseif inst:HasTag("top_ornament4") then
        inst.AnimState:AddOverrideBuild("pig_ruins_entrance_top_build")
        inst.AnimState:Hide("swap_ornament2")
        inst.AnimState:Hide("swap_ornament3")
        inst.AnimState:Hide("swap_ornament")
    else
        inst.AnimState:Hide("swap_ornament4")
        inst.AnimState:Hide("swap_ornament3")
        inst.AnimState:Hide("swap_ornament2")
        inst.AnimState:Hide("swap_ornament")
        inst.AnimState:OverrideSymbol("statue_01", "pig_ruins_entrance", "")
        inst.AnimState:OverrideSymbol("swap_ornament", "pig_ruins_entrance", "")
    end

    if push then
        inst.AnimState:PushAnimation(anim, true)
    else
        inst.AnimState:PlayAnimation(anim, true)
    end
end

local function GetNumExitsInRoom(room)
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

local function BuildMaze(inst, dungeondef, exterior_door_def)
    local interior_spawner = TheWorld.components.interiorspawner

    local rooms_to_make = dungeondef.rooms --24
    local exitRoom = nil

    local rooms = {
        {
            x = 0,
            y = 0,
            id = interior_spawner:GetNewID(),
            exits = {},
            blocked_exits = {interior_spawner:GetNorth()},
            entrance1 = true,
        }
    }
    exterior_door_def.target_interior = rooms[1].id
    local rooms_by_id = {}
    rooms_by_id[rooms[1].id] = rooms[1]

    local clock_placed = false

    while #rooms < rooms_to_make do
        local dir = interior_spawner:GetDir()
        local dir_opposite = interior_spawner:GetDirOpposite()
        local dir_choice = math.random(#dir)
        local room_connecting_to = rooms[math.random(#rooms)]

        local fail = false

        -- fail if this direction from the chosen room is blocked
        for _, exit in pairs(room_connecting_to.blocked_exits) do
            if interior_spawner:GetDir()[dir_choice] == exit then
                fail = true
            end
        end

        -- fail if this room of the maze is already set up.
        if not fail then
            for _, room_to_check in pairs(rooms) do
                if room_to_check.x == room_connecting_to.x + dir[dir_choice].x and room_to_check.y == room_connecting_to.y + dir[dir_choice].y then
                    fail = true
                    break
                end
            end
        end

        if not fail then
            local new_room = {
                x = room_connecting_to.x + dir[dir_choice].x,
                y = room_connecting_to.y + dir[dir_choice].y,
                id = interior_spawner:GetNewID(),
                exits = {},
                blocked_exits = {},
            }

            room_connecting_to.exits[dir[dir_choice]] = {
                target_room = new_room.id,
                bank =  "doorway_ruins",
                build = "pig_ruins_door",
                room = room_connecting_to.id,
            }

            new_room.exits[dir_opposite[dir_choice]] = {
                target_room = room_connecting_to.id,
                bank =  "doorway_ruins",
                build = "pig_ruins_door",
                room = new_room.id,
            }

            -- if TheWorld:IsWorldGenOptionNever("door_vines") then
            --     dungeondef.doorvines = nil
            -- end

            if dungeondef.doorvines and math.random() < dungeondef.doorvines then
                room_connecting_to.exits[dir[dir_choice]].vined = true
                new_room.exits[dir_opposite[dir_choice]].vined = true
            end

            rooms_by_id[new_room.id] = new_room

            rooms[#rooms + 1] = new_room
        end
    end

    local function CreateSecretRoom()
        local grid = {}

        local function CheckFreeGridPos(x, y)
            for i,room in ipairs(rooms) do
                if room.x == x and room.y == y then
                    return false
                end
            end

            return true
        end

        local function CheckAdjacent(room, dir)
            local x = room.x + dir.x
            local y = room.y + dir.y

            if CheckFreeGridPos(x, y) then

                if not grid[x] then
                    grid[x] = {}
                end

                if not grid[x][y] then
                    grid[x][y] = { rooms = {room}, dirs = {dir}}
                else
                    table.insert(grid[x][y].rooms, room)
                    table.insert(grid[x][y].dirs, dir)
                end
            end
        end

        local function FindCandidates()
            for i,room in ipairs(rooms) do

                local north = interior_spawner:GetNorth()
                local west = interior_spawner:GetWest()
                local east = interior_spawner:GetEast()

                local dir = nil

                -- NORTH IS OPEN
                if not room.exits[north] and not room.entrance2 and not room.entrance1 then
                    CheckAdjacent(room, north)
                end

                -- WEST IS OPEN
                if not room.exits[west]  then
                    CheckAdjacent(room, west)
                end

                -- EAST IS OPEN
                if not room.exits[east] then
                    CheckAdjacent(room, east)
                end
            end
        end

        local function GetMax()
            local max_x = 0
            local max_y = 0
            local max = 0
            local key_1 = 0
            local key_2 = 0

            for k,v in pairs(grid) do
                for k2,v2 in pairs(v) do
                    if #v2.rooms > max then
                        max = #v2.rooms
                        max_x = k
                        max_y = k2
                    end
                end
            end

            if max > 0 then
                return max_x, max_y
            end
        end

        local function PopulateSecretRoom(x, y)

            local secret_room = {
                x = x,
                y = y,
                id = interior_spawner:GetNewID(),
                exits = {},
                blocked_exits ={},
                secretroom = true
            }

            local grid_rooms = grid[x][y].rooms
            local grid_dirs = grid[x][y].dirs

            local bank =  "interior_wall_decals_ruins"
            local build = "interior_wall_decals_ruins_cracks"

            if dungeondef.name == "RUINS_5" and not clock_placed then
                -- reduce the grid_room to 1
                clock_placed = true
                secret_room.aporkalypseclock = true
                while #grid_rooms > 1 do

                    local num = math.random(1,#grid_rooms)
                    table.remove(grid_rooms,num)
                    table.remove(grid_dirs,num)
                    bank =  "doorway_ruins"
                    build = "pig_ruins_door"
                end
            end

            for i, grid_room in ipairs(grid_rooms) do
                local op_dir = interior_spawner:GetOppositeFromDirection(grid_dirs[i])
                local secret = true
                if secret_room.aporkalypseclock == true then
                    secret = false
                end

                secret_room.exits[op_dir] = {
                    target_room = grid_room.id,
                    bank =  bank,
                    build = build,
                    room = secret_room.id,
                    secret = secret,
                }

                grid_room.exits[grid_dirs[i]] = {
                    target_room = secret_room.id,
                    bank =  "interior_wall_decals_ruins",
                    build = "interior_wall_decals_ruins_cracks",
                    room = grid_room.id,
                    secret = true
                }
            end

            grid[x][y] = nil
            return secret_room
        end

        FindCandidates()

        local secret_room_count = dungeondef.secretrooms

        for i=1, secret_room_count do
            local x, y = GetMax()
            if x == nil or y == nil then
                print ("COULDN'T FIND SUITABLE CANDIDATES FOR THE SECRET ROOM.")
            else
                local newroom = PopulateSecretRoom(x, y)
                if newroom then
                    rooms_by_id[newroom.id] = newroom
                    table.insert(rooms, newroom)
                end
            end
        end
    end

    local choices = {}
    local dist = 0
    for _, room in pairs(rooms) do
        local north_exit_open = not room.exits[interior_spawner:GetNorth()]

        if math.abs(room.x) + math.abs(room.y) > dist and north_exit_open then
            choices = {}
        end

        if math.abs(room.x) + math.abs(room.y) >= dist and north_exit_open then
            choices[#choices + 1] = room
            dist = math.abs(room.x) + math.abs(room.y)
        end
    end

    if not dungeondef.no_second_exit then
        if next(choices) then
            GetRandomItem(choices).entrance2 = true
        end
    end

    choices = {}
    for _, room in pairs(rooms) do
        if GetNumExitsInRoom(room) == 1 then
            choices[#choices + 1] = room
        end
    end

    if dungeondef.name == "RUINS_3" then
        choices[math.random(#choices)].pheromonestone = true
    elseif dungeondef.name == "RUINS_1" then
        choices[math.random(#choices)].relictruffle = true
    elseif dungeondef.name == "RUINS_2" then
        choices[math.random(#choices)].relicsow = true
    elseif dungeondef.name == "RUINS_5" then
        dungeondef.advancedtraps = true
        choices[math.random(#choices)].endswell = true
    else
        choices[math.random(#choices)].treasure = true
    end

    CreateSecretRoom()

    for _, room in pairs(rooms) do
        local roomtypes = {"grown_over", "store_room", "small_treasure", "snake", nil}

        -- TODO implement IsWorldGenOptionNever
        -- if not TheWorld:IsWorldGenOptionNever("spear_traps") then
            table.insert(roomtypes, "spear_trap")
        -- end

        -- if not TheWorld:IsWorldGenOptionNever("dart_traps") then
            table.insert(roomtypes, "dart_trap")
        -- end

        -- if more than one exit, add the doortrap to the potential list
        if GetNumExitsInRoom(rooms[1]) > 1 and not room.secretroom then
            table.insert(roomtypes, "door_trap")
            table.insert(roomtypes, "door_trap")
        end

        local roomtype = GetRandomItem(roomtypes)

        if room.treasure then
            roomtype =  "treasure"
        end
        if room.relictruffle or room.relicsow then
            roomtype =  "treasure_rarerelic"
        end
        if room.secretroom  then
            roomtype = "treasure_secret"
        end
        if room.aporkalypseclock then
            roomtype = "treasure_aporkalypse"
        end
        if room.endswell then
            roomtype = "treasure_endswell" -- this prevents other features from conflicting with the endswell well.
        end

        local wall_texture = PIG_RUINS_WALL_TEXTURE
        local floor_texture = PIG_RUINS_FLOOR_TEXTURE
        if dungeondef.deepruins and math.random() < 0.3 then
            room.color = "_blue"
        else
            room.color = ""
        end
        if room.color == "_blue" then
            for ii, exit in pairs(room.exits)do
                if exit.build == "pig_ruins_door" then
                    exit.build = "pig_ruins_door_blue"
                end
            end

            wall_texture = PIG_RUINS_WALL_TEXTURE_BLUE
            floor_texture = PIG_RUINS_FLOOR_TEXTURE_BLUE
        end

        local exits_open = {
            west = not room.exits[interior_spawner:GetWest()],
            south = not room.exits[interior_spawner:GetSouth()],
            east = not room.exits[interior_spawner:GetEast()]
        }
        local exits_vined = {
            west = not exits_open.west and room.exits[interior_spawner:GetWest()].vined or false,
            south = not exits_open.south and room.exits[interior_spawner:GetSouth()].vined or false,
            east = not exits_open.east and room.exits[interior_spawner:GetEast()].vined or false,
        }
        local addprops, entrance_room, exit_room = GenerateProps("pig_ruins_" .. roomtype, PIG_RUINS_DEPTH, PIG_RUINS_WIDTH,
            exits_open, exits_vined, room, roomtype, dungeondef, exterior_door_def)

        if not exitRoom then
            exitRoom = exit_room
        end

        local def = interior_spawner:CreateRoom("generic_interior", PIG_RUINS_WIDTH, nil, PIG_RUINS_DEPTH, dungeondef.name, room.id, addprops, room.exits,
            wall_texture, floor_texture, PIG_RUINS_MINIMAP_TEXTURE, nil, PIG_RUINS_COLOUR_CUBE, nil, nil,
            PIG_RUINS_CAVE_REVERB, PIG_RUINS_CAVE_AMBIENT, PIG_RUINS_CAVE_GROUND_SOUND)
        interior_spawner:SpawnInterior(def)
    end

    return rooms[1], exitRoom
end

local function InitMaze(inst, dungeonname)
    if inst.maze_generated then
        RefreshBuild(inst)
        return
    end

    local dungeondef = {
        name = dungeonname,
        rooms = 24,
        lock  = true,
        doorvines = 0.3,
        deepruins = true,
        secretrooms = 2,
    }

    if dungeonname == "RUINS_2" then
        dungeondef.rooms = 15
        dungeondef.doorvines = 0.6
    elseif dungeonname == "RUINS_3" then
        dungeondef.rooms = 15
        dungeondef.no_second_exit = true
    elseif dungeonname == "RUINS_4" then
        dungeondef.rooms = 20
        dungeondef.doorvines = 0.4
    elseif dungeonname == "RUINS_5" then
        dungeondef.rooms = 30
        dungeondef.doorvines = 0.6
        dungeondef.no_second_exit = true
    elseif dungeonname == "RUINS_SMALL" then
        dungeondef.name = "RUINS_SMALL"
        dungeondef.rooms = math.random(6,8)
        dungeondef.no_second_exit = true
        dungeondef.lock = nil
        dungeondef.doorvines = nil
        dungeondef.deepruins = nil
        dungeondef.secretrooms = 1
        dungeondef.smallsecret = true
    end

    local exterior_door_def = {
        my_door_id = dungeondef.name .. "_ENTRANCE1",
        target_door_id = dungeondef.name .. "_EXIT1",
    }
    local entranceRoom, exitRoom = BuildMaze(inst, dungeondef, exterior_door_def)
    local interior_spawner = TheWorld.components.interiorspawner
    interior_spawner:AddDoor(inst, exterior_door_def)

    -- if inst.components.door and dungeondef.lock then
    --     inst.components.door:checkDisableDoor(true, "vines")
    -- end

    local exit_door = nil
    for _, ent in pairs(Ents) do
        if ent:HasTag(dungeondef.name .. "_EXIT_TARGET") then
            exit_door = ent
        end
    end

    if exit_door and exitRoom then
        -- CREATE 2nd DOOR
        local exterior_door_def2 = {
            my_door_id = dungeondef.name .. "_ENTRANCE2",
            target_door_id = dungeondef.name .. "_EXIT2",
            target_interior = exitRoom.id,
        }
        interior_spawner:AddDoor(exit_door, exterior_door_def2)
    end

    inst.maze_generated = true

    RefreshBuild(inst)
end

local function GetStatus(inst)
    if inst.components.door.disabled then
        return "LOCKED"
    end
end

local function OnHacked(inst, hacker, hacksleft)
    if hacksleft <= 0 then
        if inst.stage > 0 then
            inst.stage = inst.stage -1

            if inst.stage == 0 then
                inst.components.hackable.canbehacked = false
                inst.components.door:checkDisableDoor(false, "vines")
            else
                inst.components.hackable.hacksleft = inst.components.hackable.maxhacks
            end
        end
    end

    local fx = SpawnPrefab("hacking_fx")
    local x, y, z= inst.Transform:GetWorldPosition()
    fx.Transform:SetPosition(x, y + math.random() * 2, z)

    inst.SoundEmitter:PlaySound("dontstarve_DLC002/common/vine_hack")

    if inst.stage == 3 then
        inst.AnimState:PlayAnimation("hit_closed")
    elseif inst.stage == 2 then
        inst.AnimState:PlayAnimation("hit_med")
    elseif inst.stage == 1 then
        inst.AnimState:PlayAnimation("hit_low")
    end

    RefreshBuild(inst,true)
end

local function OnSave(inst, data)
    data.stage = inst.stage
    data.hackeable = inst.components.hackable.canbehacked
    data.maze_generated = inst.maze_generated

    if inst:HasTag("top_ornament") then
        data.top_ornament = true
    end
    if inst:HasTag("top_ornament2") then
        data.top_ornament2 = true
    end
    if inst:HasTag("top_ornament3") then
        data.top_ornament3 = true
    end
end

local function OnLoad(inst, data)
    if data then
        if data.stage then
            inst.stage = data.stage
        end
        if data.hackable then
            inst.components.hackable.canbehacked = data.hackeable
        end
        if data.maze_generated then
            inst:AddTag("maze_generated")
        end
        if data.top_ornament then
            inst:AddTag("top_ornament")
        end
        if data.top_ornament2 then
            inst:AddTag("top_ornament2")
        end
        if data.top_ornament3 then
            inst:AddTag("top_ornament3")
        end
    end

    RefreshBuild(inst)
end

local function MakeEntrance(name, is_entrance, dungeonname)
    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddLight()
        inst.entity:AddSoundEmitter()
        inst.entity:AddMiniMapEntity()
        inst.entity:AddNetwork()

        MakeObstaclePhysics(inst, 1.20)

        inst.AnimState:SetBank("pig_ruins_entrance")
        inst.AnimState:SetBuild("pig_ruins_entrance_build")
        inst.AnimState:PlayAnimation("idle_closed", true)

        inst.MiniMapEntity:SetIcon("pig_ruins_entrance.tex")

        inst:AddTag("ruins_exit")
        if dungeonname == "RUINS_1" then
            inst:AddTag("top_ornament")
        elseif dungeonname == "RUINS_2" then
            inst:AddTag("top_ornament2")
        elseif dungeonname == "RUINS_3" then
            inst:AddTag("top_ornament3")
        elseif dungeonname == "RUINS_4" or dungeonname == "RUINS_5" then
            inst:AddTag("top_ornament4")
        end

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        inst:AddComponent("hackable")
        inst.components.hackable:SetUp()
        inst.components.hackable.onhackedfn = OnHacked
        inst.components.hackable.hacksleft = TUNING.RUINS_ENTRANCE_VINES_HACKS
        inst.components.hackable.maxhacks = TUNING.RUINS_ENTRANCE_VINES_HACKS

        inst:AddComponent("shearable")

        inst:AddComponent("inspectable")
        inst.components.inspectable.getstatus = GetStatus

        inst:AddComponent("door")
        inst.components.door.outside = true

        if is_entrance then -- this prefab is the entrance. Makes the maze
            inst.stage = 3

            -- spread out the maze gen for less hiccup at load time.
            inst:DoTaskInTime(0, function()
                -- local time = 0
                -- local player = GetPlayer()
                -- local dist = inst:GetDistanceSqToInst(player)
                -- local w,h = GetWorld().Map:GetSize()
                -- if not GetWorld().ruinspawntime then
                --     GetWorld().ruinspawntime = 0.5
                -- end
                -- if dist < 40*40 then
                --     time = Remap(dist,0,40*40,0,0.5)
                -- else
                --     time = GetWorld().ruinspawntime
                --     GetWorld().ruinspawntime  = GetWorld().ruinspawntime + 0.3
                -- end
                inst:DoTaskInTime(1, function()
                    InitMaze(inst, dungeonname)
                end)
            end)
        else -- this prefab is an exit. Just set the door and art
            inst:AddTag(dungeonname.."_EXIT_TARGET")
            inst.stage = 0
            inst.components.hackable.canbehacked = false
            inst.components.door.disabled = nil
            RefreshBuild(inst)
        end

        if dungeonname == "RUINS_SMALL" then
            inst.stage = 0
            inst.components.hackable.canbehacked = false
            inst.components.door.disabled = nil
            RefreshBuild(inst)
        end

        MakeSnowCovered(inst, 0.01)

        inst.OnSave = OnSave
        inst.OnLoad = OnLoad

        return inst
    end

    return Prefab(name, fn, assets, prefabs)
end

return MakeEntrance("pig_ruins_entrance", true,"RUINS_1"),
       MakeEntrance("pig_ruins_exit", false,"RUINS_1"),

       MakeEntrance("pig_ruins_entrance2", true,"RUINS_2"),
       MakeEntrance("pig_ruins_exit2", false,"RUINS_2"),

       MakeEntrance("pig_ruins_entrance3", true,"RUINS_3"),

       MakeEntrance("pig_ruins_entrance4", true,"RUINS_4"),
       MakeEntrance("pig_ruins_exit4", false,"RUINS_4"),

       MakeEntrance("pig_ruins_entrance5", true,"RUINS_5"),

       MakeEntrance("pig_ruins_entrance_small", true,"RUINS_SMALL")
