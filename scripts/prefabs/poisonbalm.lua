local assets =
{
	Asset("ANIM", "anim/poison_salve.zip"),
}

local function fn()
	local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)
    MakeInventoryFloatable(inst)
    inst.components.floater:UpdateAnimations("idle_water", "idle")

	inst.AnimState:SetBank("poison_salve")
	inst.AnimState:SetBuild("poison_salve")
	inst.AnimState:PlayAnimation("idle")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

	inst:AddComponent("stackable")
	inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM

	inst:AddComponent("inspectable")

	inst:AddComponent("inventoryitem")

	inst:AddComponent("poisonhealer")

	MakeHauntableLaunch(inst)

	return inst
end

return Prefab("poisonbalm", fn, assets)

