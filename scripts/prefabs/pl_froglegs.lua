local assets_poison =
{
    Asset("ANIM", "anim/frog_legs_tree.zip"),
}

local prefabs_poison =
{
    "froglegs_poison_cooked",
}

local function oneaten(inst, eater)
    if eater.components.poisonable and eater:HasTag("poisonable") then
        eater.components.poisonable:Poison(nil, nil, nil, true)
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()

    inst.AnimState:SetBank("frog_legs")
    inst.AnimState:SetBuild("frog_legs_tree")
    inst.AnimState:PlayAnimation("idle")

    MakeInventoryPhysics(inst)
    MakeInventoryFloatable(inst)
    inst.components.floater:UpdateAnimations("idle_water", "idle")

    inst:AddTag("smallmeat")
    inst:AddTag("fishmeat")
    inst:AddTag("catfood")
    inst:AddTag("poisonous")
    inst:AddTag("dryable")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("edible")
    inst.components.edible.foodtype = "MEAT"
    inst.components.edible.healthvalue = 0
    inst.components.edible.hungervalue = TUNING.CALORIES_SMALL
    inst.components.edible.sanityvalue = -TUNING.SANITY_SMALL
    inst.components.edible:SetOnEatenFn(oneaten)

    inst:AddComponent("perishable")
    inst.components.perishable:SetPerishTime(TUNING.PERISH_FAST)
    inst.components.perishable:StartPerishing()
    inst.components.perishable.onperishreplacement = "spoiled_food"

    inst:AddComponent("stackable")
    inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM

    inst:AddComponent("bait")

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")

    inst:AddComponent("tradable")
    inst.components.tradable.goldvalue = 0

    inst:AddComponent("cookable")
    inst.components.cookable.product = "froglegs_poison_cooked"

    inst:AddComponent("dryable")
    inst.components.dryable:SetProduct("smallmeat_dried")
    inst.components.dryable:SetDryTime(TUNING.DRY_FAST)

    MakeHauntableLaunchAndPerish(inst)
    MakeBlowInHurricane(inst, TUNING.WINDBLOWN_SCALE_MIN.MEDIUM, TUNING.WINDBLOWN_SCALE_MAX.MEDIUM)

    return inst
end

local function cookedfn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)
    MakeInventoryFloatable(inst)
    inst.components.floater:UpdateAnimations("idle_cooked_water", "cooked")

    inst.AnimState:SetBank("frog_legs")
    inst.AnimState:SetBuild("frog_legs_tree")
    inst.AnimState:PlayAnimation("cooked")

    inst:AddTag("poisonous")
    inst:AddTag("smallmeat")
    inst:AddTag("fishmeat")
    inst:AddTag("catfood")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("edible")
    inst.components.edible.foodtype = "MEAT"
    inst.components.edible.foodstate = "COOKED"
    inst.components.edible.healthvalue = TUNING.HEALING_TINY
    inst.components.edible.hungervalue = TUNING.CALORIES_SMALL
    inst.components.edible.sanityvalue = -TUNING.SANITY_SMALL
    inst.components.edible:SetOnEatenFn(oneaten)

    inst:AddComponent("perishable")
    inst.components.perishable:SetPerishTime(TUNING.PERISH_MED)
    inst.components.perishable:StartPerishing()
    inst.components.perishable.onperishreplacement = "spoiled_food"

    inst:AddComponent("stackable")
    inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM

    inst:AddComponent("bait")

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")

    inst:AddComponent("tradable")
    inst.components.tradable.goldvalue = 0

    MakeHauntableLaunchAndPerish(inst)
    MakeBlowInHurricane(inst, TUNING.WINDBLOWN_SCALE_MIN.MEDIUM, TUNING.WINDBLOWN_SCALE_MAX.MEDIUM)

    return inst
end

return Prefab("froglegs_poison", fn, assets_poison, prefabs_poison),
       Prefab("froglegs_poison_cooked", cookedfn, assets_poison)
