require "prefabs/pl_veggies"
local assets =
{
    jellybug = { Asset("ANIM", "anim/jellybug.zip"), },
    slugbug = { Asset("ANIM", "anim/slugbug.zip"), },

    jellybug_cooked = { Asset("ANIM", "anim/jellybug_cooked.zip"), },
    slugbug_cooked = { Asset("ANIM", "anim/slugbug_cooked.zip"), },
}

local prefabs =
{
    jellybug =
    {
        "jellybug_cooked",
        "spoiled_food",
    },

    slugbug =
    {
        "slugbug_cooked",
        "spoiled_food",
    }
}

local function pristinefn(bank, build, foodtype)
	local inst = CreateEntity()
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddNetwork()
    
    MakeInventoryPhysics(inst)
    
	inst:AddTag("monstermeat")
	if bank == "jellybug" then
		inst:AddTag("frogbait")
	end
    inst.AnimState:SetBank(bank)
    inst.AnimState:SetBuild(build)
    --inst.AnimState:SetRayTestOnBB(true)
    
    inst:AddComponent("edible")
    inst.components.edible.foodtype = foodtype

    return inst
end

local function masterfn(inst)
	--MakeBlowInHurricane(inst, TUNING.WINDBLOWN_SCALE_MIN.LIGHT, TUNING.WINDBLOWN_SCALE_MAX.LIGHT)
 
	inst:AddComponent("stackable")
	inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM

    inst:AddComponent("tradable")
    inst:AddComponent("inspectable")

    MakeSmallBurnable(inst, TUNING.SMALL_BURNTIME)
    MakeSmallPropagator(inst)
    
    inst:AddComponent("inventoryitem")
	
    inst:AddComponent("perishable")
	inst.components.perishable:SetPerishTime(TUNING.PERISH_SUPERSLOW)
	inst.components.perishable:StartPerishing()
	inst.components.perishable.onperishreplacement = "spoiled_food"

	MakeHauntableLaunchAndPerish(inst)
end

local function jellybug_raw()
    local inst = pristinefn("jellybug", "jellybug", "VEGGIE")
    inst.AnimState:PlayAnimation("idle", true)

    MakeInventoryFloatable(inst)
	--inst.components.floater:UpdateAnimations("idle_water", "idle")
	
	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	masterfn(inst)
	
    inst.components.edible.healthvalue = 0
    inst.components.edible.hungervalue = TUNING.CALORIES_TINY
    inst.components.edible.sanityvalue = -TUNING.SANITY_SMALL

    inst:AddComponent("bait")        
    
    inst:AddComponent("cookable")
    inst.components.cookable.product = "jellybug_cooked"

    return inst
end

local function jellybug_cooked()
    local inst = pristinefn("jellybug_cooked", "jellybug_cooked", "VEGGIE")
    inst.AnimState:PlayAnimation("cooked")

	MakeInventoryFloatable(inst)
	--inst.components.floater:UpdateAnimations("idle_cooked_water", "cooked")
	
	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	masterfn(inst)

    inst.components.edible.foodstate = "COOKED"
	inst.components.edible.healthvalue = TUNING.HEALING_TINY
    inst.components.edible.hungervalue = TUNING.CALORIES_SMALL
    inst.components.edible.sanityvalue = -TUNING.SANITY_TINY
    inst.components.perishable:SetPerishTime(TUNING.PERISH_MED)

    return inst
end

local function slugbug_raw()
    local inst = pristinefn("slugbug", "slugbug", "MEAT")
    inst.AnimState:PlayAnimation("idle", true)

    MakeInventoryFloatable(inst)
	--inst.components.floater:UpdateAnimations("idle_water", "idle")
	
	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	masterfn(inst)
	
    inst.components.edible.healthvalue = 0
    inst.components.edible.hungervalue = TUNING.CALORIES_TINY
    inst.components.edible.sanityvalue = -TUNING.SANITY_SMALL

    inst:AddComponent("bait")
	
    inst:AddComponent("cookable")
    inst.components.cookable.product = "slugbug_cooked"

    return inst
end

local function slugbug_cooked()
    local inst = pristinefn("slugbug_cooked", "slugbug_cooked", "MEAT")
    inst.AnimState:PlayAnimation("cooked")

    MakeInventoryFloatable(inst)
	--inst.components.floater:UpdateAnimations("idle_cooked_water", "cooked")

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	masterfn(inst)
	
    inst.components.edible.foodstate = "COOKED"
    inst.components.edible.healthvalue = TUNING.HEALING_TINY
    inst.components.edible.hungervalue = TUNING.CALORIES_SMALL
    inst.components.edible.sanityvalue = -TUNING.SANITY_TINY
    inst.components.perishable:SetPerishTime(TUNING.PERISH_MED)

    return inst
end

return Prefab("jellybug", jellybug_raw, assets.jellybug, prefabs.jellybug),
       Prefab("jellybug_cooked", jellybug_cooked, assets.jellybug_cooked),
       Prefab("slugbug", slugbug_raw, assets.slugbug, prefabs.slugbug),
       Prefab("slugbug_cooked", slugbug_cooked, assets.slugbug_cooked)