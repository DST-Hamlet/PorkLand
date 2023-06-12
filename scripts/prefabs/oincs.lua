local assets=
{
	Asset("ANIM", "anim/pig_coin.zip"),
	Asset("ANIM", "anim/pig_coin_silver.zip"),
	Asset("ANIM", "anim/pig_coin_jade.zip"),
}

local prefabs =
{

}

local function shine(inst)
    inst.task = nil
    -- hacky, need to force a floatable anim change
	-- DS - I think the DST version of the component is better
    -- inst.components.floatable:UpdateAnimations("idle_water", "idle")
    -- inst.components.floatable:UpdateAnimations("sparkle_water", "sparkle")

    -- if inst.components.floatable.onwater then
        -- inst.AnimState:PushAnimation("idle_water")
    -- else
        -- inst.AnimState:PushAnimation("idle")
    -- end
    
    if inst.entity:IsAwake() then
        inst:DoTaskInTime(4+math.random()*5, function() shine(inst) end)
    end
end

local function onpickup(inst, pickupguy)
	
    local num = 1
	if inst.components.stackable then
		num = inst.components.stackable.stacksize
	end
	
	if num == 1 then
	  inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/objects/coins/1")
	elseif num == 2 then
	  inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/objects/coins/2")
	else
	  inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/objects/coins/3_plus")
	end 
	-- Highly simplified version of what's in Hamlet's 'inventory.lua' 'TestForOincSound' function
	-- Probably still needs some stuff to account for transactions, but perhaps that can be a global-ish function?
	-- inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/objects/coins/1") 
end

local function onwake(inst)
    inst.task = inst:DoTaskInTime(4+math.random()*5, function() shine(inst) end)
end

local function commoncoin_fn(Sim)
    
	local inst = CreateEntity()
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddPhysics()
    inst.entity:AddNetwork()

    inst.OnEntityWake = onwake

    MakeInventoryPhysics(inst)
    MakeInventoryFloatable(inst, "idle_water", "idle")
    --MakeBlowInHurricane(inst, TUNING.WINDBLOWN_SCALE_MIN.MEDIUM, TUNING.WINDBLOWN_SCALE_MAX.MEDIUM)

	inst.AnimState:SetBloomEffectHandle( "shaders/anim.ksh" )    
	
    inst.AnimState:SetBank("coin")
    -- inst.AnimState:SetBuild("pig_coin")
    -- inst.AnimState:PlayAnimation("idle")

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

    inst:AddComponent("edible")
    inst.components.edible.foodtype = "ELEMENTAL"
    inst.components.edible.hungervalue = 1
    
    inst:AddComponent("currency")
    
    inst:AddComponent("inspectable")
    
    inst:AddComponent("stackable")
    inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM

    --inst:AddComponent("appeasement")
    --inst.components.appeasement.appeasementvalue = TUNING.APPEASEMENT_TINY

	inst:AddComponent("waterproofer")
	inst.components.waterproofer.effectiveness = 0
	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem:SetOnPickupFn(onpickup)

    inst:AddComponent("bait")
    inst:AddTag("molebait")
    inst:AddTag("oinc")
    inst.oincvalue = 1 -- Default? This should get overridden by the other funcs, right?

    inst:AddComponent("tradable")
    
    return inst
end

local function oinc_fn()
	local inst = commoncoin_fn(Sim)
	
    inst.AnimState:SetBuild("pig_coin")
    inst.AnimState:PlayAnimation("idle")
	
    inst.oincvalue = 1
	return inst
end

local function oinc10_fn()
	local inst = commoncoin_fn(Sim)
	
    inst.AnimState:SetBuild("pig_coin_silver")
    inst.AnimState:PlayAnimation("idle")
	
    inst.oincvalue = 10
	return inst
end

local function oinc100_fn()
	local inst = commoncoin_fn(Sim)
	
    inst.AnimState:SetBuild("pig_coin_jade")
    inst.AnimState:PlayAnimation("idle")
	
    inst.oincvalue = 100
	return inst
end

return Prefab( "oinc", oinc_fn, assets, prefabs),
		Prefab( "oinc10", oinc10_fn, assets, prefabs),
		Prefab( "oinc100", oinc100_fn, assets, prefabs)