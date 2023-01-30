-- This file is copy form Island Adventures

local machete_assets = {
    Asset("ANIM", "anim/machete.zip"),
    Asset("ANIM", "anim/swap_machete.zip"),
}

local machete_golden_assets = {
    Asset("ANIM", "anim/goldenmachete.zip"),
    Asset("ANIM", "anim/swap_goldenmachete.zip"),
}

local function onequip(inst, owner)
    inst.hack_overridesymbols[3] = inst:GetSkinBuild()

    if inst.hack_overridesymbols[3] ~= nil then
        owner.AnimState:OverrideItemSkinSymbol("swap_object", inst.hack_overridesymbols[3], inst.hack_overridesymbols[1], inst.GUID, inst.hack_overridesymbols[2])
    else
        owner.AnimState:OverrideSymbol("swap_object", inst.hack_overridesymbols[1], inst.hack_overridesymbols[2])
    end
    owner.AnimState:Show("ARM_carry")
    owner.AnimState:Hide("ARM_normal")
end

local function onunequip(inst, owner)
    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")
end

local function pristinefn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("machete")
    inst.AnimState:SetBuild("machete")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("sharp")
    inst:AddTag("machete")
    -- weapon (from weapon component) added to pristine state for optimization
    inst:AddTag("weapon")

    MakeInventoryFloatable(inst)
    -- inst.components.floater:UpdateAnimations("idle_water", "idle")

    return inst
end

local function masterfn(inst)
    inst:AddComponent("inspectable")
    inst:AddComponent("inventoryitem")

    inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(TUNING.MACHETE_DAMAGE)

    inst:AddComponent("tool")
    inst.components.tool:SetAction(ACTIONS.HACK)

    inst:AddComponent("finiteuses")
    inst.components.finiteuses:SetMaxUses(TUNING.MACHETE_USES)
    inst.components.finiteuses:SetUses(TUNING.MACHETE_USES)
    inst.components.finiteuses:SetOnFinished(inst.Remove)
    inst.components.finiteuses:SetConsumption(ACTIONS.HACK, 1)

    inst:AddComponent("equippable")

    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)

    MakeHauntableLaunch(inst)

    return inst
end

local function normal()
    local inst = pristinefn()

    inst.hack_overridesymbols = {"swap_machete", "swap_machete"}

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    masterfn(inst)

    return inst
end

local function onequipgold(inst, owner)
    onequip(inst, owner)
    owner.SoundEmitter:PlaySound("dontstarve/wilson/equip_item_gold")
end

local function golden()
    local inst = pristinefn()

    inst.AnimState:SetBuild("goldenmachete")

    inst.hack_overridesymbols = {"swap_goldenmachete", "swap_goldenmachete"}

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    masterfn(inst)

    inst.components.finiteuses:SetConsumption(ACTIONS.HACK, 1 / TUNING.GOLDENTOOLFACTOR)
    inst.components.weapon.attackwear = 1 / TUNING.GOLDENTOOLFACTOR
    inst.components.equippable:SetOnEquip(onequipgold)

    return inst
end

return Prefab("machete", normal, machete_assets),
    Prefab("goldenmachete", golden, machete_golden_assets)
