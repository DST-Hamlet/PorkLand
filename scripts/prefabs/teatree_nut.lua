local assets =
{
    Asset("ANIM", "anim/teatree_nut.zip"),
}

local prefabs =
{
    "spoiled_food"
}

local function Plant(point)
    local sapling = SpawnPrefab("teatree_nut_sapling")
    sapling:StartGrowing()
    sapling.Transform:SetPosition(point:Get())
    sapling.SoundEmitter:PlaySound("dontstarve/wilson/plant_tree")
end

local function OnDeploy(inst, point)
    inst = inst.components.stackable:Get()
    inst:Remove()

    Plant(point)
end

local function common()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    MakeInventoryFloatable(inst)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("bait")

    inst:AddComponent("tradable")

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")

    inst:AddComponent("perishable")

    inst:AddComponent("edible")
    inst.components.edible.foodtype = FOODTYPE.SEEDS
    inst.components.perishable.onperishreplacement = "spoiled_food"


    inst:AddComponent("stackable")
    inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM

    MakeSmallBurnable(inst, TUNING.SMALL_BURNTIME)
    MakeSmallPropagator(inst)
    MakeBlowInHurricane(inst, TUNING.WINDBLOWN_SCALE_MIN.MEDIUM, TUNING.WINDBLOWN_SCALE_MAX.MEDIUM)

    return inst
end

local function seed_fn()
    local inst = common()

    inst.AnimState:SetBank("teatree_nut")
    inst.AnimState:SetBuild("teatree_nut")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("plant")
    inst:AddTag("icebox_valid")
    inst:AddTag("cattoy")
    inst:AddTag("show_spoilage")

    inst.components.floater:UpdateAnimations("idle_water", "idle")

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("cookable")
    inst.components.cookable.product = "teatree_nut_cooked"

    inst.components.perishable:SetPerishTime(TUNING.PERISH_PRESERVED)
    inst.components.perishable:StartPerishing()

    inst.components.edible.hungervalue = TUNING.CALORIES_TINY
    inst.components.edible.healthvalue = TUNING.HEALING_TINY
    inst.components.edible.antihistamine = 60

    inst:AddComponent("deployable")
    inst.components.deployable:SetDeployMode(DEPLOYMODE.PLANT)
    inst.components.deployable.ondeploy = OnDeploy

    MakeHauntableLaunchAndPerish(inst)

    return inst
end

local function cooked_fn()
    local inst = common()

    inst.AnimState:SetBank("teatree_nut")
    inst.AnimState:SetBuild("teatree_nut")
    inst.AnimState:PlayAnimation("cooked")

    inst.components.floater:UpdateAnimations("cooked_water", "cooked")

    if not TheWorld.ismastersim then
        return inst
    end

    inst.components.edible.hungervalue = TUNING.CALORIES_TINY
    inst.components.edible.healthvalue = TUNING.HEALING_SMALL
    inst.components.edible.antihistamine = 120
    inst.components.edible.foodtype = FOODTYPE.SEEDS

    inst.components.perishable:SetPerishTime(TUNING.PERISH_FAST)
    inst.components.perishable:StartPerishing()
    inst.components.perishable.onperishreplacement = "spoiled_food"

    MakeHauntableLaunch(inst)

    return inst
end

return Prefab("teatree_nut", seed_fn, assets, prefabs),
       Prefab("teatree_nut_cooked", cooked_fn, assets),
       MakePlacer("teatree_nut_placer", "teatree_nut", "teatree_nut", "idle_planted")
