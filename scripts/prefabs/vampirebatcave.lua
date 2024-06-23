local GetPropDef = require("prefabs/interior_prop_defs")

local BAT_CAVE_NAME = "batcave"
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

local function OnSave(inst, data)
    data.interiorID = inst.interiorID
end

local function OnLoad(inst, data)
    if data then
        inst.interiorID = data.interiorID
    end
end

local function CreatInterior(inst)
    local interior_spawner = TheWorld.components.interiorspawner
    local ID = inst.interiorID
    if not ID then
        ID = interior_spawner:GetNewID()
    end

    if not inst.interiorID == nil then
        return
    end

    local newID = ID
    inst.interiorID = newID
    local name = "vampirebatcave" .. newID

    local exterior_door_def = {
        my_door_id = name .. "_door",
        target_door_id = name .. "_exit",
        target_interior = newID,
    }

    interior_spawner:AddDoor(inst, exterior_door_def)

    local addprops = GetPropDef("vampirebatcave", exterior_door_def, BAT_CAVE_DEPTH, BAT_CAVE_WIDTH)
    local def = interior_spawner:CreateRoom(BAT_CAVE_NAME, BAT_CAVE_WIDTH, 10, BAT_CAVE_DEPTH, name, newID, addprops, {},
        BAT_CAVE_WALL_TEXTURE, BAT_CAVE_FLOOR_TEXTURE, BAT_CAVE_MINIMAP_TEXTURE, nil, BAT_CAVE_COULOUR_CUBE, true, nil,
        BAT_CAVE_REVERB, BAT_CAVE_AMBIENT, BAT_CAVE_GROUND_SOUND, nil, nil, true)
    interior_spawner:SpawnInterior(def)
    inst:AddTag("spawned_cave")
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

    TheWorld.components.interiorspawner:AddExterior(inst)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("door")
    inst.components.door.outside = true

    MakeSnowCovered(inst)

    inst:DoTaskInTime(0, CreatInterior)

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad

    return inst
end

return Prefab("vampirebatcave", fn, assets, prefabs)
