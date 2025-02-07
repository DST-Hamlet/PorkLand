local assets =
{
    Asset("ANIM", "anim/city_hammer.zip"),
    Asset("ANIM", "anim/swap_city_hammer.zip"),
}

local prefabs =
{
    "collapse_small",
    "collapse_big",
}

local function onequip(inst, owner)
    owner.AnimState:OverrideSymbol("swap_object", "swap_city_hammer", "swap_city_hammer")
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
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)
    PorkLandMakeInventoryFloatable(inst)

    inst.AnimState:SetBank("city_hammer")
    inst.AnimState:SetBuild("city_hammer")
    inst.AnimState:PlayAnimation("idle")

    inst.MiniMapEntity:SetPriority(15)
    inst.MiniMapEntity:SetIcon("city_hammer.tex")

    inst:AddTag("irreplaceable")
    inst:AddTag("hammer")
    inst:AddTag("fixable_crusher")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(TUNING.HAMMER_DAMAGE)

    -----
    inst:AddComponent("tool")
    inst.components.tool:SetAction(ACTIONS.HAMMER)
    -------

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")

    inst:AddComponent("equippable")

    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)

    MakeHauntableLaunch(inst)

    return inst
end

return Prefab("city_hammer", fn, assets, prefabs)
