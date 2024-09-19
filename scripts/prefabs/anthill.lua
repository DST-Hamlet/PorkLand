local GenerateProps = require("prefabs/interior_prop_defs")

local assets =
{
    Asset("ANIM", "anim/ant_hill_entrance.zip"),
    -- Asset("ANIM", "anim/ant_queen_entrance.zip"),
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

local QUEEN_CHAMBER_COUNT_MAX = 6
local QUEEN_CHAMBER_COUNT_MIN = 3

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

local dirNames = { "east", "west", "north", "south" }
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

    room_from.exits[dirs[dirIndex]] ={
        target_room = room_to.id,
        bank  = "ant_cave_door",
        build = "ant_cave_door",
        room  = room_from.id,
        sg_name = "SGanthilldoor_" .. dirNames[dirIndex],
        startstate = "idle_" .. dirNames[dirIndex],
    }

    room_to.exits[dirs_opposite[dirIndex]] = {
        target_room = room_from.id,
        bank  = "ant_cave_door",
        build = "ant_cave_door",
        room  = room_to.id,
        sg_name = "SGanthilldoor_" .. dirNamesOpposite[dirIndex],
        startstate = "idle_" .. dirNamesOpposite[dirIndex],
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
                parentRoom = nil,
                doorsEnabled = {false, false, false, false},
                dirsExplored = {false, false, false, false},
            }

            table.insert(roomRow, room)
        end

        table.insert(inst.rooms, roomRow)
    end

    ChooseEntrances(inst)
    ChooseChamberEntrances(inst)

    -- All possible doors are built, and then the doorsEnabled flag
    -- is what indicates if they should actually be in use or not.
    ConnectDoors(inst)
end

local function RebuildGrid(inst)
    for i = 1, NUM_ROWS do
        for j = 1, NUM_COLS do
            inst.rooms[i][j].parentRoom = nil
            inst.rooms[i][j].doorsEnabled = {false, false, false, false}
            inst.rooms[i][j].dirsExplored = {false, false, false, false}
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
    while not (room.dirsExplored[EAST_DOOR_IDX]
        and room.dirsExplored[WEST_DOOR_IDX]
        and room.dirsExplored[NORTH_DOOR_IDX]
        and room.dirsExplored[SOUTH_DOOR_IDX]) do
        local dirIndex = math.random(#room.dirsExplored)

        -- If already explored, then try again.
        if not room.dirsExplored[dirIndex] then
            room.dirsExplored[dirIndex] = true

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

                if (destination_room.parentRoom == nil) then -- If destination is a linked node already - abort
                    destination_room.parentRoom = room -- Otherwise, adopt node
                    room.doorsEnabled[dirIndex] = true -- Remove wall between nodes (ie. Create door.)
                    destination_room.doorsEnabled[dirsOpposite[dirIndex]] = true

                    -- Return address of the child node
                    return destination_room
                end
            end
        end
    end

    -- If nothing more can be done here - return parent's address
    return room.parentRoom
end

local function BuildWalls(inst)
    local start_room = inst.rooms[1][1]
    start_room.parentRoom = start_room
    local last_room = start_room

    -- Connect nodes until start node is reached and can't be left
    repeat
        last_room = link(inst, last_room)
    until (last_room == start_room)
end

local queenchamber_placement_id = {}
local queen_chamber_ids = {}

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
            ent:RemoveTag("ant_hill_exit") -- todo tag
            table.insert(doorway_prefabs, ent)
        end
    end

    for i = 1, NUM_ROWS do
        for j = 1, NUM_COLS do
            local room = inst.rooms[i][j]
            local room_type = room_types[room_id_list[current_room_setup_index]]
            current_room_setup_index = current_room_setup_index + 1

            local addprops = GenerateProps(room_type, ANT_CAVE_DEPTH, ANT_CAVE_WIDTH, room, doorway_count,
                doorway_prefabs, queenchamber_placement_id, queen_chamber_ids)

            if room.is_entrance then
                local exterior_door_def = {
                    my_door_id = "ANTHILL_" .. doorway_count .. "_ENTRANCE",
                    target_door_id = "ANTHILL_" .. doorway_count .. "_EXIT",
                    target_interior = room.id,
                }

                doorway_prefabs[doorway_count].interiorID = room.id
                TheWorld.components.interiorspawner:AddDoor(doorway_prefabs[doorway_count], exterior_door_def)

                doorway_count = doorway_count + 1
            end

            local def = interior_spawner:CreateRoom("generic_interior", ANT_CAVE_WIDTH, ANT_CAVE_HEIGHT, ANT_CAVE_DEPTH, ANTHILL_DUNGEON_NAME, room.id, addprops,
                room.exits, ANT_CAVE_WALL_TEXTURE, ANT_CAVE_FLOOR_TEXTURE, ANT_CAVE_MINIMAP_TEXTURE, nil, ANT_CAVE_COLOUR_CUBE,
                nil, nil, "anthill","ANT_HIVE","DIRT")
            interior_spawner:SpawnInterior(def)
        end
    end
end

-- We generate these outside of the CreateQueenChambers function because we need the ids to link it to the regular anthill
local function GenerateQueenChamberIDS(room_count)
    local interior_spawner = TheWorld.components.interiorspawner

    for i = 1, room_count do
        local newid = interior_spawner:GetNewID()
        table.insert(queen_chamber_ids, newid)
    end
end

local function CreateQueenChambers(room_count)
    local interior_spawner = TheWorld.components.interiorspawner

    for i = 1, room_count do
        local is_queen_chamber = i == room_count -- last room is ant queen room

        local addprops, def
        if is_queen_chamber then
            addprops = GenerateProps("anthill_queen_chamber", ANT_CAVE_DEPTH, ANT_CAVE_WIDTH, i, queen_chamber_ids)

            def = interior_spawner:CreateRoom("generic_interior", ANT_CAVE_WIDTH, ANT_CAVE_HEIGHT, ANT_CAVE_DEPTH, "QUEEN_CHAMBERS_DUNGEON_" .. i,
                queen_chamber_ids[i], addprops, {}, ANT_CAVE_WALL_TEXTURE, ANT_CAVE_FLOOR_TEXTURE, ANT_CAVE_MINIMAP_TEXTURE, nil,
                ANT_CAVE_COLOUR_CUBE, nil, nil, "anthill","ANT_HIVE","DIRT", -3.5, 40)
        else
            addprops = GenerateProps("anthill_queen_chamber_hallway", ANT_CAVE_DEPTH, ANT_CAVE_WIDTH, i, queen_chamber_ids, queenchamber_placement_id)

            def = interior_spawner:CreateRoom("generic_interior", ANT_CAVE_WIDTH, ANT_CAVE_HEIGHT, ANT_CAVE_DEPTH, "QUEEN_CHAMBERS_DUNGEON_" .. i,
                queen_chamber_ids[i], addprops, {}, ANT_CAVE_WALL_TEXTURE, ANT_CAVE_FLOOR_TEXTURE, ANT_CAVE_MINIMAP_TEXTURE, nil,
                ANT_CAVE_COLOUR_CUBE, nil, nil, "anthill","ANT_HIVE","DIRT")
        end

        interior_spawner:SpawnInterior(def)
    end
end

local function SetCurrentDoorHiddenStatus(door, show, direction)
    if not door.sg then
        print("MISSING sg FOR DIRECTION (" .. direction .. ") AND PREFAB (" .. door.prefab ..")")
        return
    end

    if show and door.components.door.hidden then
        door.sg:GoToState("open_" .. direction)
    elseif not show and not door.components.door.hidden then
        door.sg:GoToState("shut_" .. direction)
    end
end

local function RefreshCurrentDoor(room, door)
    if door.components.door then
        if door:HasTag("door_north") then
            SetCurrentDoorHiddenStatus(door, room.doorsEnabled[NORTH_DOOR_IDX], "north")
        elseif door:HasTag("door_south") then
            SetCurrentDoorHiddenStatus(door, room.doorsEnabled[SOUTH_DOOR_IDX], "south")
        elseif door:HasTag("door_east") then
            SetCurrentDoorHiddenStatus(door, room.doorsEnabled[EAST_DOOR_IDX], "east")
        elseif door:HasTag("door_west") then
            SetCurrentDoorHiddenStatus(door, room.doorsEnabled[WEST_DOOR_IDX], "west")
        end
    end
end

local function RefreshDoors(inst)
    local interior_spawner = TheWorld.components.interiorspawner
    for i = 1, NUM_ROWS do
        for j = 1, NUM_COLS do
            local room = inst.rooms[i][j]

            local interior = interior_spawner:GetInteriorByIndex(room.id)
            local x, y, z = interior.Transform:GetWorldPosition()
            local ents = TheSim:FindEntities(x, y, z, 50, {"interior_door"})
            for _, door in pairs(ents) do
                RefreshCurrentDoor(room, door)
            end
        end
    end
end

local function SpawnDust(inst, dustCount)
    if dustCount > 0 then
        local interior_spawner = GetWorld().components.interiorspawner

        local pt = interior_spawner:getSpawnOrigin()
        local fx = SpawnPrefab("int_ceiling_dust_fx")
        local VARIANCE = 8.0

        fx.Transform:SetPosition(pt.x + math.random(-VARIANCE, VARIANCE), 0.0, pt.z + math.random(-VARIANCE, VARIANCE))
        fx.Transform:SetScale(2.0, 2.0, 2.0)
        inst:DoTaskInTime(0.5, function() SpawnDust(inst, dustCount - 1) end)
    else
        inst:DoTaskInTime(0.5, function() inst.SoundEmitter:KillSound("miniearthquake") end)
    end
end

local function Earthquake(inst)
    -- local interior_spawner = TheWorld.components.interiorspawner

    -- for i = 1, NUM_ROWS do
    --     for j = 1, NUM_COLS do
    --         local room = inst.rooms[i][j]
    --     interior_spawner.interiorCamera:Shake("FULL", 5.0, 0.025, 0.8)
    --     inst.SoundEmitter:PlaySound("dontstarve/cave/earthquake", "miniearthquake")
    --     inst.SoundEmitter:SetParameter("miniearthquake", "intensity", 1)
    --     SpawnDust(inst, 10)
    --     end
    -- end
end

local function CreateInterior(inst)
    if inst.maze_generated then
        return
    end

    local queen_chamber_count = math.random(QUEEN_CHAMBER_COUNT_MIN, QUEEN_CHAMBER_COUNT_MAX)
    GenerateQueenChamberIDS(queen_chamber_count)
    BuildGrid(inst)
    CreateRegularRooms(inst)
    CreateQueenChambers(queen_chamber_count)
    BuildWalls(inst)
    RefreshDoors(inst)
    TheWorld.components.interiorspawner:AddExterior(inst)

    inst.maze_generated = true
end

local function GenerateMaze(inst)
    RebuildGrid(inst)
    BuildWalls(inst)
    RefreshDoors(inst)
    Earthquake(inst)
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
    data.maze_generated = inst.maze_generated
    data.interiorID = inst.interiorID
    if inst.rooms then
        data.rooms = inst.rooms

        -- parentRoom and exits are not necessary to save and cause the
        -- game to crash upon saving, so they are stripped out here.
        for i = 1, NUM_ROWS do
            for j = 1, NUM_COLS do
                data.rooms[i][j].parentRoom = nil
                data.rooms[i][j].exits = nil
            end
        end
    end
end

local function OnLoad(inst, data)
    if not data then
        return
    end

    if data.maze_generated then
        inst.maze_generated = data.maze_generated
    end

    if data.interiorID then
        inst.interiorID = data.interiorID
    end

    if data.rooms then
        inst.rooms = data.rooms
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
        if is_entrance then
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

        -- inst:AddComponent("childspawner")
        -- inst.components.childspawner.childname = "antman"
        -- inst.components.childspawner:SetRegenPeriod(TUNING.ANTMAN_REGEN_TIME)
        -- inst.components.childspawner:SetSpawnPeriod(TUNING.ANTMAN_RELEASE_TIME)
        -- inst.components.childspawner:SetMaxChildren(math.random(TUNING.ANTMAN_MIN, TUNING.ANTMAN_MAX))
        -- inst.components.childspawner:StartSpawning()

        inst:AddComponent("playerprox")
        inst.components.playerprox:SetDist(10, 13)

        inst:AddComponent("inspectable")
        inst.components.inspectable.getstatus = GetStatus
        inst.components.inspectable.nameoverride = "anthill"

        -- inst:AddComponent("door")
        -- inst.components.door.outside = true

        -- if is_entrance then
        --     inst:DoTaskInTime(0, CreateInterior)
        --     inst:DoPeriodicTask(TUNING.TOTAL_DAY_TIME / 3, GenerateMaze)
        --     inst.OnRemoveEntity = function()
        --         -- this is really bad but apparently can happen. But how....
        --         assert(false, "anthill got removed.  Please submit a bug report!")
        --     end
        -- end

        MakeSnowCovered(inst, 0.01)
        MakeHauntable(inst)

        -- inst.OnSave = OnSave
        -- inst.OnLoad = OnLoad
        -- inst.generateMaze = GenerateMaze

        return inst
    end

    return fn
end

return Prefab("anthill", makefn(true), assets, prefabs),
       Prefab("anthill_exit", makefn(false), assets, prefabs)
