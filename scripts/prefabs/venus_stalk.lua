local assets =
{
    Asset("ANIM", "anim/venus_stalk.zip"),
}

local prefabs =
{
    "plantmeat_cooked",
    "spoiled_food",
    "walkingstick",
}

local function flytrapstalk(inst)
	local inst = CreateEntity()
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)
    MakeInventoryFloatable(inst)
    -- MakeBlowInHurricane(inst, TUNING.WINDBLOWN_SCALE_MIN.MEDIUM, TUNING.WINDBLOWN_SCALE_MAX.MEDIUM)
    -- MakeInventoryFloatable(inst, "idle_water", "idle")

    inst.AnimState:SetBank("stalk")
    inst.AnimState:SetBuild("venus_stalk")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("meat")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("edible")
    inst.components.edible.ismeat = true
    inst.components.edible.foodtype = "MEAT"
    inst.components.edible.foodstate = "RAW"
    inst.components.edible.healthvalue = 0
    inst.components.edible.hungervalue = TUNING.CALORIES_SMALL
    inst.components.edible.sanityvalue = -TUNING.SANITY_SMALL

    inst:AddComponent("stackable")
    inst:AddComponent("bait")

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")

    inst:AddComponent("tradable")
    inst.components.tradable.goldvalue = TUNING.GOLD_VALUES.MEAT

    inst:AddComponent("dryable")
    inst.components.dryable:SetProduct("walkingstick")
    inst.components.dryable:SetBuildFile("meat_rack_food_sw")
    inst.components.dryable:SetDryTime(TUNING.DRY_FAST)

	inst:AddComponent("perishable")
	inst.components.perishable:SetPerishTime(TUNING.PERISH_FAST)
	inst.components.perishable:StartPerishing()
	inst.components.perishable.onperishreplacement = "spoiled_food"

    inst:AddComponent("appeasement")
    inst.components.appeasement.appeasementvalue = TUNING.APPEASEMENT_TINY

    MakeHauntableLaunch(inst)
    MakeSmallBurnable(inst, TUNING.SMALL_BURNTIME)
    MakeSmallPropagator(inst)

    return inst
end

return Prefab("venus_stalk", flytrapstalk, assets, prefabs)
