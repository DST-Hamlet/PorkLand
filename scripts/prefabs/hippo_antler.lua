local assets=
{
	Asset("ANIM", "anim/hippo_antler.zip"),
}

local function fn(Sim)
	local inst = CreateEntity()
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	
	inst:AddTag("antler")
    
    inst.AnimState:SetBank("hippo_antler")
    inst.AnimState:SetBuild("hippo_antler")
    inst.AnimState:PlayAnimation("idle")
    MakeInventoryPhysics(inst)

    MakeInventoryFloatable(inst, "idle_water", "idle")

    inst:AddComponent("stackable")
    inst.components.stackable.maxsize = TUNING.STACK_SIZE_LARGEITEM

    inst:AddComponent("inspectable")
    inst:AddComponent("tradable")
    
    inst:AddComponent("inventoryitem")
    
    return inst
end

return Prefab( "common/inventory/hippo_antler", fn, assets) 
