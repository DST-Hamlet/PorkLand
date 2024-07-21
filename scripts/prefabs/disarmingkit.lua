local assets =
{
	Asset("ANIM", "anim/disarm_kit.zip"),
}

local function OnFinished(inst)
	inst:Remove()
end

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
    inst.entity:AddNetwork()

	MakeInventoryPhysics(inst)
	MakeInventoryFloatable(inst)
    inst.components.floater:UpdateAnimations("idle_water", "idle")

	inst.AnimState:SetBank("disarm_kit")
	inst.AnimState:SetBuild("disarm_kit")
	inst.AnimState:PlayAnimation("idle")

	inst:AddTag("smeltable") -- Smelter

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

	inst:AddComponent("finiteuses")
	inst.components.finiteuses:SetMaxUses(TUNING.SEWINGKIT_USES)
	inst.components.finiteuses:SetUses(TUNING.SEWINGKIT_USES)
	inst.components.finiteuses:SetOnFinished(OnFinished)
	inst.components.finiteuses:SetConsumption(ACTIONS.DISARM, 1)

	inst:AddComponent("disarming")

	inst:AddComponent("inspectable")

	inst:AddComponent("inventoryitem")

	MakeHauntableLaunch(inst)

	return inst
end

return Prefab("disarming_kit", fn, assets)
