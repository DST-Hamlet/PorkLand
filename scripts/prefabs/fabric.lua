local assets=
{
	Asset("ANIM", "anim/fabric.zip"),
}

local function fn(Sim)
	local inst = CreateEntity()
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddNetwork()

	inst.AnimState:SetBank("fabric")
	inst.AnimState:SetBuild("fabric")
	inst.AnimState:PlayAnimation("idle")

	MakeInventoryPhysics(inst)

	MakeInventoryFloatable(inst)
	--inst.components.floater:UpdateAnimations("idle_water", "idle")

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	--MakeBlowInHurricane(inst, TUNING.WINDBLOWN_SCALE_MIN.LIGHT, TUNING.WINDBLOWN_SCALE_MAX.LIGHT)

	inst:AddComponent("stackable")

	inst:AddComponent("inspectable")
	
	inst:AddComponent("inventoryitem")

	MakeHauntableLaunch(inst)

	MakeSmallBurnable(inst, TUNING.LARGE_BURNTIME)
	MakeSmallPropagator(inst)

	inst:AddComponent("fuel")
	inst.components.fuel.fuelvalue = TUNING.MED_FUEL

	--inst:AddComponent("appeasement")
	--inst.components.appeasement.appeasementvalue = TUNING.WRATH_SMALL

	inst:AddTag("cattoy")
	inst:AddComponent("tradable")

	--MakeInvItemIA(inst)

	return inst
end

return Prefab("fabric", fn, assets) 
