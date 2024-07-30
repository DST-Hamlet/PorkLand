local assets =
{
    Asset("ANIM", "anim/bugrepellent.zip"),
    Asset("ANIM", "anim/swap_bugrepellent.zip"),
}

local prefabs =
{
    "impact",
    "gascloud",
}

local function OnEquip(inst, owner)
    owner.AnimState:OverrideSymbol("swap_object", "swap_bugrepellent", "swap_bugrepellent")
    owner.AnimState:Show("ARM_carry")
    owner.AnimState:Hide("ARM_normal")
end

local function OnUnequip(inst, owner)
    owner.AnimState:ClearOverrideSymbol("swap_object")
    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)
    MakeInventoryFloatable(inst)
    inst.components.floater:UpdateAnimations("idle_water", "idle")

    inst.AnimState:SetBank("bugrepellent")
    inst.AnimState:SetBuild("bugrepellent")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("bugrepellent")
    inst:AddTag("nopunch")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("gasser")

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")

    inst:AddComponent("equippable")
    inst.components.equippable:SetOnEquip(OnEquip)
    inst.components.equippable:SetOnUnequip(OnUnequip)
    inst.components.equippable.equipstack = true

    inst:AddComponent("finiteuses")
    inst.components.finiteuses:SetMaxUses(TUNING.BUGREPELLENT_USES)
    inst.components.finiteuses:SetUses(TUNING.BUGREPELLENT_USES)
    inst.components.finiteuses:SetOnFinished(inst.Remove)

    inst:AddComponent("tool")
    inst.components.tool:SetAction(ACTIONS.GAS, 1)

    MakeHauntableLaunch(inst)

    return inst
end

return Prefab("bugrepellent", fn, assets, prefabs)
