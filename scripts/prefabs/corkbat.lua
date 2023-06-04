local basic_assets =
{
	Asset("ANIM", "anim/cork_bat.zip"),
	Asset("ANIM", "anim/swap_cork_bat.zip"),
}


local function onfinished(inst)
	inst:Remove()
end

local function onequip(inst, owner)
	owner.AnimState:OverrideSymbol("swap_object", "swap_cork_bat", "swap_cork_bat")
	owner.AnimState:Show("ARM_carry")
	owner.AnimState:Hide("ARM_normal")
end

local function onunequip(inst, owner)
	owner.AnimState:Hide("ARM_carry")
	owner.AnimState:Show("ARM_normal")
end


local function fn(Sim)
	local inst = CreateEntity()
	inst.entity:AddTransform()
	inst.entity:AddAnimState()

	MakeInventoryPhysics(inst)
	MakeInventoryFloatable(inst, "idle_water", "idle")

	inst.AnimState:SetBuild("cork_bat")
	inst.AnimState:SetBank("cork_bat")
	inst.AnimState:PlayAnimation("idle")
	inst:AddTag("bat")
	inst:AddTag("corkbat")
	inst:AddTag("slowattack")

	inst:AddComponent("weapon")
	inst.components.weapon:SetDamage(TUNING.CORK_BAT_DAMAGE)

	inst:AddComponent("tradable")

	-------

	inst:AddComponent("finiteuses")
	inst.components.finiteuses:SetMaxUses(TUNING.CORK_BAT_USES)
	inst.components.finiteuses:SetUses(TUNING.CORK_BAT_USES)

	inst.components.finiteuses:SetOnFinished( onfinished )

	inst:AddComponent("inspectable")

	inst:AddComponent("equippable")
	inst.components.equippable:SetOnEquip( onequip )
	inst.components.equippable:SetOnUnequip( onunequip )
	
	inst:AddComponent("inventoryitem")

	return inst
end


return Prefab( "common/inventory/cork_bat", fn, basic_assets)