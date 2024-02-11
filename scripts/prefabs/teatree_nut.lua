require "prefabutil"

local assets =
{
    Asset("ANIM", "anim/teatree_nut.zip"),
}

local prefabs =
{
    "spoiled_food"
}

local function plant(point)
    local sapling = SpawnPrefab("teatree_nut_sapling")
    sapling:StartGrowing()
    sapling.Transform:SetPosition(point:Get())
    sapling.SoundEmitter:PlaySound("dontstarve/wilson/plant_tree")
end

local function ondeploy(inst, point)
    inst = inst.components.stackable:Get()
    inst:Remove()

    plant(point)
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("teatree_nut")
    inst.AnimState:SetBuild("teatree_nut")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("plant")
    inst:AddTag("icebox_valid")
    inst:AddTag("cattoy")
    inst:AddTag("show_spoilage")

    MakeInventoryFloatable(inst)
    inst.components.floater:UpdateAnimations("idle_water", "idle")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("cookable")
    inst.components.cookable.product = "teatree_nut_cooked"

    inst:AddComponent("tradable")

    inst:AddComponent("perishable")
    inst.components.perishable:SetPerishTime(TUNING.PERISH_PRESERVED)
    inst.components.perishable:StartPerishing()
    inst.components.perishable.onperishreplacement = "spoiled_food"

    inst:AddComponent("edible")
    inst.components.edible.hungervalue = TUNING.CALORIES_TINY
    inst.components.edible.healthvalue = TUNING.HEALING_TINY
    inst.components.edible.antihistamine = 60
    inst.components.edible.foodtype = "SEEDS"
    inst.components.edible.foodstate = "RAW"

    inst:AddComponent("bait")

    inst:AddComponent("stackable")
    inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")

    inst:AddComponent("deployable")
    inst.components.deployable:SetDeployMode(DEPLOYMODE.PLANT)
    inst.components.deployable.ondeploy = ondeploy

    MakeSmallBurnable(inst, TUNING.SMALL_BURNTIME)
    MakeSmallPropagator(inst)
    MakeBlowInHurricane(inst, TUNING.WINDBLOWN_SCALE_MIN.MEDIUM, TUNING.WINDBLOWN_SCALE_MAX.MEDIUM)

    return inst
end

local function fn_cooked()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("teatree_nut")
    inst.AnimState:SetBuild("teatree_nut")
    inst.AnimState:PlayAnimation("cooked")

    MakeInventoryFloatable(inst)
    inst.components.floater:UpdateAnimations("cooked_water", "cooked")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("edible")
    inst.components.edible.foodstate = "COOKED"
    inst.components.edible.hungervalue = TUNING.CALORIES_TINY
    inst.components.edible.healthvalue = TUNING.HEALING_SMALL
    inst.components.edible.antihistamine = 120
    inst.components.edible.foodtype = "SEEDS"

    inst:AddComponent("perishable")
    inst.components.perishable:SetPerishTime(TUNING.PERISH_FAST)
    inst.components.perishable:StartPerishing()
    inst.components.perishable.onperishreplacement = "spoiled_food"

    inst:AddComponent("stackable")
    inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")

    MakeSmallBurnable(inst, TUNING.SMALL_BURNTIME)
    MakeSmallPropagator(inst)

    return inst
end

return Prefab("teatree_nut", fn, assets, prefabs),
       Prefab("teatree_nut_cooked", fn_cooked, assets),
       MakePlacer("teatree_nut_placer", "teatree_nut", "teatree_nut", "idle_planted")
