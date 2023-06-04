local assets=
{
	Asset("ANIM", "anim/frog_legs.zip"),
}


local prefabs =
{
	"froglegs_cooked",
}    

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


local function commonfn()
	local inst = CreateEntity()
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
    inst.AnimState:SetBank("frog_legs")
    inst.AnimState:SetBuild("frog_legs")
    inst.entity:AddNetwork()
    
    MakeInventoryPhysics(inst)
    -- MakeBlowInHurricane(inst, TUNING.WINDBLOWN_SCALE_MIN.MEDIUM, TUNING.WINDBLOWN_SCALE_MAX.MEDIUM) TODO Fix

    inst:AddTag("smallmeat")
	inst:AddTag("fishmeat")
    inst:AddTag("catfood")

    inst:AddComponent("edible")
    inst.components.edible.foodtype = "MEAT"
    
    
	inst:AddComponent("perishable")
	inst.components.perishable:SetPerishTime(TUNING.PERISH_FAST)
	inst.components.perishable:StartPerishing()
	inst.components.perishable.onperishreplacement = "spoiled_food"

    inst.entity:SetPristine()

	if not TheWorld.ismastersim then
        return inst
    end

    
    inst:AddComponent("stackable")
	inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM

    inst:AddComponent("bait")
    
    inst:AddComponent("inspectable")
    
    inst:AddComponent("inventoryitem")
    
    inst:AddComponent("tradable")
	inst.components.tradable.goldvalue = 0

    -- inst:AddComponent("appeasement")
    -- inst.components.appeasement.appeasementvalue = TUNING.APPEASEMENT_SMALL TODO fix


    return inst
end

local function defaultfn()
	local inst = commonfn()
    inst.AnimState:PlayAnimation("idle")

    MakeInventoryFloatable(inst, "idle_water", "idle")
    
    inst.components.edible.healthvalue = 0
    inst.components.edible.hungervalue = TUNING.CALORIES_SMALL
    inst.components.perishable:SetPerishTime(TUNING.PERISH_FAST)
    inst.components.edible.sanityvalue = -TUNING.SANITY_SMALL
    
    
    inst:AddComponent("cookable")
    inst.components.cookable.product = "froglegs_cooked"
    inst:AddComponent("dryable")
    inst.components.dryable:SetProduct("smallmeat_dried")
    inst.components.dryable:SetDryTime(TUNING.DRY_FAST)
	return inst
end

local function cookedfn()
	local inst = commonfn()
    inst.AnimState:PlayAnimation("cooked")

    MakeInventoryFloatable(inst, "idle_cooked_water", "cooked")

    inst.components.edible.foodstate = "COOKED"
    inst.components.edible.healthvalue = TUNING.HEALING_TINY
    inst.components.edible.hungervalue = TUNING.CALORIES_SMALL
    inst.components.perishable:SetPerishTime(TUNING.PERISH_MED)
    
	return inst
end

local function default_poisonfn()
    local inst = defaultfn()
    inst:AddTag("poisonous")
    inst.AnimState:SetBuild("frog_legs_tree")
    inst.components.cookable.product = "froglegs_poison_cooked"
    inst.components.edible:SetOnEatenFn(oneaten)
    return inst
end

local function cooked_poisonfn()    
    local inst = cookedfn()
    inst:AddTag("poisonous")
    inst.AnimState:SetBuild("frog_legs_tree")
    inst.components.edible:SetOnEatenFn(oneaten)
    return inst
end


return Prefab("common/inventory/froglegs_poison", default_poisonfn, assets_poison, prefabs_poison),
          Prefab("common/inventory/froglegs_poison_cooked", cooked_poisonfn, assets_poison) 


 
