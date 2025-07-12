--TODO 让蝙蝠洞室内房间在下方有门时使用与roc洞穴链接时的黑色遮挡
--TODO 与roc的链接
--TODO 内部布局
local GenerateProps = require("prefabs/interior_prop_defs")

local BAT_CAVE_WIDTH = 26
local BAT_CAVE_HEIGHT = 10
local BAT_CAVE_DEPTH = 18
local BAT_CAVE_NUM_ROOMS = 3 --math.random(1, 3)
local BAT_CAVE_REVERB = "batcave"
local BAT_CAVE_AMBIENT = "BAT_CAVE"
local BAT_CAVE_GROUND_SOUND = WORLD_TILES.DIRT
local BAT_CAVE_FLOOR_TEXTURE = "levels/textures/interiors/batcave_floor.tex"
local BAT_CAVE_WALL_TEXTURE = "levels/textures/interiors/batcave_wall_rock.tex"
local BAT_CAVE_MINIMAP_TEXTURE = "levels/textures/map_interior/mini_vamp_cave_noise.tex"
local BAT_CAVE_COULOUR_CUBE = "images/colour_cubes/pigshop_interior_cc.tex"

local assets =
{
    Asset("ANIM", "anim/vamp_bat_entrance.zip"),
}

local prefabs =
{
    "vampirebat",
    "cave_fern",
}

local function BuildMaze(inst, exterior_door_def)
    local interior_spawner = TheWorld.components.interiorspawner

    local rooms = {
        {
            x = 0, -- x, y are used to keep track of the relative position of those rooms
            y = 0,
            id = exterior_door_def.target_interior,
            exits = {},
            blocked_exits = {interior_spawner:GetNorth()},
            is_entrance = true,
        },
    }

    while #rooms < BAT_CAVE_NUM_ROOMS do
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

    for _, room in ipairs(rooms) do
        local exits_open = {
            west = not room.exits[interior_spawner:GetWest()],
            south = not room.exits[interior_spawner:GetSouth()],
            east = not room.exits[interior_spawner:GetEast()]
        }

        local addprops = GenerateProps("vampirebatcave", exterior_door_def, BAT_CAVE_DEPTH, BAT_CAVE_WIDTH, room)
        interior_spawner:CreateRoom({
            width = BAT_CAVE_WIDTH,
            height = BAT_CAVE_HEIGHT,
            depth = BAT_CAVE_DEPTH,
            dungeon_name = "vampirebatcave",
            roomindex = room.id,
            addprops = addprops,
            exits = room.exits,
            walltexture = BAT_CAVE_WALL_TEXTURE,
            floortexture = BAT_CAVE_FLOOR_TEXTURE,
            minimaptexture = BAT_CAVE_MINIMAP_TEXTURE,
            colour_cube = BAT_CAVE_COULOUR_CUBE,
            --batted = true,
            reverb = BAT_CAVE_REVERB,
            ambient_sound = BAT_CAVE_AMBIENT,
            footstep_tile = BAT_CAVE_GROUND_SOUND,
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

    local name = "vampirebatcave" .. id
    local exterior_door_def = {
        my_door_id = name .. "_door",
        target_door_id = name .. "_exit",
        target_interior = id,
    }
    interior_spawner:AddDoor(inst, exterior_door_def)
    interior_spawner:AddExterior(inst)

    if can_reuse_interior then
        -- Reuse old interior, but we still need to re-register the door
        return
    end

    BuildMaze(inst, exterior_door_def)
end

local function OnSave(inst, data)
    data.interiorID = inst.interiorID
end

local function OnLoad(inst, data)
    if data and data.interiorID then
        inst.interiorID = data.interiorID
    end
    InitMaze(inst)
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    MakeObstaclePhysics(inst, 0.5)

    inst.AnimState:SetBank("vampbat_den")
    inst.AnimState:SetBuild("vamp_bat_entrance")
    inst.AnimState:PlayAnimation("idle")

    inst.MiniMapEntity:SetIcon("vamp_bat_cave.tex")

    inst:AddTag("batcave")
    inst:AddTag("client_forward_action_target")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("door")

    MakeSnowCovered(inst)

    --inst:DoTaskInTime(0, CreateInterior)

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad

    return inst
end

return Prefab("vampirebatcave", fn, assets, prefabs)
