local assets=
{
	Asset("ANIM", "anim/permit_demolition.zip"),
}

local function makefn(inst)
    local inst = CreateEntity()
    
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    MakeInventoryPhysics(inst)   
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("permit_demolition")
    inst.AnimState:SetBuild("permit_demolition")
    inst.AnimState:PlayAnimation("idle")

    inst:AddComponent("inspectable")
    
    inst:AddComponent("roomdemolisher")

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end
    
    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.foleysound = "dontstarve/movement/foley/jewlery"

    MakeInventoryFloatable(inst, "idle_water", "idle")

    return inst
end

return Prefab( "demolition_permit", makefn, assets)