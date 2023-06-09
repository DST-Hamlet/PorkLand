local prefabs = {}

local function OnDepleted(inst)
    inst:Remove()
end

local function Common_OnEquip(inst, owner, symbol_override, headbase_hat_override)
    local skin_build = inst:GetSkinBuild()
    if skin_build ~= nil then
        owner:PushEvent("equipskinneditem", inst:GetSkinName())
        owner.AnimState:OverrideItemSkinSymbol("swap_hat", skin_build, symbol_override or "swap_hat", inst.GUID, inst.fname)
    else
        owner.AnimState:OverrideSymbol("swap_hat", inst.fname, symbol_override or "swap_hat")
    end

    owner.AnimState:ClearOverrideSymbol("headbase_hat") --clear out previous overrides
    if headbase_hat_override ~= nil then
        local skin_build = owner.AnimState:GetSkinBuild()
        if skin_build ~= "" then
            owner.AnimState:OverrideSkinSymbol("headbase_hat", skin_build, headbase_hat_override )
        else
            local build = owner.AnimState:GetBuild()
            owner.AnimState:OverrideSymbol("headbase_hat", build, headbase_hat_override)
        end
    end

    owner.AnimState:Show("HAT")
    owner.AnimState:Show("HAIR_HAT")
    owner.AnimState:Hide("HAIR_NOHAT")
    owner.AnimState:Hide("HAIR")

    if owner:HasTag("player") then
        owner.AnimState:Hide("HEAD")
        owner.AnimState:Show("HEAD_HAT")
    end

    if inst.components.fueled ~= nil then
        inst.components.fueled:StartConsuming()
    end
end

local function Common_OnUnEquip(inst, owner)
    local skin_build = inst:GetSkinBuild()
    if skin_build ~= nil then
        owner:PushEvent("unequipskinneditem", inst:GetSkinName())
    end

    owner.AnimState:ClearOverrideSymbol("swap_hat")
    owner.AnimState:ClearOverrideSymbol("headbase_hat") --it might have been overriden by _onequip

    owner.AnimState:Hide("HAT")
    owner.AnimState:Hide("HAIR_HAT")
    owner.AnimState:Show("HAIR_NOHAT")
    owner.AnimState:Show("HAIR")

    if owner:HasTag("player") then
        owner.AnimState:Show("HEAD")
        owner.AnimState:Hide("HEAD_HAT")
    end

    if inst.components.fueled ~= nil then
        inst.components.fueled:StopConsuming()
    end
end

local function SetOpenTop(inst, owner)
    local skin_build = inst:GetSkinBuild()
    if skin_build ~= nil then
        owner:PushEvent("equipskinneditem", inst:GetSkinName())
        owner.AnimState:OverrideItemSkinSymbol("swap_hat", skin_build, "swap_hat", inst.GUID, inst.fname)
    else
        owner.AnimState:OverrideSymbol("swap_hat", inst.fname, "swap_hat")
    end

    owner.AnimState:Show("HAT")
    owner.AnimState:Hide("HAIR_HAT")
    owner.AnimState:Show("HAIR_NOHAT")
    owner.AnimState:Show("HAIR")

    owner.AnimState:Show("HEAD")
    owner.AnimState:Hide("HEAD_HAT")

    if inst.components.fueled ~= nil then
        inst.components.fueled:StartConsuming()
    end
end

local function MakeHat(name, common_postinit, master_postinit, onequip, onunequip, onequiptomodel)
    local fname = "hat_"..name
	local symname = name.."hat"
    local prefabname = symname
	local assets = {
        Asset("ANIM", "anim/"..fname..".zip"),
	}

    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddNetwork()

        MakeInventoryPhysics(inst)
        MakeInventoryFloatable(inst)
        -- MakeInventoryFloatable(inst, "idle_water", "anim")

        inst.AnimState:SetBank(symname)
        inst.AnimState:SetBuild(fname)
        inst.AnimState:PlayAnimation("anim")

        inst:AddTag("hat")

        if common_postinit ~= nil then
            common_postinit(inst)
        end

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        inst:AddComponent("inventoryitem")
        inst:AddComponent("inspectable")
        inst:AddComponent("tradable")

        inst:AddComponent("equippable")
        inst.components.equippable.equipslot = EQUIPSLOTS.HEAD
        inst.components.equippable:SetOnEquip(onequip)
        inst.components.equippable:SetOnUnequip(onunequip)
        if onequiptomodel ~= nil then
            inst.components.equippable:SetOnEquipToModel(onequiptomodel)
        end

        if master_postinit ~= nil then
            master_postinit(inst)
        end

        inst.fname = fname

        MakeHauntableLaunch(inst)

        return inst
    end
    return Prefab(prefabname, fn, assets, prefabs)
end

-------------------------------------------------------------------------------------

-- gasmask
local function gasmask_equipfn(inst, owner)
    SetOpenTop(inst, owner)
    if inst:HasTag("gasmask") then
        owner:AddTag("has_gasmask")
    end
end

local function gasmask_unequipfn(inst,owner)
    Common_OnUnEquip(inst, owner)
    if inst:HasTag("gasmask") then
        owner:RemoveTag("has_gasmask")
    end
end

local function gasmask_commom_postinit(inst)
    inst:AddTag("gasmask")
    inst:AddTag("muffler")
end

local function gasmask_master_postinit(inst)
    inst.components.equippable.dapperness = TUNING.CRAZINESS_SMALL
    inst.components.equippable.poisongasblocker = true

    inst:AddComponent("fueled")
    inst.components.fueled.fueltype = FUELTYPE.USAGE
    inst.components.fueled:InitializeFuelLevel(TUNING.GASMASK_PERISHTIME)
    inst.components.fueled:SetDepletedFn(OnDepleted)
end

-- pith
local function pith_equipfn(inst, owner)
    Common_OnEquip(inst, owner)
    if inst:HasTag("venting") then
        owner:AddTag("venting")
    end
end

local function pith_unequipfn(inst, owner)
    Common_OnUnEquip(inst, owner)
    if inst:HasTag("venting") then
        owner:RemoveTag("venting")
    end
end

local function pith_commom_postinit(inst)
    inst:AddTag("venting")
    inst:AddTag("fogproof")
end

local function pith_master_postinit(inst)
    inst.components.equippable.dapperness = TUNING.DAPPERNESS_SMALL
    inst:AddComponent("waterproofer")
    inst.components.waterproofer:SetEffectiveness(TUNING.WATERPROOFNESS_MED)

    inst:AddComponent("fueled")
    inst.components.fueled.fueltype = FUELTYPE.USAGE
    inst.components.fueled:InitializeFuelLevel(TUNING.PITHHAT_PERISHTIME)
    inst.components.fueled:SetDepletedFn(OnDepleted)
end

-------------------------------------------------------------------------------------

local hats_data = {
    gasmask = {
        onequip = gasmask_equipfn,
        onunequip = gasmask_unequipfn,
        common_postinit = gasmask_commom_postinit,
        master_postinit = gasmask_master_postinit,
    },
    pith = {
        onequip = pith_equipfn,
        onunequip = pith_unequipfn,
        common_postinit = pith_commom_postinit,
        master_postinit = pith_master_postinit,
    },
}

local hats = {}
for k, v in pairs(hats_data) do
    table.insert(hats, MakeHat(k, v.common_postinit,v.master_postinit, v.onequip, v.onunequip, v.onequiptomodel))
end

return unpack(hats)
