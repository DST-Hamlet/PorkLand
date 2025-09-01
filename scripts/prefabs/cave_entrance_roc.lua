local GenerateProps = require("prefabs/interior_prop_defs")

local ROC_CAVE_NUM_ROOMS = 6
local ROC_CAVE_WIDTH = 24
local ROC_CAVE_HEIGHT = 10
local ROC_CAVE_DEPTH = 16
local ROC_CAVE_NAME = "roc_cave"
local ROC_CAVE_FLOOR_TEXTURE = "levels/textures/interiors/batcave_floor.tex"
local ROC_CAVE_WALL_TEXTURE = "levels/textures/interiors/batcave_wall_rock.tex"
local ROC_CAVE_MINIMAP_TEXTURE = "levels/textures/map_interior/mini_vamp_cave_noise.tex"
local ROC_CAVE_COULOUR_CUBE = "images/colour_cubes/pigshop_interior_cc.tex"
local ROC_CAVE_REVERB = "ruins"
local ROC_CAVE_AMBIENT = "BAT_CAVE"
local ROC_CAVE_GROUND_SOUND = WORLD_TILES.DIRT

local assets =
{
    Asset("ANIM", "anim/cave_entrance.zip"),
    Asset("ANIM", "anim/rock_batcave.zip"),
}

local prefabs =
{
    -- "roc_cave_light_beam",
}

local REMOVE_BLOCKERS_RAD = 50 -- enough to cover the bat cave
local BLOCKER_MUST_TAGS = {"roc_cave_delete_me"}

local function ConnectInteriors(inst)
    local interiorID = TheWorld.components.batted and TheWorld.components.batted:GetRandomBatCave()
    if not interiorID then
        return
    end

    local interior_spawner = TheWorld.components.interiorspawner

    local x, y, z = inst.Transform:GetWorldPosition()

    local door = SpawnPrefab("prop_door")
    door.entity:AddMiniMapEntity()

    door.AnimState:SetBank("ant_cave_door")
    door.AnimState:SetBuild("ant_cave_door")
    door.AnimState:PlayAnimation("north")

    door.Transform:SetPosition(x, y, z)

    door.MiniMapEntity:SetIcon("ant_cave_door.tex")

    door.minimapicon = "ant_cave_door.tex"
    door.door_data_bank = "ant_cave_door"
    door.door_data_build = "ant_cave_door"
    door.door_data_animstate = "north"

    local prefab_door_def = -- This door leads to the bat cave
    {
        my_door_id =  "roc_cave_EXIT2",
        target_door_id = "roc_cave_ENTRANCE2",
        target_interior = interiorID,
        animdata = {
            minimapicon = "ant_cave_door.tex",
            bank = "ant_cave_door",
            build = "ant_cave_door",
            anim = "north",
            background = true,
            is_exit = true,
        }
    }

    local interior_door_def =
    {
        unique_name = inst:GetCurrentInteriorID()
    }

    door:initInteriorPrefab(nil, prefab_door_def, interior_door_def)

    --interior_spawner:AddDoor(door, interior_door_def) -- 亚丹：在InitInteriorPrefab 中已经执行

    local target_interior_center = interior_spawner:GetInteriorCenter(interiorID) -- center of bat cave

    local door_pos
    local blocker = FindEntity(target_interior_center, REMOVE_BLOCKERS_RAD, nil, BLOCKER_MUST_TAGS)
    if blocker then
        door_pos = blocker:GetPosition()
        blocker:Remove()
    end

    if not door_pos then
        return
    end

    local door_replacement = SpawnPrefab("prop_door")
    door_replacement.entity:AddMiniMapEntity()

    door_replacement.AnimState:SetBank("ant_cave_door")
    door_replacement.AnimState:SetBuild("ant_cave_door")
    door_replacement.AnimState:PlayAnimation("south")

    door_replacement.Transform:SetPosition(door_pos.x, door_pos.y, door_pos.z)

    door_replacement.MiniMapEntity:SetIcon("ant_cave_door.tex")

    door_replacement.minimapicon = "ant_cave_door.tex"
    door_replacement.door_data_animstate = "south"
    door_replacement.door_data_bank = "ant_cave_door"
    door_replacement.door_data_build = "ant_cave_door"

    local prefab_door_replacement_def = -- This door leads to the bat cave
    {
        my_door_id = "roc_cave_ENTRANCE2",
        target_door_id = "roc_cave_EXIT2",
        target_interior = inst:GetCurrentInteriorID(),
        animdata = {
            minimapicon = "ant_cave_door.tex",
            bank = "ant_cave_door",
            build = "ant_cave_door",
            anim = "south",
            background = true,
            is_exit = true,
        },
        addtags = {"door_south"}
    }

    local interior_door_replacement_def =
    {
        unique_name = interiorID
    }

    door_replacement:initInteriorPrefab(nil, prefab_door_replacement_def, interior_door_replacement_def)

    -- interior_spawner:AddDoor(door_replacement, data_replacement)

    local shadow = SpawnPrefab("prop_door_shadow")
    shadow.Transform:SetPosition(door_pos.x, door_pos.y, door_pos.z)
    shadow.AnimState:SetBank("ant_cave_door")
    shadow.AnimState:SetBuild("ant_cave_door")
    shadow.Transform:SetRotation(-90)
    shadow.AnimState:PlayAnimation("south_floor")
end

local function Open(inst)
    inst.AnimState:PlayAnimation("open", true)
    inst.AnimState:SetLayer(LAYER_BACKGROUND)

    inst:RemoveComponent("workable")
    inst:RemoveComponent("lootdropper")

    inst.open = true
    inst.name = STRINGS.NAMES.CAVE_ENTRANCE_OPEN

    inst.MiniMapEntity:SetIcon("cave_open.png")

    inst.components.door:SetDoorDisabled(false, "plug")
end

local function OnWorkCallbackEntrance(inst, worker, workleft)
    if workleft <= 0 then
        inst.SoundEmitter:PlaySound("dontstarve/wilson/rock_break")
        inst.components.lootdropper:DropLoot()
        Open(inst)
    else
        if workleft < TUNING.ROCKS_MINE * (1 / 3) then
            inst.AnimState:PlayAnimation("low")
        elseif workleft < TUNING.ROCKS_MINE * (2 / 3) then
            inst.AnimState:PlayAnimation("med")
        else
            inst.AnimState:PlayAnimation("idle_closed")
        end
    end
end

local function OnWorkCallbackExit(inst, worker, work_left)
    if work_left > 0 then
        if work_left < TUNING.ROCKS_MINE * (1 / 3) then
            inst.AnimState:PlayAnimation("low")
        elseif work_left < TUNING.ROCKS_MINE * (2 / 3) then
            inst.AnimState:PlayAnimation("med")
        else
            inst.AnimState:PlayAnimation("full")
        end
        return
    end

    local x, y, z = inst.Transform:GetWorldPosition()
    local fx = SpawnPrefab("collapse_big")
    fx.Transform:SetPosition(x, y, z)
    fx:SetMaterial("stone")

    inst.components.lootdropper:DropLoot()
    inst.SoundEmitter:PlaySound("dontstarve/wilson/rock_break")

    TheWorld:PushEvent("interior_startquake", {
        interiorID = inst:GetCurrentInteriorID(),
        quake_level = INTERIOR_QUAKE_LEVELS.PILLAR_WORKED,
    })

    ConnectInteriors(inst)

    inst:Remove()
end

local function Close(inst)
    inst.AnimState:PlayAnimation("idle_closed", true)

    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.MINE)
    inst.components.workable:SetWorkLeft(TUNING.ROCKS_MINE)
    inst.components.workable:SetOnWorkCallback(OnWorkCallbackEntrance)

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetLoot({"rocks", "rocks", "flint", "flint", "flint"})

    inst.name = STRINGS.NAMES.CAVE_ENTRANCE

    inst.open = false

   inst.components.door:SetDoorDisabled(true, "plug")
end

local function GetStatus(inst)
    if inst.open then
        return "OPEN"
    end
end

local function BuildMaze(inst, exterior_door_def)
    local interior_spawner = TheWorld.components.interiorspawner

    local id = inst.interiorID
    local rooms = {
        {
            x = 0, -- x, y are used to keep track of the relative position of those rooms
            y = 0,
            id = id,
            exits = {},
            blocked_exits = {},
            is_entrance_room = true, -- this is the room you enter from the roc island
        },
    }
    exterior_door_def.target_interior = id

    while #rooms < ROC_CAVE_NUM_ROOMS do
        local dir = interior_spawner:GetDir()
        local dir_opposite = interior_spawner:GetDirOpposite()
        local dir_choice = math.random(#dir)
        local room_connecting_to = rooms[math.random(#rooms)] -- the room this new room will be connecting to

        local failed = false

        -- fail if this direction from the chosen room is blocked
        for _, exit in pairs(room_connecting_to.blocked_exits) do
            if dir[dir_choice] == exit then
                failed = true
            end
        end

        -- fail if this room of the maze is already set up.
        if not failed then
            for _, room_to_check in pairs(rooms) do
                if room_to_check.x == room_connecting_to.x + dir[dir_choice].x
                    and room_to_check.y == room_connecting_to.y + dir[dir_choice].y then
                    failed = true
                    break
                end
            end
        end

        if not failed then
            local newroom = {
                x = room_connecting_to.x + dir[dir_choice].x,
                y = room_connecting_to.y + dir[dir_choice].y,
                id = interior_spawner:GetNewID(),
                exits = {},
                blocked_exits = {},
            }

            room_connecting_to.exits[dir[dir_choice]] = {
                target_room = newroom.id,
                bank  = "ant_cave_door",
                build = "ant_cave_door",
                room = room_connecting_to.id,
            }

            newroom.exits[dir_opposite[dir_choice]] = {
                target_room = room_connecting_to.id,
                bank  = "ant_cave_door",
                build = "ant_cave_door",
                room = newroom.id,
            }

            table.insert(rooms, newroom)
        end
    end

    local available_exits = {}
    for i, room in ipairs(rooms) do
        if i > 1 then -- skipping first one since it is the entrance
            if not room.exits[interior_spawner:GetNorth()] then -- The exit to bat cave is always at the top(north) of the room
                table.insert(available_exits, room)
            end
        end
    end
    GetRandomItem(available_exits).is_exit_room = true -- make this room connect to the bat cave

    for _, room in ipairs(rooms) do
        local exits_open = {
            west = not room.exits[interior_spawner:GetWest()],
            south = not room.exits[interior_spawner:GetSouth()],
            east = not room.exits[interior_spawner:GetEast()]
        }

        local addprops = GenerateProps(ROC_CAVE_NAME, ROC_CAVE_DEPTH, ROC_CAVE_WIDTH, room, exits_open, exterior_door_def)
        interior_spawner:CreateRoom({
            width = ROC_CAVE_WIDTH,
            height = ROC_CAVE_HEIGHT,
            depth = ROC_CAVE_DEPTH,
            dungeon_name = ROC_CAVE_NAME,
            roomindex = room.id,
            addprops = addprops,
            exits = room.exits,
            walltexture = ROC_CAVE_WALL_TEXTURE,
            floortexture = ROC_CAVE_FLOOR_TEXTURE,
            minimaptexture = ROC_CAVE_MINIMAP_TEXTURE,
            colour_cube = ROC_CAVE_COULOUR_CUBE,
            reverb = ROC_CAVE_REVERB,
            ambient_sound = ROC_CAVE_AMBIENT,
            footstep_tile = ROC_CAVE_GROUND_SOUND,
            cameraoffset = nil,
            zoom = nil,
            group_id = inst.interiorID,
            interior_coordinate_x = room.x,
            interior_coordinate_y = room.y,
        })
    end

    return rooms[1] -- entrance_room
end

local function InitMaze(inst)
    local id = inst.interiorID
    local can_reuse_interior = id ~= nil

    local interior_spawner = TheWorld.components.interiorspawner
    if not can_reuse_interior then
        id = interior_spawner:GetNewID()
        inst.interiorID = id
    end
    local exterior_door_def = {
        my_door_id = ROC_CAVE_NAME .. "_ENTRANCE1",
        target_door_id = ROC_CAVE_NAME .. "_EXIT1",
        target_interior = inst.interiorID
    }
    TheWorld.components.interiorspawner:AddDoor(inst, exterior_door_def)
    TheWorld.components.interiorspawner:AddExterior(inst)

    if can_reuse_interior then
        -- Reuse old interior, but we still need to re-register the door
        return
    end

    BuildMaze(inst, exterior_door_def)
end

local function OnSave(inst, data)
    data.open = inst.open
    data.interiorID = inst.interiorID
end

local function OnLoad(inst, data)
    if data and data.interiorID then
        inst.interiorID = data.interiorID
    end
    InitMaze(inst)
    if data and data.open then
        Open(inst)
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    MakeObstaclePhysics(inst, 1)

    inst.AnimState:SetBank("cave_entrance")
    inst.AnimState:SetBuild("cave_entrance")

    inst.MiniMapEntity:SetIcon("cave_closed.png")

    inst:AddTag("client_forward_action_target")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("door")

    inst:AddComponent("inspectable")
    inst.components.inspectable.getstatus = GetStatus
    inst.components.inspectable.nameoverride = "CAVE_ENTRANCE"

    Close(inst)

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad

    return inst
end

local function exitfn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    MakeObstaclePhysics(inst, 1)

    inst.AnimState:SetBank("rock_batcave")
    inst.AnimState:SetBuild("rock_batcave")
    inst.AnimState:PlayAnimation("full")

    inst.MiniMapEntity:SetIcon("rock_batcave.tex")

    inst:AddTag("client_forward_action_target")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetChanceLootTable("rock1")
    -- inst.components.lootdropper.alwaysinfront = true

    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.MINE)
    inst.components.workable:SetWorkLeft(TUNING.ROCKS_MINE)

    inst.components.workable:SetOnWorkCallback(OnWorkCallbackExit)

    inst:AddComponent("inspectable")
    inst.components.inspectable.nameoverride = "ROCK"

    MakeSnowCovered(inst, 0.01)
    MakeHauntable(inst)

    return inst
end

return Prefab("cave_entrance_roc", fn, assets, prefabs),
       Prefab("cave_exit_roc", exitfn, assets, prefabs)
