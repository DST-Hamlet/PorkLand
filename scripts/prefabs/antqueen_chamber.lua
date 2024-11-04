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

local QUEEN_CHAMBER_COUNT_MAX = 6
local QUEEN_CHAMBER_COUNT_MIN = 3

local ANT_CAVE_DEPTH = 18
local ANT_CAVE_WIDTH = 26
local ANT_CAVE_HEIGHT = 7
local ANT_CAVE_FLOOR_TEXTURE = "levels/textures/interiors/antcave_floor.tex"
local ANT_CAVE_WALL_TEXTURE = "levels/textures/interiors/antcave_wall_rock.tex"
local ANT_CAVE_MINIMAP_TEXTURE = "levels/textures/map_interior/mini_antcave_floor.tex"
local ANT_CAVE_COLOUR_CUBE = "images/colour_cubes/pigshop_interior_cc.tex"

local queen_chamber_ids = {}
local queenchamber_placement_id = nil

-- We generate these outside of the CreateQueenChambers function because we need the ids to link it to the regular anthill
local function GenerateQueenChamberIDS(room_count)
    local interior_spawner = TheWorld.components.interiorspawner

    for i = 1, room_count do
        local newid = interior_spawner:GetNewID()
        table.insert(queen_chamber_ids, newid)
    end
end

local function CreateQueenChambers(inst, room_count)
    local interior_spawner = TheWorld.components.interiorspawner

    for i = 1, room_count do
        local is_queen_chamber = i == room_count -- last room is ant queen room

        if is_queen_chamber then
            local addprops = GenerateProps("anthill_queen_chamber", ANT_CAVE_DEPTH, ANT_CAVE_WIDTH, i, queen_chamber_ids)

            interior_spawner:CreateRoom({
                width = ANT_CAVE_WIDTH,
                height = ANT_CAVE_HEIGHT,
                depth = ANT_CAVE_DEPTH,
                dungeon_name = "QUEEN_CHAMBERS_DUNGEON_" .. i,
                roomindex = queen_chamber_ids[i],
                addprops = addprops,
                exits = {},
                walltexture = ANT_CAVE_WALL_TEXTURE,
                floortexture = ANT_CAVE_FLOOR_TEXTURE,
                minimaptexture = ANT_CAVE_MINIMAP_TEXTURE,
                cityID = nil,
                colour_cube = ANT_CAVE_COLOUR_CUBE,
                batted = nil,
                playerroom = nil,
                reverb = "anthill",
                ambient_sound = "ANT_HIVE",
                footstep_tile = WORLD_TILES.DIRT,
                cameraoffset = -3.5,
                zoom = 40,
                forceInteriorMinimap = nil
            })
        else
            local addprops = GenerateProps("anthill_queen_chamber_hallway", ANT_CAVE_DEPTH, ANT_CAVE_WIDTH, i, queen_chamber_ids)

            interior_spawner:CreateRoom({
                width = ANT_CAVE_WIDTH,
                height = ANT_CAVE_HEIGHT,
                depth = ANT_CAVE_DEPTH,
                dungeon_name = "QUEEN_CHAMBERS_DUNGEON_" .. i,
                roomindex = queen_chamber_ids[i],
                addprops = addprops,
                exits = {},
                walltexture = ANT_CAVE_WALL_TEXTURE,
                floortexture = ANT_CAVE_FLOOR_TEXTURE,
                minimaptexture = ANT_CAVE_MINIMAP_TEXTURE,
                cityID = nil,
                colour_cube = ANT_CAVE_COLOUR_CUBE,
                batted = nil,
                playerroom = nil,
                reverb = "anthill",
                ambient_sound = "ANT_HIVE",
                footstep_tile = WORLD_TILES.DIRT,
                cameraoffset = nil,
                zoom = nil,
                forceInteriorMinimap = nil
            })
        end

        if is_queen_chamber then
            local center_ent = interior_spawner:GetInteriorCenter(queen_chamber_ids[i])
            center_ent:AddInteriorTags("antqueen") -- need this antman_warrior_egg
        end
    end
end

local function CreateInterior(inst)
    if inst.maze_generated then
        return
    end

    local queen_chamber_count = math.random(QUEEN_CHAMBER_COUNT_MIN, QUEEN_CHAMBER_COUNT_MAX)
    GenerateQueenChamberIDS(queen_chamber_count)
    CreateQueenChambers(inst, queen_chamber_count)

    local exterior_door_def = {
        my_door_id = "ANTQUEEN_CHAMBERS_ENTRANCE",
        target_door_id = "ANTQUEEN_CHAMBERS_EXIT",
        target_interior = queen_chamber_ids[1],
    }

    inst.interiorID = queen_chamber_ids[1]
    TheWorld.components.interiorspawner:AddDoor(inst, exterior_door_def)
    TheWorld.components.interiorspawner:AddExterior(inst)

    inst.maze_generated = true
end

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

        -- parent_room and exits are not necessary to save and cause the
        -- game to crash upon saving, so they are stripped out here.
        for i = 1, NUM_ROWS do
            for j = 1, NUM_COLS do
                data.rooms[i][j].parent_room = nil
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
        TheWorld.components.interiorspawner:AddExterior(inst)
    end
    CreateInterior(inst)

    if data.rooms then
        inst.rooms = data.rooms
    end
end

local function makefn()
    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddLight()
        inst.entity:AddSoundEmitter()
        inst.entity:AddMiniMapEntity()
        inst.entity:AddNetwork()

        MakeObstaclePhysics(inst, 2)

        inst.AnimState:SetBank("entrance")
        inst.AnimState:SetBuild("ant_queen_entrance")
        inst.AnimState:PlayAnimation("idle", true)

        inst.Light:SetFalloff(1)
        inst.Light:SetIntensity(0.5)
        inst.Light:SetRadius(1)
        inst.Light:Enable(false)
        inst.Light:SetColour(180 / 255, 195 / 255, 50 / 255)

        inst.MiniMapEntity:SetIcon("ant_queen_entrance.tex")

        inst.Transform:SetScale(0.8, 0.8, 0.8)

        inst:AddTag("structure")
        inst:AddTag("chamber_entrance")
        inst:AddTag("client_forward_action_target")

        inst.name = STRINGS.NAMES.ANTQUEEN_CHAMBERS

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        inst:AddComponent("lootdropper")

        inst:AddComponent("playerprox")
        inst.components.playerprox:SetDist(10, 13)

        inst:AddComponent("inspectable")
        inst.components.inspectable.getstatus = GetStatus
        inst.components.inspectable.nameoverride = "anthill"

        inst:AddComponent("door")
        inst.components.door.outside = true

        inst:DoTaskInTime(0, function()
            if inst.interiorID == nil then
                CreateInterior(inst)
            end
        end)

        MakeSnowCovered(inst, 0.01)

        inst.OnSave = OnSave
        inst.OnLoad = OnLoad

        return inst
    end

    return fn
end

return Prefab("antqueen_chamber_entrance", makefn(), assets, prefabs)
