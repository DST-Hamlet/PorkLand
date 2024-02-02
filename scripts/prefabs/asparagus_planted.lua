local assets =
{
    Asset("ANIM", "anim/asparagus_planted.zip"),
}

local prefabs =
{
    "asparagus",
}

local function fn()
    -- Asparagus you eat is defined in veggies.lua
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    inst.Transform:SetScale(1.3, 1.3, 1.3)

    inst.AnimState:SetBank("asparagus_planted")
    inst.AnimState:SetBuild("asparagus_planted")
    inst.AnimState:PlayAnimation("idle")
    inst.AnimState:SetRayTestOnBB(true)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("pickable")
    inst.components.pickable.picksound = "dontstarve/wilson/pickup_plants"
    inst.components.pickable:SetUp("asparagus", 10)
    inst.components.pickable.remove_when_picked = true
    inst.components.pickable.quickpick = true

    MakeSmallBurnable(inst)
    MakeSmallPropagator(inst)
    AddToRegrowthManager(inst)

    inst:AddComponent("hauntable")
    inst.components.hauntable:SetHauntValue(TUNING.HAUNT_TINY)

    return inst
end

return Prefab("common/inventory/asparagus_planted", fn, assets, prefabs)
