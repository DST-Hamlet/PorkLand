local assets =
{
    Asset("ANIM", "anim/cork_bat.zip"),
    Asset("ANIM", "anim/swap_cork_bat.zip"),
}

local function OnEquip(inst, owner)
    owner.AnimState:OverrideSymbol("swap_object", "swap_cork_bat", "swap_cork_bat")
    owner.AnimState:Show("ARM_carry")
    owner.AnimState:Hide("ARM_normal")
end

local function OnUnequip(inst, owner)
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
    inst.components.floater:UpdateAnimations( "idle_water", "idle")

    inst.AnimState:SetBuild("cork_bat")
    inst.AnimState:SetBank("cork_bat")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("bat")
    inst:AddTag("corkbat")
    inst:AddTag("slowattack")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(TUNING.CORK_BAT_DAMAGE)

    inst:AddComponent("tradable")

    inst:AddComponent("finiteuses")
    inst.components.finiteuses:SetMaxUses(TUNING.CORK_BAT_USES)
    inst.components.finiteuses:SetUses(TUNING.CORK_BAT_USES)
    inst.components.finiteuses:SetOnFinished(inst.Remove)

    inst:AddComponent("inspectable")

    inst:AddComponent("equippable")
    inst.components.equippable:SetOnEquip(OnEquip)
    inst.components.equippable:SetOnUnequip(OnUnequip)

    inst:AddComponent("inventoryitem")

    MakeHauntableLaunch(inst)

    return inst
end

return Prefab("cork_bat", fn, assets)
