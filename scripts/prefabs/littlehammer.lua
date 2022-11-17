local assets =
{
	Asset("ANIM", "anim/ballpein_hammer.zip"),
	Asset("ANIM", "anim/swap_ballpein_hammer.zip"),
}

local function onfinished(inst)
    inst:Remove()
end

local function onequip(inst, owner)
    owner.AnimState:OverrideSymbol("swap_object", "swap_ballpein_hammer", "swap_ballpein_hammer")
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

    inst.AnimState:SetBank("ballpein_hammer")
    inst.AnimState:SetBuild("ballpein_hammer")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("ballpein_hammer")
    inst:AddTag("hammer")

    inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

    inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(TUNING.LITTLE_HAMMER_DAMAGE)

    inst:AddComponent("tool")
    inst.components.tool:SetAction(ACTIONS.DISLODGE)

    inst:AddComponent("finiteuses")
    inst.components.finiteuses:SetMaxUses(TUNING.LITTLE_HAMMER_USES)
    inst.components.finiteuses:SetUses(TUNING.LITTLE_HAMMER_USES)
    inst.components.finiteuses:SetOnFinished(onfinished)
    inst.components.finiteuses:SetConsumption(ACTIONS.DISLODGE, 1)

    inst:AddComponent("dislodger")

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")

    inst:AddComponent("equippable")
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)

    MakeHauntableLaunch(inst)

    return inst
end

return Prefab("ballpein_hammer", fn, assets)
