local assets =
{
    Asset("ANIM", "anim/hand_lens.zip"),
    Asset("ANIM", "anim/swap_hand_lens.zip"),
}

local prefabs =
{
}

local function onequip(inst, owner)
    owner.AnimState:OverrideSymbol("swap_object", "swap_hand_lens", "swap_hand_lens")
    owner.AnimState:Show("ARM_carry")
    owner.AnimState:Hide("ARM_normal")
end

local function onunequip(inst, owner)
    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")
end

local function onfinished(inst)
    inst:Remove()
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("hand_lens")
    inst.AnimState:SetBuild("hand_lens")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("magnifying_glass")
    inst:AddTag("smeltable") -- Smelter

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("finiteuses")
    inst.components.finiteuses:SetMaxUses(TUNING.MAGNIFYING_GLASS_USES)
    inst.components.finiteuses:SetUses(TUNING.MAGNIFYING_GLASS_USES)
    inst.components.finiteuses:SetConsumption(ACTIONS.SPY, 1)
    inst.components.finiteuses:SetOnFinished(onfinished)

    inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(TUNING.MAGNIFYING_GLASS_DAMAGE)

    inst:AddComponent("tool")
    inst.components.tool:SetAction(ACTIONS.SPY)

    inst:AddComponent("inspectable")
    inst:AddComponent("inventoryitem")

    inst:AddComponent("equippable")
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)

    inst:AddComponent("lighter")

    MakeHauntableLaunch(inst)

    return inst
end

return Prefab("magnifying_glass", fn, assets, prefabs)
