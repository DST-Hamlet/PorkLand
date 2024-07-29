local assets =
{
    Asset("ANIM", "anim/lotus.zip"),
}

local function common()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)
    PorkLandMakeInventoryFloatable(inst)

    inst:AddTag("cattoy")
    inst:AddTag("billfood")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")

    inst:AddComponent("tradable")

    inst:AddComponent("stackable")
    inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM

    inst:AddComponent("edible")

    inst:AddComponent("perishable")

    inst:AddComponent("bait")

    MakeSmallBurnable(inst)
    MakeSmallPropagator(inst)
    MakeHauntableLaunchAndPerish(inst)
    MakeBlowInHurricane(inst, TUNING.WINDBLOWN_SCALE_MIN.LIGHT, TUNING.WINDBLOWN_SCALE_MAX.LIGHT)

    return inst
end

local function fn()
    local inst = common()

    inst.components.floater:UpdateAnimations("idle_water", "idle")

    inst.AnimState:SetBank("lotus")
    inst.AnimState:SetBuild("lotus")
    inst.AnimState:PlayAnimation("idle")

    if not TheWorld.ismastersim then
        return inst
    end

    inst.components.edible.healthvalue = TUNING.HEALING_TINY
    inst.components.edible.hungervalue = TUNING.CALORIES_SMALL
    inst.components.edible.sanityvalue = TUNING.SANITY_TINY
    inst.components.edible.foodtype = FOODTYPE.VEGGIE
    inst.components.edible.foodstate = "RAW"

    inst.components.perishable:SetPerishTime(TUNING.PERISH_MED)
    inst.components.perishable:StartPerishing()
    inst.components.perishable.onperishreplacement = "spoiled_food"

    inst:AddComponent("cookable")
    inst.components.cookable.product = "lotus_flower_cooked"

    return inst
end

local function cooked_fn()
    local inst = common()

    inst.components.floater:UpdateAnimations("cooked_water", "cooked")

    inst.AnimState:SetBank("lotus")
    inst.AnimState:SetBuild("lotus")
    inst.AnimState:PlayAnimation("cooked")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.components.edible.healthvalue = TUNING.HEALING_TINY
    inst.components.edible.hungervalue = TUNING.CALORIES_SMALL
    inst.components.edible.sanityvalue = TUNING.SANITY_MED
    inst.components.edible.foodtype = FOODTYPE.VEGGIE
    inst.components.edible.foodstate = "COOKED"

    inst.components.perishable:SetPerishTime(TUNING.PERISH_MED)
    inst.components.perishable:StartPerishing()
    inst.components.perishable.onperishreplacement = "spoiled_food"

    return inst
end

return Prefab("lotus_flower", fn, assets),
    Prefab("lotus_flower_cooked", cooked_fn, assets)
