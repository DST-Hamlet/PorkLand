local GenerateProps = require("prefabs/interior_prop_defs")

local assets =
{
    Asset("ANIM", "anim/ant_hill_entrance.zip"),
    Asset("ANIM", "anim/ant_queen_entrance.zip"),
}

local prefabs =
{
    "antman",
    "antman_warrior",
    "int_ceiling_dust_fx",
    "antchest",
    "giantgrub",
    "ant_cave_lantern",
    "antqueen",
}

-- local QUEEN_CHAMBER_COUNT_MAX = 6
-- local QUEEN_CHAMBER_COUNT_MIN = 3

local ANT_CAVE_DEPTH = 18
local ANT_CAVE_WIDTH = 26
local ANT_CAVE_HEIGHT = 7
local ANT_CAVE_FLOOR_TEXTURE = "levels/textures/interiors/antcave_floor.tex"
local ANT_CAVE_WALL_TEXTURE = "levels/textures/interiors/antcave_wall_rock.tex"
local ANT_CAVE_MINIMAP_TEXTURE = "levels/textures/map_interior/mini_antcave_floor.tex"
local ANT_CAVE_COLOUR_CUBE = "images/colour_cubes/pigshop_interior_cc.tex"

local ANTHILL_DUNGEON_NAME = "ANTHILL1"

-- Each value here indicates how many of the 25 rooms are created with each room setup.
local ANTHILL_EMPTY_COUNT = 7
local ANTHILL_ANT_HOME_COUNT = 5
local ANTHILL_WANDERING_ANT_COUNT = 10
local ANTHILL_TREASURE_COUNT = 3
local ROOM_CARDINALITY = {ANTHILL_EMPTY_COUNT, ANTHILL_ANT_HOME_COUNT, ANTHILL_WANDERING_ANT_COUNT, ANTHILL_TREASURE_COUNT}

local dir_names = { "east", "west", "north", "south" }
local dirNamesOpposite = { "west", "east", "south", "north" }

local EAST_DOOR_IDX  = 1
local WEST_DOOR_IDX  = 2
local NORTH_DOOR_IDX = 3
local SOUTH_DOOR_IDX = 4
local NUM_ENTRANCES = 3
local NUM_CHAMBER_ENTRANCES = 1
local NUM_ROWS = 5
local NUM_COLS = 5

local function ChooseEntrances(inst)
    local num_entrances_chosen = 0

    repeat
        local row_index = math.random(1, NUM_ROWS)
        local col_index = math.random(1, NUM_COLS)

        if not inst.rooms[row_index][col_index].is_entrance then
            inst.rooms[row_index][col_index].is_entrance = true
            num_entrances_chosen = num_entrances_chosen + 1
        end
    until (num_entrances_chosen == NUM_ENTRANCES)
end

local function ChooseChamberEntrances(inst)
   local num_entrances_chosen = 0

    repeat
        local row_index = math.random(1, NUM_ROWS)
        local col_index = math.random(1, NUM_COLS)

        if not inst.rooms[row_index][col_index].is_entrance and not inst.rooms[row_index][col_index].isChamberEntrance then
            inst.rooms[row_index][col_index].isChamberEntrance = true
            num_entrances_chosen = num_entrances_chosen + 1
        end
    until (num_entrances_chosen == NUM_CHAMBER_ENTRANCES)
end

local function ConnectRooms(dirIndex, room_from, room_to)
    local interior_spawner = TheWorld.components.interiorspawner
    local dirs = interior_spawner:GetDir()
    local dirs_opposite = interior_spawner:GetDirOpposite()

    room_from.exits[dirs[dirIndex]] = {
        target_room = room_to.id,
        bank  = "ant_cave_door",
        build = "ant_cave_door",
        room  = room_from.id,
        sg_name = "SGanthilldoor_" .. dir_names[dirIndex],
        startstate = "idle",
    }

    room_to.exits[dirs_opposite[dirIndex]] = {
        target_room = room_from.id,
        bank  = "ant_cave_door",
        build = "ant_cave_door",
        room  = room_to.id,
        sg_name = "SGanthilldoor_" .. dirNamesOpposite[dirIndex],
        startstate = "idle",
    }
end

local function ConnectDoors(inst)
    for i = 1, NUM_ROWS do
        for j = 1, NUM_COLS do
            local current_room = inst.rooms[i][j]

            -- EAST
            if (current_room.x + 1) <= NUM_COLS then
                local room_east = inst.rooms[current_room.y][current_room.x + 1]
                ConnectRooms(EAST_DOOR_IDX, current_room, room_east)
            end

            -- WEST
            if (current_room.x - 1) >= 1 then
                local room_west = inst.rooms[current_room.y][current_room.x - 1]
                ConnectRooms(WEST_DOOR_IDX, current_room, room_west)
            end

            -- NORTH
            if ((current_room.y - 1) >= 1) and not current_room.is_entrance then
                local room_north = inst.rooms[current_room.y - 1][current_room.x]
                -- The entrance is always from the north, so when attempting to link to a northern room, give up if the current room is an entrance.
                ConnectRooms(NORTH_DOOR_IDX, current_room, room_north)
            end

            -- SOUTH
            if (current_room.y + 1) <= NUM_ROWS then
                local room_south = inst.rooms[current_room.y + 1][current_room.x]
                -- The entrance is always from the north, so when attempting to link to a southern room, give up if it's an entrance.
                if not room_south.is_entrance then
                    ConnectRooms(SOUTH_DOOR_IDX, current_room, room_south)
                end
            end
        end
    end
end

local function BuildGrid(inst)
    local interior_spawner = TheWorld.components.interiorspawner

    inst.rooms = {}

    for i = 1, NUM_ROWS do
        local roomRow = {}

        for j = 1, NUM_COLS do
            local room = {
                x = j,
                y = i,
                id = interior_spawner:GetNewID(),
                exits = {},
                is_entrance = false,
                isChamberEntrance = false,
                parent_room = nil,
                doors_enabled = {false, false, false, false},
                dirs_explored = {false, false, false, false},
            }

            table.insert(roomRow, room)
        end

        table.insert(inst.rooms, roomRow)
    end

    ChooseEntrances(inst)
    ChooseChamberEntrances(inst)

    -- All possible doors are built, and then the doors_enabled flag
    -- is what indicates if they should actually be in use or not.
    ConnectDoors(inst)
end

local function RebuildGrid(inst)
    for i = 1, NUM_ROWS do
        for j = 1, NUM_COLS do
            inst.rooms[i][j].parent_room = nil
            inst.rooms[i][j].doors_enabled = {false, false, false, false}
            inst.rooms[i][j].dirs_explored = {false, false, false, false}
        end
    end
end

local function link(inst, room)
    local row = 0
    local col = 0

    local dirsOpposite = { WEST_DOOR_IDX, EAST_DOOR_IDX, SOUTH_DOOR_IDX, NORTH_DOOR_IDX }

    if room == nil then
        return nil
    end

    -- While there are still directions to explore.
    while not (room.dirs_explored[EAST_DOOR_IDX]
        and room.dirs_explored[WEST_DOOR_IDX]
        and room.dirs_explored[NORTH_DOOR_IDX]
        and room.dirs_explored[SOUTH_DOOR_IDX]) do
        local dirIndex = math.random(#room.dirs_explored)

        -- If already explored, then try again.
        if not room.dirs_explored[dirIndex] then
            room.dirs_explored[dirIndex] = true

            local dirPossible = false
            if dirIndex == EAST_DOOR_IDX then -- EAST
                if (room.x + 1 <= NUM_COLS) then
                    col = room.x + 1
                    row = room.y
                    dirPossible = true
                end
            elseif dirIndex == SOUTH_DOOR_IDX then -- SOUTH
                if (room.y + 1 <= NUM_ROWS) then
                    -- The entrance is always from the north, so when attempting
                    -- to link to a southern room, give up if it's an entrance.
                    local destRoom = inst.rooms[room.y + 1][room.x]
                    if not destRoom.is_entrance then
                        col = room.x
                        row = room.y + 1
                        dirPossible = true
                    end
                end
            elseif dirIndex == WEST_DOOR_IDX then -- WEST
                if (room.x - 1 >= 1) then
                    col = room.x - 1
                    row = room.y
                    dirPossible = true
                end
            elseif dirIndex == NORTH_DOOR_IDX then -- NORTH
                -- The entrance is always from the north, so when attempting to link
                -- to a northern room, give up if the current room is an entrance.
                if ((room.y - 1 >= 1) and not room.is_entrance) then
                    col = room.x
                    row = room.y - 1
                    dirPossible = true
                end
            end

            if dirPossible then
                -- Get destination node into pointer (makes things a tiny bit faster)
                local destination_room = inst.rooms[row][col]

                if (destination_room.parent_room == nil) then -- If destination is a linked node already - abort
                    destination_room.parent_room = room -- Otherwise, adopt node
                    room.doors_enabled[dirIndex] = true -- Remove wall between nodes (ie. Create door.)
                    destination_room.doors_enabled[dirsOpposite[dirIndex]] = true

                    -- Return address of the child node
                    return destination_room
                end
            end
        end
    end

    -- If nothing more can be done here - return parent's address
    return room.parent_room
end

local function BuildWalls(inst)
    local start_room = inst.rooms[1][1]
    start_room.parent_room = start_room
    local last_room = start_room

    -- Connect nodes until start node is reached and can't be left
    repeat
        last_room = link(inst, last_room)
    until (last_room == start_room)
end

local room_types = {"anthill_empty", "anthill_ant_home", "anthill_wandering_ant", "anthill_treasure"}

local function CreateRegularRooms(inst)
    local interior_spawner = TheWorld.components.interiorspawner

    local room_id_list = {}
    for room_id, cardinality in pairs(ROOM_CARDINALITY) do
        for i = 1, cardinality do
            table.insert(room_id_list, room_id)
        end
    end
    room_id_list = shuffleArray(room_id_list)

    local doorway_count = 1
    local current_room_setup_index = 1
    local doorway_prefabs = {inst}
    for _, ent in pairs(Ents) do
        if ent:HasTag("ant_hill_exit") then
            table.insert(doorway_prefabs, ent)
        end
    end

    for i = 1, NUM_ROWS do
        for j = 1, NUM_COLS do
            local room = inst.rooms[i][j]
            local room_type = room_types[room_id_list[current_room_setup_index]]
            current_room_setup_index = current_room_setup_index + 1

            local addprops = GenerateProps(room_type, ANT_CAVE_DEPTH, ANT_CAVE_WIDTH, room, doorway_count,
                doorway_prefabs)

            if room.is_entrance then
                local exterior_door_def = {
                    my_door_id = "ANTHILL_" .. doorway_count .. "_ENTRANCE",
                    target_door_id = "ANTHILL_" .. doorway_count .. "_EXIT",
                    target_interior = room.id,
                }

                doorway_prefabs[doorway_count].interiorID = room.id
                doorway_prefabs[doorway_count].doorway_index = doorway_count
                TheWorld.components.interiorspawner:AddDoor(doorway_prefabs[doorway_count], exterior_door_def)
                TheWorld.components.interiorspawner:AddExterior(doorway_prefabs[doorway_count])

                doorway_count = doorway_count + 1
            end

            interior_spawner:CreateRoom({
                width = ANT_CAVE_WIDTH,
                height = ANT_CAVE_HEIGHT,
                depth = ANT_CAVE_DEPTH,
                dungeon_name = ANTHILL_DUNGEON_NAME,
                roomindex = room.id,
                addprops = addprops,
                exits = room.exits,
                walltexture = ANT_CAVE_WALL_TEXTURE,
                floortexture = ANT_CAVE_FLOOR_TEXTURE,
                minimaptexture = ANT_CAVE_MINIMAP_TEXTURE,
                colour_cube = ANT_CAVE_COLOUR_CUBE,
                reverb = "anthill",
                ambient_sound = "ANT_HIVE",
                footstep_tile = WORLD_TILES.DIRT,
                cameraoffset = nil,
                zoom = nil,
                group_id = inst.rooms[1][1].id,
                interior_coordinate_x = room.x,
                interior_coordinate_y = -room.y,
            })
        end
    end
end

local function SetCurrentDoorHiddenStatus(door, show, direction)
    local isaleep = door:IsAsleep()
    if show and door.components.door.hidden then
        if isaleep then
            door.components.door:SetHidden(false)
            door.sg:GoToState("idle")
        else
            door.sg:GoToState("open")
        end
    elseif not show and not door.components.door.hidden then
        if isaleep then
            door.components.door:SetHidden(true)
            door.sg:GoToState("idle")
        else
            door.sg:GoToState("shut")
        end
    end
end

local function RefreshCurrentDoor(room, door)
    if not door.components.door then
        return
    end
    if door.components.door.target_interior == "EXTERIOR" then
        return
    end

    if door:HasTag("door_north") then
        SetCurrentDoorHiddenStatus(door, room.doors_enabled[NORTH_DOOR_IDX], "north")
    elseif door:HasTag("door_south") then
        SetCurrentDoorHiddenStatus(door, room.doors_enabled[SOUTH_DOOR_IDX], "south")
    elseif door:HasTag("door_east") then
        SetCurrentDoorHiddenStatus(door, room.doors_enabled[EAST_DOOR_IDX], "east")
    elseif door:HasTag("door_west") then
        SetCurrentDoorHiddenStatus(door, room.doors_enabled[WEST_DOOR_IDX], "west")
    end
end

local function RefreshDoors(inst)
    local interior_spawner = TheWorld.components.interiorspawner
    for i = 1, NUM_ROWS do
        for j = 1, NUM_COLS do
            local room = inst.rooms[i][j]

            local centre = interior_spawner:GetInteriorCenter(room.id)
            local x, y, z = centre.Transform:GetWorldPosition()
            local ents = TheSim:FindEntities(x, y, z, TUNING.ROOM_FINDENTITIES_RADIUS, {"interior_door"})
            for _, door in pairs(ents) do
                RefreshCurrentDoor(room, door)
            end
        end
    end
end

local function SpawnDust(inst, dust_count, interiorID)
    if dust_count > 0 then
        local VARIANCE = 8.0
        local offset = Vector3(math.random(-VARIANCE, VARIANCE), 0, math.random(-VARIANCE, VARIANCE))
        local fx = TheWorld.components.interiorspawner:SpawnObject(interiorID, "int_ceiling_dust_fx", offset)
        fx.Transform:SetScale(2.0, 2.0, 2.0)
        inst:DoTaskInTime(0.5, function() SpawnDust(inst, dust_count - 1, interiorID) end)
    end
end

local function Earthquake(inst)
    for i = 1, NUM_ROWS do
        for j = 1, NUM_COLS do
            local room = inst.rooms[i][j]
            TheWorld:PushEvent("interior_startquake", {interiorID = room.id, quake_level = INTERIOR_QUAKE_LEVELS.ANTHILL_REBUILT})
            SpawnDust(inst, 10, room.id)
        end
    end
end

local function CreateInterior(inst)
    BuildGrid(inst)
    CreateRegularRooms(inst)
    BuildWalls(inst)
    RefreshDoors(inst)
    if inst.interiorID then
        TheWorld.components.interiorspawner:AddExterior(inst)
    end
end

local function GenerateMaze(inst)
    RebuildGrid(inst)
    BuildWalls(inst)
    RefreshDoors(inst)
    Earthquake(inst)

    inst.maze_reset_time = TheWorld.components.worldtimetracker:GetTime()
    for _, player in ipairs(AllPlayers) do
        local interiorvisitor = player.components.interiorvisitor
        if interiorvisitor then
            interiorvisitor:RecordAnthillDoorMapReset()
        end
    end
end

-- end of interior stuff

local function GetStatus(inst)
    if inst:HasTag("burnt") then
        return "BURNT"
    elseif inst.components.spawner and inst.components.spawner:IsOccupied() then
        if inst.lightson then
            return "FULL"
        else
            return "LIGHTSOUT"
        end
    end
end

local function OnSave(inst, data)
    data.maze_reset_time = inst.maze_reset_time
    data.interiorID = inst.interiorID
    if inst.rooms then
        data.rooms = inst.rooms

        -- parent_room and exits are not necessary to save and cause the
        -- game to crash upon saving, so they are stripped out here.
        for i = 1, NUM_ROWS do
            for j = 1, NUM_COLS do
                data.rooms[i][j].parent_room = nil
                data.rooms[i][j].exits = nil
            end
        end
    end
    data.doorway_index = inst.doorway_index
end

local function OnLoad(inst, data)
    if not data then
        return
    end

    if data.maze_reset_time then
        inst.maze_reset_time = data.maze_reset_time
    end

    if data.interiorID then
        inst.interiorID = data.interiorID
        inst.doorway_index = data.doorway_index
        TheWorld.components.interiorspawner:AddExterior(inst)
    end

    if data.rooms then
        inst.rooms = data.rooms
    end
end

local function OnLoadPostPass(inst, data) -- 出口的连接写在 OnLoadPostPass 中，这样才能确定所有储存的实体已经添加进世界
    if inst.is_entrance then
        if inst.interiorID == nil then
            CreateInterior(inst)
        end
    end
end

local function makefn(is_entrance)
    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddLight()
        inst.entity:AddSoundEmitter()
        inst.entity:AddMiniMapEntity()
        inst.entity:AddNetwork()

        MakeObstaclePhysics(inst, 1.3)

        inst.AnimState:SetBank("ant_hill_entrance")
        inst.AnimState:SetBuild("ant_hill_entrance")
        inst.AnimState:PlayAnimation("idle", true)

        inst.Light:SetFalloff(1)
        inst.Light:SetIntensity(0.5)
        inst.Light:SetRadius(1)
        inst.Light:Enable(false)
        inst.Light:SetColour(180 / 255, 195 / 255, 50 / 255)

        inst.MiniMapEntity:SetIcon("ant_hill_entrance.tex")

        inst.Transform:SetScale(0.8, 0.8, 0.8)

        inst:AddTag("structure")
        inst:AddTag("client_forward_action_target")
        if is_entrance then
            inst.is_entrance = true
            inst:AddTag("ant_hill_entrance")
        else
            inst:AddTag("ant_hill_exit")
        end

        inst.name = STRINGS.NAMES.ANTHILL

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        inst:AddComponent("lootdropper")

        inst:AddComponent("childspawner")
        inst.components.childspawner.childname = "antman"
        inst.components.childspawner:SetRegenPeriod(TUNING.ANTMAN_REGEN_TIME)
        inst.components.childspawner:SetSpawnPeriod(TUNING.ANTMAN_RELEASE_TIME)
        inst.components.childspawner:SetMaxChildren(math.random(TUNING.ANTMAN_MIN, TUNING.ANTMAN_MAX))
        inst.components.childspawner:StartSpawning()

        inst:AddComponent("playerprox")
        inst.components.playerprox:SetDist(10, 13)

        inst:AddComponent("inspectable")
        inst.components.inspectable.getstatus = GetStatus
        inst.components.inspectable.nameoverride = "anthill"

        inst:AddComponent("door")
        inst.components.door.outside = true

        MakeSnowCovered(inst, 0.01)

        inst.OnSave = OnSave
        inst.OnLoad = OnLoad
        inst.OnLoadPostPass = OnLoadPostPass
        inst.GenerateMaze = GenerateMaze

        if is_entrance then
            inst:DoTaskInTime(0, function()
                if inst.interiorID == nil then
                    CreateInterior(inst)
                end
            end)
            inst:DoPeriodicTask(TUNING.TOTAL_DAY_TIME / 3, inst.GenerateMaze)
            TheWorld.anthill_entrance = inst
            inst.maze_reset_time = 0
        end

        return inst
    end

    return fn
end

return Prefab("anthill", makefn(true), assets, prefabs),
       Prefab("anthill_exit", makefn(false), assets, prefabs)
