local assets=
{
	Asset("ANIM", "anim/pan.zip"),
	Asset("ANIM", "anim/swap_pan.zip"),
}

local function onfinished(inst)
	inst:Remove()
end

local function onequip(inst, owner)
	owner.AnimState:OverrideSymbol("swap_object", "swap_pan", "swap_pan")
	owner.AnimState:Show("ARM_carry")
	owner.AnimState:Hide("ARM_normal")
end

local function onunequip(inst, owner)
	owner.AnimState:Hide("ARM_carry")
	owner.AnimState:Show("ARM_normal")
end

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()

	MakeInventoryPhysics(inst)

	inst.AnimState:SetBank("pan")
	inst.AnimState:SetBuild("pan")
	inst.AnimState:PlayAnimation("idle")

	inst:AddTag("worksOnFloor")
	inst:AddTag("smeltable") -- Smelter

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inventoryitem")

	inst:AddComponent("weapon")
	inst.components.weapon:SetDamage(TUNING.AXE_DAMAGE)

	inst:AddComponent("tool")
	inst.components.tool:SetAction(ACTIONS.PAN)

	inst:AddComponent("finiteuses")
	inst.components.finiteuses:SetMaxUses(TUNING.PAN_USES)
	inst.components.finiteuses:SetUses(TUNING.PAN_USES)
	inst.components.finiteuses:SetOnFinished(onfinished)
	inst.components.finiteuses:SetConsumption(ACTIONS.PAN, 1)

	inst:AddComponent("inspectable")

	inst:AddComponent("equippable")
	inst.components.equippable:SetOnEquip( onequip )
	inst.components.equippable:SetOnUnequip( onunequip)

	MakeInventoryFloatable(inst)
    inst.components.floater:UpdateAnimations("idle_water", "idle")

	return inst
end

return Prefab("goldpan", fn, assets)
