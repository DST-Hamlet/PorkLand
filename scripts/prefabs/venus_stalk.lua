local assets=
{
	Asset("ANIM", "anim/venus_stalk.zip"),
	Asset("ANIM", "anim/meat_rack_food_pl.zip"),
}
local prefabs=
{
	"plantmeat_cooked",
    "spoiled_food",
}

local function fn()
	local inst = CreateEntity()
	
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
    inst.entity:AddNetwork()
    
    MakeInventoryPhysics(inst)
    MakeInventoryFloatable(inst, "med", nil, 0.8)
    --MakeBlowInHurricane(inst, TUNING.WINDBLOWN_SCALE_MIN.HEAVY, TUNING.WINDBLOWN_SCALE_MAX.HEAVY)

    inst.AnimState:SetBank("stalk")
    inst.AnimState:SetBuild("venus_stalk")
    inst.AnimState:PlayAnimation("idle")

	inst:AddTag("meat")

	inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("stackable")
    inst:AddComponent("bait")
    
    inst:AddComponent("inspectable")
    
    inst:AddComponent("inventoryitem")
    
    inst:AddComponent("edible")
    inst.components.edible.ismeat = true    
    inst.components.edible.foodtype = "MEAT"
    inst.components.edible.healthvalue = 0
    inst.components.edible.hungervalue = TUNING.CALORIES_SMALL
    inst.components.edible.sanityvalue = -TUNING.SANITY_SMALL
	
	inst:AddComponent("tradable")
    inst.components.tradable.goldvalue = TUNING.GOLD_VALUES.MEAT
	
	inst:AddComponent("perishable")
	inst.components.perishable:SetPerishTime(TUNING.PERISH_FAST)
	inst.components.perishable:StartPerishing()
	inst.components.perishable.onperishreplacement = "spoiled_food"

    inst:AddComponent("dryable")
    inst.components.dryable:SetProduct("walkingstick")
    inst.components.dryable:SetDryTime(TUNING.DRY_FAST)

	MakeSmallBurnable(inst, TUNING.LARGE_BURNTIME)
    MakeSmallPropagator(inst)
	MakeHauntableLaunch(inst)
    
    return inst
end

return Prefab("venus_stalk", fn, assets, prefabs)

