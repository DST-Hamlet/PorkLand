local assets =
{
    Asset("ANIM", "anim/cutlass.zip"),
    Asset("ANIM", "anim/swap_cutlass.zip"),
}

local function onequip(inst, owner)
    owner.AnimState:OverrideSymbol("swap_object", "swap_cutlass", "swap_cutlass")
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
    PorkLandMakeInventoryFloatable(inst, "idle_water", "idle")

    inst.AnimState:SetBank("cutlass")
    inst.AnimState:SetBuild("cutlass")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("sharp")
    inst:AddTag("fishmeat")
    inst:AddTag("cutlass")
    -- weapon (from weapon component) added to pristine state for optimization
    inst:AddTag("weapon")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inventoryitem")

    inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(TUNING.CUTLASS_DAMAGE)

    inst:AddComponent("finiteuses")
    inst.components.finiteuses:SetMaxUses(TUNING.CUTLASS_USES)
    inst.components.finiteuses:SetUses(TUNING.CUTLASS_USES)
    inst.components.finiteuses:SetOnFinished(inst.Remove)

    inst:AddComponent("inspectable")

    inst:AddComponent("equippable")
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)

    MakeHauntableLaunch(inst)

    return inst
end

return Prefab("cutlass", fn, assets)
