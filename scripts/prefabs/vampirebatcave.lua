local GetPropDef = require("prefabs/interior_prop_defs")

local BAT_CAVE_WIDTH = 26
local BAT_CAVE_DEPTH = 18
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

local function CreateInterior(inst)
    local id = inst.interiorID
    local can_reuse_interior = id ~= nil

    local interior_spawner = TheWorld.components.interiorspawner
    if not can_reuse_interior then
        id = interior_spawner:GetNewID()
        inst.interiorID = id
        print("CreateInterior id:", id)
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

    local addprops = GetPropDef("vampirebatcave", exterior_door_def, BAT_CAVE_DEPTH, BAT_CAVE_WIDTH)
    interior_spawner:CreateRoom({
        width = BAT_CAVE_WIDTH,
        height = 10,
        depth = BAT_CAVE_DEPTH,
        dungeon_name = name,
        roomindex = id,
        addprops = addprops,
        exits = {},
        walltexture = BAT_CAVE_WALL_TEXTURE,
        floortexture = BAT_CAVE_FLOOR_TEXTURE,
        minimaptexture = BAT_CAVE_MINIMAP_TEXTURE,
        colour_cube = BAT_CAVE_COULOUR_CUBE,
        batted = true,
        reverb = BAT_CAVE_REVERB,
        ambient_sound = BAT_CAVE_AMBIENT,
        footstep_tile = BAT_CAVE_GROUND_SOUND,
        cameraoffset = nil,
        zoom = nil,
        forceInteriorMinimap = true,
        group_id = inst.interiorID,
        interior_coordinate_x = 0,
        interior_coordinate_y = 0,
    })
    inst:AddTag("spawned_cave")
end

local function OnSave(inst, data)
    data.interiorID = inst.interiorID
end

local function OnLoad(inst, data)
    if data then
        inst.interiorID = data.interiorID
    end
    CreateInterior(inst)
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
