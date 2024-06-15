local GetPropDef = require("prefabs/interior_prop_defs")

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
        ID = interior_spawner:GetCurrentMaxID() + 1
    end

    if inst.interiorID == nil then
        local newID = ID
        inst.interiorID = newID
        local name = "vampirebatcave" .. newID
        local height = 18
        local width = 26

        local exterior_door_def = {
            my_door_id = name .. newID .. "_door",
            target_door_id = name .. newID .. "_exit",
            target_interior = newID,
        }

        interior_spawner:AddDoor(inst, exterior_door_def)

        local floortexture = "levels/textures/interiors/batcave_floor.tex"
        local walltexture =  "levels/textures/interiors/batcave_wall_rock.tex"
        local minimaptexture = "levels/textures/map_interior/mini_vamp_cave_noise.tex"

        local addprops = GetPropDef("vampirebatcave", exterior_door_def, height, width)

        local def = interior_spawner:CreateRoom("generic_interior", width, 10, height, name, newID, addprops, {}, walltexture, floortexture, minimaptexture,
            nil, "images/colour_cubes/pigshop_interior_cc.tex", true, nil, "batcave","BAT_CAVE","DIRT", nil, nil, true)
        interior_spawner:SpawnInterior(def)
        inst:AddTag("spawned_cave")
    end
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
