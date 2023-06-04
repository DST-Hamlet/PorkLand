local assets=
{
	Asset("ANIM", "anim/cork.zip"), 
    Asset("INV_IMAGE", "cork"),
    Asset("ATLAS", "images/inventoryimages/inventoryimages_hamlet.xml"),
}

local function fn(Sim)
	local inst = CreateEntity()
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
    inst.entity:AddNetwork()
    
    MakeInventoryPhysics(inst)
    -- MakeInventoryFloatable(inst, "idle_water", "idle")
    -- MakeBlowInHurricane(inst, TUNING.WINDBLOWN_SCALE_MIN.HEAVY, TUNING.WINDBLOWN_SCALE_MAX.HEAVY)
    
    inst.AnimState:SetBuild("cork")
    inst.AnimState:SetBank("cork")
    inst.AnimState:PlayAnimation("idle")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.atlasname = "images/inventoryimages/inventoryimages_hamlet.xml"

    inst:AddComponent("tradable")
    
    inst:AddComponent("stackable")
    
    inst:AddComponent("edible")
    inst.components.edible.foodtype = "WOOD"
    inst.components.edible.woodiness = 5

    
    inst:AddComponent("fuel")
    inst.components.fuel.fuelvalue = TUNING.MED_FUEL
    inst.components.fuel.fueltype = "CORK"

    -- inst:AddComponent("appeasement")
    -- inst.components.appeasement.appeasementvalue = TUNING.WRATH_SMALL
    
    
	MakeSmallBurnable(inst, TUNING.LARGE_BURNTIME)
    MakeSmallPropagator(inst)
    -- inst.components.burnable:MakeDragonflyBait(3)

    ---------------------       
    
    inst:AddComponent("inspectable")
    
  
    
	-- inst:AddComponent("repairer")
	-- inst.components.repairer.repairmaterial = "wood"
	-- inst.components.repairer.healthrepairvalue = TUNING.REPAIR_LOGS_HEALTH

	--inst:ListenForEvent("burnt", function(inst) inst.entity:Retire() end)
    
    return inst
end

return Prefab( "cork", fn, assets) 

