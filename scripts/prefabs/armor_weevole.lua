local assets =
{
    Asset("ANIM", "anim/armor_weevole.zip"),
}

local function OnBlocked(owner)
    owner.SoundEmitter:PlaySound("dontstarve/wilson/hit_armour")
end

local function OnEquip(inst, owner)
    owner.AnimState:OverrideSymbol("swap_body", "armor_weevole", "swap_body")
    inst:ListenForEvent("blocked", OnBlocked, owner)
end

local function OnUnequip(inst, owner)
    owner.AnimState:ClearOverrideSymbol("swap_body")
    inst:RemoveEventCallback("blocked", OnBlocked, owner)
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("armor_weevole")
    inst.AnimState:SetBuild("armor_weevole")
    inst.AnimState:PlayAnimation("anim")

    inst:AddTag("wood")
    inst:AddTag("vented")

    inst.foleysound = "dontstarve/movement/foley/logarmour"

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")

    inst:AddComponent("armor")
    inst.components.armor:InitCondition(TUNING.ARMOR_WEEVOLE_DURABILITY, TUNING.ARMOR_WEEVOLE_ABSORPTION)

    inst:AddComponent("waterproofer")
    inst.components.waterproofer:SetEffectiveness(TUNING.WATERPROOFNESS_MED)

    inst:AddComponent("equippable")
    inst.components.equippable.equipslot = EQUIPSLOTS.BODY
    inst.components.equippable:SetOnEquip(OnEquip)
    inst.components.equippable:SetOnUnequip(OnUnequip)

    return inst
end

return Prefab("armor_weevole", fn, assets)
