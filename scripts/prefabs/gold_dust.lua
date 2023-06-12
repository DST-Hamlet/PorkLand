local assets=
{
	Asset("ANIM", "anim/gold_dust.zip"),
}

local function shine(inst)
	inst.AnimState:PlayAnimation("sparkle")
	inst.AnimState:PushAnimation("idle", false)
 inst:DoTaskInTime(4 + math.random() * 5, shine)
end


local function fn(Sim)
	local inst = CreateEntity()
	
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()
	
    MakeInventoryPhysics(inst)
	MakeInventoryFloatable(inst)
    --MakeInventoryFloatable(inst, "idle_water", "idle")
    --MakeBlowInHurricane(inst, TUNING.WINDBLOWN_SCALE_MIN.MEDIUM, TUNING.WINDBLOWN_SCALE_MAX.MEDIUM)

	inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
	
    inst.AnimState:SetBank("gold_dust")
    inst.AnimState:SetBuild("gold_dust")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("molebait")
    inst:AddTag("scarerbait")
	
	inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("edible")
    inst.components.edible.foodtype = FOODTYPE.GOLDDUST
    inst.components.edible.hungervalue = 1
    inst:AddComponent("tradable")
    
    inst:AddComponent("inspectable")
    
    inst:AddComponent("inventoryitem")

    inst:AddComponent("stackable")
    inst:AddComponent("bait")

	MakeHauntableLaunch(inst)
	
    shine(inst)
	return inst
end

return Prefab( "gold_dust", fn, assets) 
