local assets =
{
    Asset("ANIM", "anim/tuber_crop.zip"),
    Asset("ANIM", "anim/tuber_bloom_crop.zip"),
}

local function oneaten(inst, eater)
    if eater.components.poisonable and eater:HasTag("poisonable") then
        eater.components.poisonable:Poison()
    end
end

local function fn(Sim)
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    MakeInventoryFloatable(inst, "idle_water", "idle")

    inst.AnimState:SetBank("tuber_crop")
    inst.AnimState:SetBuild("tuber_crop")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("poisonous")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("stackable")
    inst.components.stackable.maxsize = TUNING.STACK_SIZE_LARGEITEM



    inst:AddComponent("edible")
    inst.components.edible.foodtype = "VEGGIE"
    inst.components.edible:SetOnEatenFn(oneaten)
    inst.components.edible.hungervalue = TUNING.CALORIES_SMALL

    inst:AddComponent("perishable")
    inst.components.perishable:SetPerishTime(TUNING.PERISH_PRESERVED)
    inst.components.perishable:StartPerishing()
    inst.components.perishable.onperishreplacement = "spoiled_food"

    inst:AddComponent("cookable")
    inst.components.cookable.product = "tuber_crop_cooked"

    inst:AddComponent("inspectable")

    inst:AddComponent("fuel")
    inst.components.fuel.fuelvalue = TUNING.SMALL_FUEL

    MakeSmallBurnable(inst, TUNING.SMALL_BURNTIME)
    MakeSmallPropagator(inst)

    inst:AddComponent("inventoryitem")

    return inst
end

local function cookedfn(Sim)
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()
    MakeInventoryPhysics(inst)

    MakeInventoryFloatable(inst, "cooked_water", "cooked")

    inst.AnimState:SetBank("tuber_crop")
    inst.AnimState:SetBuild("tuber_crop")
    inst.AnimState:PlayAnimation("cooked")

    inst:AddTag("poisonous")

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("stackable")
    inst.components.stackable.maxsize = TUNING.STACK_SIZE_LARGEITEM

    inst:AddComponent("edible")
    inst.components.edible.foodtype = "VEGGIE"
    inst.components.edible:SetOnEatenFn(oneaten)
    inst.components.edible.healthvalue = TUNING.HEALING_SMALL
    inst.components.edible.hungervalue = TUNING.CALORIES_MEDSMALL

    inst.components.edible.foodstate = "COOKED"

    inst:AddComponent("perishable")
    inst.components.perishable:SetPerishTime(TUNING.PERISH_FAST)
    inst.components.perishable:StartPerishing()
    inst.components.perishable.onperishreplacement = "spoiled_food"

    inst:AddComponent("inspectable")

    inst:AddComponent("fuel")
    inst.components.fuel.fuelvalue = TUNING.SMALL_FUEL

    MakeSmallBurnable(inst, TUNING.SMALL_BURNTIME)
    MakeSmallPropagator(inst)

    inst:AddComponent("inventoryitem")

    return inst
end

local function bloomfn(Sim)
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()
    MakeInventoryPhysics(inst)

    MakeInventoryFloatable(inst, "idle_water", "idle")

    inst.AnimState:SetBank("tuber_bloom_crop")
    inst.AnimState:SetBuild("tuber_bloom_crop")
    inst.AnimState:PlayAnimation("idle")

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("stackable")
    inst.components.stackable.maxsize = TUNING.STACK_SIZE_LARGEITEM

    inst:AddComponent("edible")
    inst.components.edible.foodtype = "VEGGIE"
    inst.components.edible.hungervalue = TUNING.CALORIES_SMALL

    inst:AddComponent("perishable")
    inst.components.perishable:SetPerishTime(TUNING.PERISH_PRESERVED)
    inst.components.perishable:StartPerishing()
    inst.components.perishable.onperishreplacement = "spoiled_food"

    inst:AddComponent("cookable")
    inst.components.cookable.product = "tuber_bloom_crop_cooked"

    inst:AddComponent("inspectable")

    inst:AddComponent("fuel")
    inst.components.fuel.fuelvalue = TUNING.SMALL_FUEL

    MakeSmallBurnable(inst, TUNING.SMALL_BURNTIME)
    MakeSmallPropagator(inst)

    inst:AddComponent("inventoryitem")

    return inst
end


local function cookedbloomfn(Sim)
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()
    MakeInventoryPhysics(inst)

    MakeInventoryFloatable(inst, "cooked_water", "cooked")

    inst.AnimState:SetBank("tuber_bloom_crop")
    inst.AnimState:SetBuild("tuber_bloom_crop")
    inst.AnimState:PlayAnimation("cooked")

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("stackable")
    inst.components.stackable.maxsize = TUNING.STACK_SIZE_LARGEITEM

    inst:AddComponent("edible")
    inst.components.edible.foodtype = "VEGGIE"
    inst.components.edible.healthvalue = TUNING.HEALING_SMALL
    inst.components.edible.hungervalue = TUNING.CALORIES_MEDSMALL
    inst.components.edible.sanityvalue = TUNING.SANITY_TINY

    inst.components.edible.foodstate = "COOKED"

    inst:AddComponent("perishable")

    inst.components.perishable:SetPerishTime(TUNING.PERISH_FAST)
    inst.components.perishable:StartPerishing()
    inst.components.perishable.onperishreplacement = "spoiled_food"

    inst:AddComponent("inspectable")

    inst:AddComponent("fuel")
    inst.components.fuel.fuelvalue = TUNING.SMALL_FUEL

    MakeSmallBurnable(inst, TUNING.SMALL_BURNTIME)
    MakeSmallPropagator(inst)

    inst:AddComponent("inventoryitem")

    return inst
end

return Prefab( "common/inventory/tuber_crop", fn, assets),
    Prefab( "common/inventory/tuber_crop_cooked", cookedfn, assets),
    Prefab( "common/inventory/tuber_bloom_crop", bloomfn, assets),
    Prefab( "common/inventory/tuber_bloom_crop_cooked", cookedbloomfn, assets)

