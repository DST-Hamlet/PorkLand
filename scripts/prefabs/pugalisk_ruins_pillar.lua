local assets =
{
    Asset("ANIM", "anim/fountain_pillar.zip"),
    Asset("MINIMAP_IMAGE", "pig_ruins_pillar"),
}

local prefabs =
{
    "rocks"
}

SetSharedLootTable("pugalisk_pillar",
{
    {"rocks",  1.00},
    {"rocks",  1.00},
    {"rocks",  1.00},
    {"rocks",  0.25},
    {"rocks",  0.25},
    -- {"relic_2",  0.05},
})

local function OnFinishCallback(inst, worker)
    inst.SoundEmitter:PlaySound("dontstarve/common/destroy_stone")
    inst.AnimState:PlayAnimation("pillar_collapse")
    inst.AnimState:PushAnimation("pillar_collapsed")
    inst.components.lootdropper:DropLoot()
end

local function OnLoadPostPass(inst, ents, data)
    if inst.components.workable.workleft <= 0 then
        inst.AnimState:PlayAnimation("pillar_collapsed")
    end
end

local PUGALISK_FOUNTAIN_TAG = {"pugalisk_fountain"}
local FIND_FOUNTAIN_RANGE = 20
local function RotatePillar(inst)
    local fountain = GetClosestInstWithTag(PUGALISK_FOUNTAIN_TAG, inst, FIND_FOUNTAIN_RANGE)
    if fountain then
        local x, y, z = fountain.Transform:GetWorldPosition()
        local angle = inst:GetAngleToPoint(x, y ,z)
        inst.Transform:SetRotation(angle)
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    inst.AnimState:SetBuild("fountain_pillar")
    inst.AnimState:SetBank("fountain_pillar")
    inst.AnimState:PlayAnimation("pillar",true)

    inst.MiniMapEntity:SetIcon("pig_ruins_pillar.tex")

    inst.Transform:SetEightFaced()

    inst:AddTag("structure")
    inst:AddTag("pugalisk_pillar")

    MakeObstaclePhysics(inst, 0.5)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.MINE)
    inst.components.workable:SetWorkLeft(TUNING.PUGALISK_RUINS_PILLAR_WORK)
    inst.components.workable.savestate = true
    inst.components.workable:SetOnFinishCallback(OnFinishCallback)

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetChanceLootTable("pugalisk_pillar")

    MakeHauntable(inst)

    inst:DoTaskInTime(0, RotatePillar)

    inst.LoadPostPass = OnLoadPostPass

    return inst
end

return Prefab("pugalisk_ruins_pillar", fn, assets, prefabs)
