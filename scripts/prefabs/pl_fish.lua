local assets =
{
    Asset("ANIM", "anim/coi.zip"),
}

local prefabs =
{
    "fish_cooked",
    "spoiled_food",
}

local function stopkicking(inst)
    if inst.floptask then
        inst.floptask:Cancel()
        inst.floptask = nil
    end
    inst.AnimState:PlayAnimation("dead")
end

local function commonfn(bank, build, anim, loop, dryable, cookable)
    local inst = CreateEntity()
    inst.entity:AddSoundEmitter()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank(bank)
    inst.AnimState:SetBuild(build)
    inst.AnimState:PlayAnimation(anim, loop)

    inst:AddTag("meat")
    inst:AddTag("catfood")
	inst:AddTag("pondfish")

    if dryable then
        --dryable (from dryable component) added to pristine state for optimization
        inst:AddTag("dryable")
    end

    if cookable then
        --cookable (from cookable component) added to pristine state for optimization
        inst:AddTag("cookable")
    end

    PorkLandMakeInventoryFloatable(inst)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.build = build --This is used within SGwilson, sent from an event in fishingrod.lua

    inst:AddComponent("edible")
    inst.components.edible.ismeat = true
    inst.components.edible.foodtype = FOODTYPE.MEAT

    inst:AddComponent("stackable")
    inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM

    inst:AddComponent("bait")

    inst:AddComponent("perishable")
    inst.components.perishable:SetPerishTime(TUNING.PERISH_FAST)
    inst.components.perishable:StartPerishing()
    inst.components.perishable.onperishreplacement = "spoiled_food"

    if dryable then
        inst:AddComponent("dryable")
        inst.components.dryable:SetProduct("smallmeat_dried")
        inst.components.dryable:SetDryTime(TUNING.DRY_FAST)
    end

    if cookable then
        inst:AddComponent("cookable")
        inst.components.cookable.product = "fish_cooked"
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")

    MakeHauntableLaunchAndPerish(inst)

    inst:AddComponent("tradable")
    inst.components.tradable.goldvalue = TUNING.GOLD_VALUES.MEAT
    inst.data = {}

    return inst
end

local function flopsound(inst)
    inst.floptask = inst:DoTaskInTime(10/30, function()
        inst.SoundEmitter:PlaySound("dontstarve/common/fishingpole_fishland")
        if inst.floptask then
            inst.floptask:Cancel()
            inst.floptask = nil
        end
        inst.floptask = inst:DoTaskInTime(12/30, function()
            inst.SoundEmitter:PlaySound("dontstarve/common/fishingpole_fishland")
        end)
    end)
end

local function rawfn(bank, build, nameoverride)
    local inst = commonfn(bank, build, "idle", false, true, true)

    if nameoverride then
        inst:SetPrefabNameOverride(nameoverride)
    end

    if not TheWorld.ismastersim then
        return inst
    end

    inst.components.edible.healthvalue = TUNING.HEALING_TINY
    inst.components.edible.hungervalue = TUNING.CALORIES_SMALL
    inst.components.perishable:SetPerishTime(TUNING.PERISH_SUPERFAST)
    inst.components.perishable.onperishreplacement = "spoiled_fish_small"

    inst:DoTaskInTime(5, stopkicking)
    inst.components.inventoryitem:SetOnPickupFn(stopkicking)
    inst.OnLoad = stopkicking

    inst:ListenForEvent("animover", function()
        if inst.AnimState:IsCurrentAnimation("idle") then
            flopsound(inst)
            inst.AnimState:PlayAnimation("idle")
        end
    end)
    flopsound(inst)

    return inst
end

local function cookedfn(bank, build, nameoverride)
    local inst = commonfn(bank, build, "cooked")

    if nameoverride then
        inst:SetPrefabNameOverride(nameoverride.."_cooked")
    end

    if not TheWorld.ismastersim then
        return inst
    end

    inst.components.edible.healthvalue = TUNING.HEALING_TINY
    inst.components.edible.hungervalue = TUNING.CALORIES_SMALL
    inst.components.perishable:SetPerishTime(TUNING.PERISH_FAST)
    inst.components.perishable.onperishreplacement = "spoiled_fish_small"

    inst.components.floater:SetVerticalOffset(0.2)
    inst.components.floater:SetScale(0.75)

    return inst
end

local function makefish(bank, build, nameoverride, data)
    local function makerawfn()
        local raw = rawfn(bank, build, nameoverride)
        if not TheWorld.ismastersim then
            return raw
        end
        if data.cookproduct then
            raw.components.cookable.product = data.cookproduct
        end
        return raw
    end

    local function makecookedfn()
        return cookedfn(bank, build, nameoverride)
    end

    return makerawfn, makecookedfn
end

local function fish(name, bank, build, nameoverride, data)
    local raw, cooked = makefish(bank, build, nameoverride, data)
    return Prefab(name, raw, assets, prefabs),
        Prefab(name.."_cooked", cooked, assets)
end

return fish("coi", "coi", "coi", nil, {cookproduct = "coi_cooked"})
