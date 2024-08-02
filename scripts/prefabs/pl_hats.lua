local function MakeHat(name)
    local fns = {}
    local fname = "hat_" .. name
    local symname = name .. "hat"
    local prefabname = symname

    local swap_data = {bank = symname, anim = "anim"}

    -- do not pass this function to equippable:SetOnEquip as it has different a parameter listing
    local function _base_onequip(inst, owner, symbol_override, swap_hat_override, override_build, override_skin_build)
        local skin_build = inst:GetSkinBuild()
        if skin_build ~= nil then
            owner:PushEvent("equipskinneditem", inst:GetSkinName())
            owner.AnimState:OverrideItemSkinSymbol(swap_hat_override or "swap_hat", override_skin_build or skin_build,
                symbol_override or "swap_hat", inst.GUID, fname)
        else
            owner.AnimState:OverrideSymbol(swap_hat_override or "swap_hat", override_build or fname, symbol_override or "swap_hat")
        end

        if inst.components.fueled ~= nil then
            inst.components.fueled:StartConsuming()
        end

        if inst.skin_equip_sound and owner.SoundEmitter then
            owner.SoundEmitter:PlaySound(inst.skin_equip_sound)
        end
    end

    -- do not pass this function to equippable:SetOnEquip as it has different a parameter listing
    local function _onequip(inst, owner, symbol_override, headbase_hat_override, override_build, override_skin_build)
        _base_onequip(inst, owner, symbol_override, nil, override_build, override_skin_build)

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
            owner.AnimState:Show("HEAD_HAT_NOHELM")
            owner.AnimState:Hide("HEAD_HAT_HELM")
        end
    end

    local function _onunequip(inst, owner)
        local skin_build = inst:GetSkinBuild()
        if skin_build ~= nil then
            owner:PushEvent("unequipskinneditem", inst:GetSkinName())
        end

        owner.AnimState:ClearOverrideSymbol("headbase_hat") --it might have been overriden by _onequip
        if owner.components.skinner ~= nil then
            owner.components.skinner.base_change_cb = owner.old_base_change_cb
        end

        owner.AnimState:ClearOverrideSymbol("swap_hat")
        owner.AnimState:Hide("HAT")
        owner.AnimState:Hide("HAIR_HAT")
        owner.AnimState:Show("HAIR_NOHAT")
        owner.AnimState:Show("HAIR")

        if owner:HasTag("player") then
            owner.AnimState:Show("HEAD")
            owner.AnimState:Hide("HEAD_HAT")
            owner.AnimState:Hide("HEAD_HAT_NOHELM")
            owner.AnimState:Hide("HEAD_HAT_HELM")
        end

        if inst.components.fueled ~= nil then
            inst.components.fueled:StopConsuming()
        end
    end

    -- This is not really implemented, can just use _onequip
	fns.simple_onequip =  function(inst, owner, from_ground)
		_onequip(inst, owner)
	end

    -- This is not really implemented, can just use _onunequip
	fns.simple_onunequip = function(inst, owner, from_ground)
		_onunequip(inst, owner)
	end

    fns.opentop_onequip = function(inst, owner)
        _base_onequip(inst, owner)

        owner.AnimState:Show("HAT")
        owner.AnimState:Hide("HAIR_HAT")
        owner.AnimState:Show("HAIR_NOHAT")
        owner.AnimState:Show("HAIR")

        owner.AnimState:Show("HEAD")
        owner.AnimState:Hide("HEAD_HAT")
        owner.AnimState:Hide("HEAD_HAT_NOHELM")
        owner.AnimState:Hide("HEAD_HAT_HELM")
    end

    fns.fullhelm_onequip = function(inst, owner)
        if owner:HasTag("player") then
            _base_onequip(inst, owner, nil, "headbase_hat")

            owner.AnimState:Hide("HAT")
            owner.AnimState:Hide("HAIR_HAT")
            owner.AnimState:Hide("HAIR_NOHAT")
            owner.AnimState:Hide("HAIR")

            owner.AnimState:Hide("HEAD")
            owner.AnimState:Show("HEAD_HAT")
            owner.AnimState:Hide("HEAD_HAT_NOHELM")
            owner.AnimState:Show("HEAD_HAT_HELM")

            owner.AnimState:HideSymbol("face")
            owner.AnimState:HideSymbol("swap_face")
            owner.AnimState:HideSymbol("beard")
            owner.AnimState:HideSymbol("cheeks")

            owner.AnimState:UseHeadHatExchange(true)
        else
            _base_onequip(inst, owner)

            owner.AnimState:Show("HAT")
            owner.AnimState:Hide("HAIR_HAT")
            owner.AnimState:Hide("HAIR_NOHAT")
            owner.AnimState:Hide("HAIR")
        end
    end

    fns.fullhelm_onunequip = function(inst, owner)
        _onunequip(inst, owner)

        if owner:HasTag("player") then
            owner.AnimState:ShowSymbol("face")
            owner.AnimState:ShowSymbol("swap_face")
            owner.AnimState:ShowSymbol("beard")
            owner.AnimState:ShowSymbol("cheeks")

            owner.AnimState:UseHeadHatExchange(false)
        end
    end

    fns.simple_onequiptomodel = function(inst, owner, from_ground)
        if inst.components.fueled ~= nil then
            inst.components.fueled:StopConsuming()
        end
    end

    local _skinfns = { -- NOTES(JBK): These are useful for skins to have access to them instead of sometimes storing a reference to a hat.
        opentop_onequip = fns.opentop_onequip,
        fullhelm_onequip = fns.fullhelm_onequip,
        fullhelm_onunequip = fns.fullhelm_onunequip,
        simple_onequiptomodel = fns.simple_onequiptomodel,
    }

    local function simple(custom_init)
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddNetwork()

        MakeInventoryPhysics(inst)

        inst.AnimState:SetBank(symname)
        inst.AnimState:SetBuild(fname)
        inst.AnimState:PlayAnimation("anim")

        inst:AddTag("hat")

        if custom_init ~= nil then
            custom_init(inst)
        end

        MakeInventoryFloatable(inst)
        inst.components.floater:UpdateAnimations("idle_water", "anim")
        inst.components.floater:SetBankSwapOnFloat(false, nil, swap_data) --Hats default animation is not "idle", so even though we don't swap banks, we need to specify the swap_data for re-skinning to reset properly when floating

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        inst._skinfns = _skinfns

        inst:AddComponent("inventoryitem")

        inst:AddComponent("inspectable")

        inst:AddComponent("tradable")

        inst:AddComponent("equippable")
        inst.components.equippable.equipslot = EQUIPSLOTS.HEAD
        inst.components.equippable:SetOnEquip(fns.simple_onequip)
        inst.components.equippable:SetOnUnequip(fns.simple_onunequip)
        inst.components.equippable:SetOnEquipToModel(fns.simple_onequiptomodel)

        MakeHauntableLaunch(inst)

        return inst
    end

    local function default()
        return simple()
    end

    -----------------------------------------------------------------------------

    local function bat_onequip(inst, owner)
        _onequip(inst, owner)

        if not owner:HasTag("player") then
            return
        end

        inst.bat_sonar_on:push()
        owner.SoundEmitter:PlaySound("dontstarve_DLC003/common/crafted/batmask/on")
    end

    local function bat_onunequip(inst, owner)
        _onunequip(inst, owner)

        if not owner:HasTag("player") then
            return
        end

        inst.bat_sonar_off:push()
        owner.SoundEmitter:PlaySound("dontstarve_DLC003/common/crafted/batmask/off")
    end

    local function bat_custom_init(inst)
        inst:AddTag("bat_hat")
        inst:AddTag("clearfog")
        inst:AddTag("nightvision")
        inst:AddTag("no_sewing")
        inst:AddTag("venting")

        inst.bat_sonar_on = net_event(inst.GUID, "bat_sonar_on")
        inst.bat_sonar_off = net_event(inst.GUID, "bat_sonar_off")

        if not TheNet:IsDedicated() then
            inst:ListenForEvent("bat_sonar_on", function()
                if ThePlayer.replica.inventory:EquipHasTag("bat_hat") then
                    ThePlayer:PushEvent("startbatsonar")
                end
            end)

            inst:ListenForEvent("bat_sonar_off", function()
                if not ThePlayer.replica.inventory:EquipHasTag("bat_hat") then
                    ThePlayer:PushEvent("stopbatsonar")
                end
            end)
        end
    end

    fns.bat = function()
        local inst = simple(bat_custom_init)

        if not TheWorld.ismastersim then
            return inst
        end

        inst.components.equippable:SetOnEquip(bat_onequip)
        inst.components.equippable:SetOnUnequip(bat_onunequip)

        inst:AddComponent("fueled")
        inst.components.fueled.fueltype = FUELTYPE.USAGE
        inst.components.fueled:InitializeFuelLevel(TUNING.BATHAT_PERISHTIME)
        inst.components.fueled:SetDepletedFn(inst.Remove)
        inst.components.fueled.accepting = true

        inst.transition = false

        return inst
    end

    -----------------------------------------------------------------------------

    local function snake_equip(inst, owner)
        _onequip(inst, owner, nil, nil, "hat_snakeskin_scaly")
    end

    local function snake_custom_init(inst)
        inst.AnimState:SetBuild("hat_snakeskin_scaly")

        inst:SetPrefabName("snakeskinhat")

        inst.shelfart = "snakeskinhat_scaly"
    end

    fns.snakeskin = function()
        local inst = simple(snake_custom_init)

        if not TheWorld.ismastersim then
            return inst
        end

        inst.components.inventoryitem:ChangeImageName("snakeskinhat_scaly")

        inst:AddComponent("fueled")
        inst.components.fueled.fueltype = FUELTYPE.USAGE
        inst.components.fueled:InitializeFuelLevel(TUNING.SNAKESKINHAT_PERISHTIME)
        inst.components.fueled:SetDepletedFn(inst.Remove)

        inst:AddComponent("waterproofer")
        inst.components.waterproofer:SetEffectiveness(TUNING.WATERPROOFNESS_LARGE)

        inst.components.equippable.insulated = true
        inst.components.equippable:SetOnEquip(snake_equip)

        return inst
    end

    -----------------------------------------------------------------------------

    local function thunder_equip(inst, owner)
        _onequip(inst, owner)
        inst:AddTag("lightningrod")
    end

    local function thunder_unequip(inst, owner)
        _onunequip(inst, owner)
        inst:RemoveTag("lightningrod")
    end

    fns.thunder = function()
        local inst = simple()

        if not TheWorld.ismastersim then
            return inst
        end

        inst.components.equippable.dapperness = TUNING.DAPPERNESS_SMALL

        inst:AddComponent("fueled")
        inst.components.fueled.fueltype = FUELTYPE.USAGE
        inst.components.fueled:InitializeFuelLevel(TUNING.THUNDERHAT_PERISHTIME)
        inst.components.fueled:SetDepletedFn(inst.Remove)

        inst.components.equippable:SetOnEquip(thunder_equip)
        inst.components.equippable:SetOnUnequip(thunder_unequip)

        inst:ListenForEvent("lightningstrike", function(inst, data)
            inst.components.fueled:DoDelta(-inst.components.fueled.maxfuel * TUNING.THUNDERHAT_USAGE_PER_LIGHTINING_STRIKE)
        end)

        return inst
    end

    -----------------------------------------------------------------------------

    local function disguise_onequip(inst, owner)
        fns.opentop_onequip(inst, owner)
        inst.monster = owner:HasTag("monster")
        owner:RemoveTag("monster")
    end

    local function disguise_unequip(inst, owner)
        _onunequip(inst, owner)
        if inst.monster then
            inst.monster = nil
            owner:AddTag("monster")
        end
    end

    local function disguise_custom_init(inst)
        inst:AddTag("disguise")
    end

    fns.disguise = function()
        local inst = simple(disguise_custom_init)

        if not TheWorld.ismastersim then
            return inst
        end

        inst.components.equippable:SetOnEquip(disguise_onequip)
        inst.components.equippable:SetOnUnequip(disguise_unequip)

        return inst
    end

    -----------------------------------------------------------------------------

    local function metalplate_custom_init(inst)
        inst:AddTag("smeltable") -- Smelter
    end

    fns.metalplate = function()
        local inst = simple(metalplate_custom_init)

        if not TheWorld.ismastersim then
            return inst
        end

        inst:AddComponent("armor")
        inst.components.armor:InitCondition(TUNING.ARMOR_KNIGHT, TUNING.ARMOR_KNIGHT_ABSORPTION)

        inst:AddComponent("waterproofer")
        inst.components.waterproofer:SetEffectiveness(TUNING.WATERPROOFNESS_SMALL)

        inst.components.equippable.walkspeedmult = TUNING.ARMORMETAL_SLOW

        return inst
    end

    -----------------------------------------------------------------------------

    local function candle_turnon(inst)
        local owner = inst.components.inventoryitem and inst.components.inventoryitem.owner
        if owner then
            _onequip(inst, owner)
        end

        if inst.components.fueled:IsEmpty() then
            return
        end

        inst.components.fueled:StartConsuming()

        inst.SoundEmitter:PlaySound("dontstarve/wilson/torch_LP", "torch")
        inst.SoundEmitter:SetParameter("torch", "intensity", 1)

        if not inst.fire then
            inst.fire = SpawnPrefab("candlefire")
            local follower = inst.fire.entity:AddFollower()
            follower:FollowSymbol(owner.GUID, "swap_hat", 0, -250, 0)
        end
    end

    local function candle_turnoff(inst)
        if inst.components.equippable and inst.components.equippable:IsEquipped() then
            local owner = inst.components.inventoryitem and inst.components.inventoryitem.owner
            if owner then
                _onequip(inst, owner)
            end
        end
        inst.components.fueled:StopConsuming()

        if inst.fire then
            inst.fire:Remove()
            inst.fire = nil
        end

        inst.SoundEmitter:KillSound("torch")
        inst.SoundEmitter:PlaySound("dontstarve/common/fireOut")
    end

    local function candle_equip(inst, owner)
        candle_turnon(inst)
    end

    local function candle_unequip(inst, owner)
        _onunequip(inst, owner)
        candle_turnoff(inst)
    end

    local function candle_equiptomodel(inst, owner)
        candle_equip(inst, owner)
        candle_turnoff(inst)
    end

    local function candle_perish(inst)
        local owner = inst.components.inventoryitem and inst.components.inventoryitem.owner
        if owner then
            owner:PushEvent("torchranout", {torch = inst})
        end
        candle_turnoff(inst)
    end

    local function candle_drop(inst)
        candle_turnoff(inst)
    end

    local function candle_takefuel(inst)
        inst.SoundEmitter:PlaySound("dontstarve/common/fireAddFuel")
        if inst.components.equippable and inst.components.equippable:IsEquipped() then
            candle_turnon(inst)
        end
    end

    local function candle_custom_init(inst)
        inst.entity:AddSoundEmitter()
        inst:AddTag("smeltable") -- Smelter
    end

    fns.candle = function()
        local inst = simple(candle_custom_init)

        if not TheWorld.ismastersim then
            return inst
        end

        inst:AddComponent("waterproofer")
        inst.components.waterproofer:SetEffectiveness(TUNING.WATERPROOFNESS_SMALL)

        inst.components.inventoryitem:SetOnDroppedFn(candle_drop)

        inst.components.equippable:SetOnEquip(candle_equip)
        inst.components.equippable:SetOnUnequip(candle_unequip)
        inst.components.equippable:SetOnEquipToModel(candle_equiptomodel)

        inst:AddComponent("fueled")
        inst.components.fueled.fueltype = FUELTYPE.CORK
        inst.components.fueled:InitializeFuelLevel(TUNING.CANDLEHAT_LIGHTTIME)
        inst.components.fueled:SetDepletedFn(candle_perish)
        inst.components.fueled.ontakefuelfn = candle_takefuel
        inst.components.fueled.accepting = true

        return inst
    end

    -----------------------------------------------------------------------------

    local function bandit_custom_init(inst)
        inst:AddTag("sneaky")
    end

    fns.bandit = function()
        local inst = simple(bandit_custom_init)

        if not TheWorld.ismastersim then
            return inst
        end

        inst.components.equippable.dapperness = TUNING.DAPPERNESS_SMALL

        inst:AddComponent("fueled")
        inst.components.fueled.fueltype = FUELTYPE.USAGE
        inst.components.fueled:InitializeFuelLevel(TUNING.BANDITHAT_PERISHTIME)
        inst.components.fueled:SetDepletedFn(inst.Remove)

        return inst
    end

    -----------------------------------------------------------------------------

    local function pith_custom_init(inst)
        inst:AddTag("venting")
        inst:AddTag("fogproof")
    end

    fns.pith = function()
        local inst = simple(pith_custom_init)

        if not TheWorld.ismastersim then
            return inst
        end

        inst.components.equippable.dapperness = TUNING.DAPPERNESS_SMALL

        inst:AddComponent("fueled")
        inst.components.fueled.fueltype = FUELTYPE.USAGE
        inst.components.fueled:InitializeFuelLevel(TUNING.PITHHAT_PERISHTIME)
        inst.components.fueled:SetDepletedFn(inst.Remove)

        inst:AddComponent("waterproofer")
        inst.components.waterproofer:SetEffectiveness(TUNING.WATERPROOFNESS_MED)

        return inst
    end

    -----------------------------------------------------------------------------

    local function gasmask_custom_init(inst)
        inst:AddTag("gasmask")
        inst:AddTag("muffler") -- TODO add missing sound effects
    end

    fns.gasmask = function()
        local inst = simple(gasmask_custom_init)

        if not TheWorld.ismastersim then
            return inst
        end

        inst.components.equippable.dapperness = TUNING.CRAZINESS_SMALL

        inst.components.equippable.poisongasblocker = true

        inst.components.equippable:SetOnEquip(fns.opentop_onequip)

        inst:AddComponent("fueled")
        inst.components.fueled.fueltype = FUELTYPE.USAGE
        inst.components.fueled:InitializeFuelLevel(TUNING.GASMASK_PERISHTIME)
        inst.components.fueled:SetDepletedFn(inst.Remove)

        return inst
    end

    -----------------------------------------------------------------------------

    local function pigcrown_custom_init(inst)
        inst:AddTag("pigcrown")
        inst:AddTag("irreplaceable")
    end

    fns.pigcrown = function()
        local inst = simple(pigcrown_custom_init)

        if not TheWorld.ismastersim then
            return inst
        end

        inst.components.equippable.dapperness = TUNING.DAPPERNESS_MED_LARGE

        return inst
    end

    -----------------------------------------------------------------------------

    local function antmask_onupdate(inst)
        inst.components.armor:SetPercent(inst.components.fueled:GetPercent())
    end

    local function antmask_ontakedamage(inst, damage_amount)
        if inst.components.fueled then
            local percent = inst.components.fueled:GetPercent()
            local new_percent = percent - (damage_amount * inst.components.armor.absorb_percent / inst.components.armor.maxcondition)
            inst.components.fueled:SetPercent(new_percent)
        end
    end

    local function antmask_custom_init(inst)
        inst:AddTag("antmask")
    end

    fns.antmask = function()
        local inst = simple(antmask_custom_init)

        if not TheWorld.ismastersim then
            return inst
        end

        inst:AddComponent("armor")
        inst.components.armor:InitCondition(TUNING.ARMOR_FOOTBALLHAT, TUNING.ARMOR_FOOTBALLHAT_ABSORPTION)
        inst.components.armor.ontakedamage = antmask_ontakedamage

        inst:AddComponent("fueled")
        inst.components.fueled.fueltype = FUELTYPE.USAGE
        inst.components.fueled:InitializeFuelLevel(TUNING.ANTMASKHAT_PERISHTIME)
        inst.components.fueled:SetDepletedFn(inst.Remove)
        inst.components.fueled:SetUpdateFn(antmask_onupdate)

        return inst
    end

    -----------------------------------------------------------------------------

    local fn = nil
    local assets = {Asset("ANIM", "anim/" .. fname .. ".zip") }
    local prefabs = nil

	if name == "candle" then
		fn = fns.candle
	elseif name == "bandit" then
		fn = fns.bandit
	elseif name == "pith" then
		fn = fns.pith
	elseif name == "gasmask" then
		fn = fns.gasmask
	elseif name == "pigcrown" then
		fn = fns.pigcrown
	elseif name == "antmask" then
		fn = fns.antmask
	elseif name == "bat" then
		fn = fns.bat
        table.insert(assets, Asset("IMAGE", "images/colour_cubes/bat_vision_on_cc.tex"))
	elseif name == "snakeskin" then
		fn = fns.snakeskin
        table.insert(assets, Asset("ANIM", "anim/hat_snakeskin_scaly.zip"))
	elseif name == "thunder" then
		fn = fns.thunder
	elseif name == "metalplate" then
		fn = fns.metalplate
	elseif name == "disguise" then
		fn = fns.disguise
	end

    table.insert(ALL_HAT_PREFAB_NAMES, prefabname)

    return Prefab(prefabname, fn or default, assets, prefabs)
end

return  MakeHat("antmask"),
        MakeHat("bandit"),
        MakeHat("candle"),
        MakeHat("gasmask"),
        MakeHat("metalplate"),
        MakeHat("pigcrown"),
        MakeHat("pith"),
        MakeHat("thunder"),
        MakeHat("snakeskin"),
        MakeHat("disguise"),
        MakeHat("bat")
