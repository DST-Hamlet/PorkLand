local assets =
{
    Asset("ANIM", "anim/hand_lens.zip"),
    Asset("ANIM", "anim/swap_hand_lens.zip"),

    Asset("ANIM", "anim/eye_lens_wilson.zip"),
    Asset("ANIM", "anim/eye_lens_willow.zip"),
    Asset("ANIM", "anim/eye_lens_wolfgang.zip"),
    Asset("ANIM", "anim/eye_lens_wendy.zip"),
    Asset("ANIM", "anim/eye_lens_wx78.zip"),
    Asset("ANIM", "anim/eye_lens_wickerbottom.zip"),
    Asset("ANIM", "anim/eye_lens_woodie.zip"),
    Asset("ANIM", "anim/eye_lens_wes.zip"),
    Asset("ANIM", "anim/eye_lens_waxwell.zip"),
    Asset("ANIM", "anim/eye_lens_wathgrithr.zip"),
    Asset("ANIM", "anim/eye_lens_webber.zip"),
    Asset("ANIM", "anim/eye_lens_winona.zip"),
    Asset("ANIM", "anim/eye_lens_warly.zip"),
    Asset("ANIM", "anim/eye_lens_wortox.zip"),
    Asset("ANIM", "anim/eye_lens_wormwood.zip"),
    Asset("ANIM", "anim/eye_lens_wurt.zip"),
    Asset("ANIM", "anim/eye_lens_walter.zip"),
    Asset("ANIM", "anim/eye_lens_wanda.zip"),
}

local prefabs =
{

}

local LENS_EYES_SYMBOL =
{
    ["wilson"] = "eye_lens_wilson",
    ["willow"] = "eye_lens_willow",
    ["wolfgang"] = "eye_lens_wolfgang",
    ["wendy"] = "eye_lens_wendy",
    ["wx78"] = "eye_lens_wx78",
    ["wickerbottom"] = "eye_lens_wickerbottom",
    ["woodie"] = "eye_lens_woodie",
    ["wes"] = "eye_lens_wes",
    ["waxwell"] = "eye_lens_waxwell",
    ["wathgrithr"] = "eye_lens_wathgrithr",
    ["webber"] = "eye_lens_webber",
    ["winona"] = "eye_lens_winona",
    ["warly"] = "eye_lens_warly",
    ["wortox"] = "eye_lens_wortox",
    ["wormwood"] = "eye_lens_wormwood",
    ["wurt"] = "eye_lens_wurt",
    ["walter"] = "eye_lens_walter",
    ["wanda"] = "eye_lens_wanda",
}

local function onequip(inst, owner)
    owner.AnimState:OverrideSymbol("swap_object", "swap_hand_lens", "swap_hand_lens")
    if LENS_EYES_SYMBOL[owner.prefab] ~= nil then
        owner.AnimState:OverrideSymbol("lens_eye", LENS_EYES_SYMBOL[owner.prefab], "lens_eye")
    end
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
