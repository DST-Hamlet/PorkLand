local assets =
{
    Asset("ANIM", "anim/armor_snakeskin_scaly.zip"),
}

local function OnEquip(inst, owner)
    owner.AnimState:OverrideSymbol("swap_body", "armor_snakeskin_scaly", "swap_body")
    inst.components.fueled:StartConsuming()
end

local function OnUnequip(inst, owner)
    owner.AnimState:ClearOverrideSymbol("swap_body")
    inst.components.fueled:StopConsuming()
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)
    MakeInventoryFloatable(inst)
    inst.components.floater:UpdateAnimations("idle_water", "anim")

    inst.AnimState:SetBank("armor_snakeskin_scaly")
    inst.AnimState:SetBuild("armor_snakeskin_scaly")
    inst.AnimState:PlayAnimation("anim")

    inst.shelfart = "armor_snakeskin_scaly"
    inst.foleysound = "dontstarve_DLC002/common/foley/snakeskin_jacket"

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem:ChangeImageName("armor_snakeskin_scaly")

    inst:AddComponent("equippable")
    inst.components.equippable.equipslot = EQUIPSLOTS.BODY
    inst.components.equippable:SetOnEquip(OnEquip)
    inst.components.equippable:SetOnUnequip(OnUnequip)
    inst.components.equippable.insulated = true

    inst:AddComponent("waterproofer")
    inst.components.waterproofer.effectiveness = TUNING.WATERPROOFNESS_HUGE

    inst:AddComponent("fueled")
    inst.components.fueled.fueltype = FUELTYPE.USAGE
    inst.components.fueled:InitializeFuelLevel(TUNING.ARMOR_SNAKESKIN_PERISHTIME)
    inst.components.fueled:SetDepletedFn(inst.Remove)

    inst:AddComponent("insulator")
    inst.components.insulator:SetInsulation(TUNING.INSULATION_SMALL)

    MakeHauntableLaunch(inst)

    return inst
end

return Prefab("armor_snakeskin", fn, assets) -- why armor_snakeskin?
