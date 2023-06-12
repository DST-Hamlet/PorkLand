local assets=
{
	Asset("ANIM", "anim/cork.zip"),
}

local function fn()
	local inst = CreateEntity()
	
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
    inst.entity:AddNetwork()
    
    MakeInventoryPhysics(inst)
    MakeInventoryFloatable(inst, "med", nil, 0.8)
    --MakeBlowInHurricane(inst, TUNING.WINDBLOWN_SCALE_MIN.HEAVY, TUNING.WINDBLOWN_SCALE_MAX.HEAVY)

    inst.AnimState:SetBuild("cork")
    inst.AnimState:SetBank("cork")
    inst.AnimState:PlayAnimation("idle")

	inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("tradable")
    inst:AddComponent("inventoryitem")
	inst:AddComponent("inspectable")
    inst:AddComponent("stackable")
    
    inst:AddComponent("edible")
    inst.components.edible.foodtype = FOODTYPE.WOOD
    inst.components.edible.woodiness = 5

    inst:AddComponent("fuel")
    inst.components.fuel.fueltype = FUELTYPE.CORK
    inst.components.fuel.fuelvalue = TUNING.MED_FUEL
    
	inst:AddComponent("repairer")
	inst.components.repairer.repairmaterial = MATERIALS.WOOD
	inst.components.repairer.workrepairvalue = TUNING.REPAIR_LOGS_HEALTH

	MakeSmallBurnable(inst, TUNING.LARGE_BURNTIME)
    MakeSmallPropagator(inst)
	MakeHauntableLaunch(inst)
    
    return inst
end

return Prefab( "cork", fn, assets) 

