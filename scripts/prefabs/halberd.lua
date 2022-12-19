local assets =
{
	Asset("ANIM", "anim/halberd.zip"),
	Asset("ANIM", "anim/swap_halberd.zip"),
}

local function onfinished(inst)
	inst:Remove()
end

local function onequip(inst, owner)
	owner.AnimState:OverrideSymbol("swap_object", "swap_halberd", "swap_halberd")
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
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)
    MakeInventoryFloatable(inst)
	-- MakeInventoryFloatable(inst, "idle_water", "idle")

	inst.AnimState:SetBank("halberd")
	inst.AnimState:SetBuild("halberd")
	inst.AnimState:PlayAnimation("idle")

	inst:AddTag("halberd")
	inst:AddTag("sharp")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

	inst:AddComponent("weapon")
	inst.components.weapon:SetDamage(TUNING.HALBERD_DAMAGE)

	inst:AddComponent("tool")
	inst.components.tool:SetAction(ACTIONS.CHOP)

	inst:AddComponent("finiteuses")
	inst.components.finiteuses:SetMaxUses(TUNING.HALBERD_USES)
	inst.components.finiteuses:SetUses(TUNING.HALBERD_USES)
	inst.components.finiteuses:SetOnFinished(onfinished)
	inst.components.finiteuses:SetConsumption(ACTIONS.CHOP, 1)

	inst:AddComponent("equippable")
	inst.components.equippable:SetOnEquip(onequip)
	inst.components.equippable:SetOnUnequip(onunequip)

	inst:AddComponent("inspectable")
    inst:AddComponent("inventoryitem")

    MakeHauntableLaunch(inst)

	return inst
end

return Prefab( "halberd", fn, assets)
