local assets = {
    Asset("ANIM", "anim/ballpein_hammer.zip"),
    Asset("ANIM", "anim/swap_ballpein_hammer.zip"),
}

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

    inst:AddTag("smeltable") -- Smelter

    -- weapon (from weapon component) added to pristine state for optimization
    inst:AddTag("weapon")

    --tool (from tool component) added to pristine state for optimization
    inst:AddTag("tool")

    inst.AnimState:SetBank("ballpein_hammer")
    inst.AnimState:SetBuild("ballpein_hammer")
    inst.AnimState:PlayAnimation("idle")

    MakeInventoryFloatable(inst)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")
    inst:AddComponent("inventoryitem")

    inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(TUNING.BALLPEIN_HAMMER_DAMAGE)

    inst:AddComponent("tool")
    inst.components.tool:SetAction(ACTIONS.DISLODGE)

    inst:AddComponent("equippable")
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)

    inst:AddComponent("finiteuses")
    inst.components.finiteuses:SetMaxUses(TUNING.BALLPEIN_HAMMER_USES)
    inst.components.finiteuses:SetUses(TUNING.BALLPEIN_HAMMER_USES)
    inst.components.finiteuses:SetOnFinished(inst.Remove)
    inst.components.finiteuses:SetConsumption(ACTIONS.DISLODGE, 1)

    MakeHauntableLaunch(inst)

    return inst
end

return Prefab("ballpein_hammer", fn, assets)
