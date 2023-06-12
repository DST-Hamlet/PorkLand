local function MakeHat(name)
    local fname = "hat_" .. name
    local symname = name .. "hat"
    local prefabname = symname

    local function generic_perish(inst)
        inst:Remove()
    end

    -- do not pass this function to equippable:SetOnEquip as it has different a parameter listing
    local function _onequip(inst, owner, symbol_override)
        local skin_build = inst:GetSkinBuild()
        if skin_build ~= nil then
            owner:PushEvent("equipskinneditem", inst:GetSkinName())
            owner.AnimState:OverrideItemSkinSymbol("swap_hat", skin_build, symbol_override or "swap_hat", inst.GUID,
                fname)
        else
            owner.AnimState:OverrideSymbol("swap_hat", inst.override or fname, symbol_override or "swap_hat")
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

		if inst:HasTag("antmask") then
			owner:AddTag("has_antmask")
		end		

		if inst:HasTag("gasmask") then
			owner:AddTag("has_gasmask")
		end				

		if inst:HasTag("venting") then
			owner:AddTag("venting")
		end

		if inst:HasTag("sneaky") then
			if not owner:HasTag("monster") then
				owner:AddTag("monster")
			else
				owner:AddTag("originaly_monster")
			end
			owner:AddTag("sneaky")
		end	
    end

    local function _onunequip(inst, owner)
        local skin_build = inst:GetSkinBuild()
        if skin_build ~= nil then
            owner:PushEvent("unequipskinneditem", inst:GetSkinName())
        end

        owner.AnimState:ClearOverrideSymbol("swap_hat")
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

        if inst:HasTag("antmask") then
			owner:RemoveTag("has_antmask")
		end	
		if inst:HasTag("gasmask") then
			owner:RemoveTag("has_gasmask")
		end	

		if inst:HasTag("venting") then
			owner:RemoveTag("venting")
		end	

		if inst:HasTag("sneaky") then
			if not owner:HasTag("originaly_monster") then
				owner:RemoveTag("monster")
			else
				owner:RemoveTag("originaly_monster")
			end
			owner:RemoveTag("sneaky")
		end	
    end

    local function simple_onequip(inst, owner, from_ground)
        _onequip(inst, owner)
    end

    local function simple_onunequip(inst, owner, from_ground)
        _onunequip(inst, owner)
    end

    local function simple_onequiptomodel(inst, owner, from_ground)
        if inst.components.fueled ~= nil then
            inst.components.fueled:StopConsuming()
        end
    end

    local function opentop_onequip(inst, owner)
        local skin_build = inst:GetSkinBuild()
        if skin_build ~= nil then
            owner:PushEvent("equipskinneditem", inst:GetSkinName())
            owner.AnimState:OverrideItemSkinSymbol("swap_hat", skin_build, "swap_hat", inst.GUID, fname)
        else
            owner.AnimState:OverrideSymbol("swap_hat", fname, "swap_hat")
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

        if inst:HasTag("gasmask") then
			owner:AddTag("has_gasmask")
		end
    end

    local function simple_common(custom_init)
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
        --inst.components.floater:UpdateAnimations("idle_water", "anim")

        return inst
    end

    local function simple_master(inst, image)
        inst:AddComponent("inventoryitem")
		if image then inst.components.inventoryitem.imagename = image
		end

        inst:AddComponent("inspectable")

        inst:AddComponent("tradable")

        inst:AddComponent("equippable")
        inst.components.equippable.equipslot = EQUIPSLOTS.HEAD
        inst.components.equippable:SetOnEquip(simple_onequip)
        inst.components.equippable:SetOnUnequip(simple_onunequip)
        inst.components.equippable:SetOnEquipToModel(simple_onequiptomodel)

        MakeHauntableLaunch(inst)
    end

    --------

    local function metalplate()
        local inst = simple_common()

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        simple_master(inst)

        inst:AddComponent("armor")
		inst.components.armor:InitCondition(TUNING.ARMOR_KNIGHT, TUNING.ARMOR_KNIGHT_ABSORPTION)

		inst:AddTag("smeltable") -- Smelter

		inst:AddComponent("waterproofer")
		inst.components.waterproofer:SetEffectiveness(TUNING.WATERPROOFNESS_SMALL)
		
    	inst.components.equippable.walkspeedmult = TUNING.ARMORMETAL_SLOW


        return inst
    end

    --------
	local function candle_turnon(inst, owner)
		if owner then
			_onequip(inst, owner)
		end
		if not inst.components.fueled:IsEmpty() then
			inst.components.fueled:StartConsuming()

	        inst.SoundEmitter:PlaySound("dontstarve/wilson/torch_LP", "torch")
	        inst.SoundEmitter:SetParameter( "torch", "intensity", 1 )

	        if not inst.fire then 
	            inst.fire = SpawnPrefab("candlefire")
	            inst.fire:AddTag("INTERIOR_LIMBO_IMMUNE")
				inst.fire.entity:SetParent(owner.entity)
				inst.fire.entity:AddFollower()
	            inst.fire.Follower:FollowSymbol(owner.GUID, "swap_hat", -10, -250, 0)
	        end 
			--inst.Light:Enable(true)
		end
	end

	local function candle_turnoff(inst, ranout)
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
		--inst.Light:Enable(false)
	end

	local function candle_equip(inst, owner)
		candle_turnon(inst, owner)
	end
	
	local function candle_unequip(inst, owner)
		_onunequip(inst, owner)
		candle_turnoff(inst)
	end
	
	local function candle_onequiptomodel(inst, owner)
		simple_onequiptomodel(inst, owner)
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

    local function candle()
        local inst = simple_common()

	    --waterproofer (from waterproofer component) added to pristine state for optimization
	    inst:AddTag("waterproofer")
		
        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        simple_master(inst)
		
		inst.entity:AddSoundEmitter() 
        inst:AddComponent("waterproofer")
		inst.components.waterproofer:SetEffectiveness(TUNING.WATERPROOFNESS_SMALL)

        inst.components.inventoryitem:SetOnDroppedFn(candle_drop)
		inst.components.equippable:SetOnEquip(candle_equip)
		inst.components.equippable:SetOnUnequip(candle_unequip)
        inst.components.equippable:SetOnEquipToModel(candle_onequiptomodel)

		inst:AddComponent("fueled")
		inst.components.fueled.fueltype = FUELTYPE.CORK
		inst.components.fueled:InitializeFuelLevel(TUNING.CANDLEHAT_LIGHTTIME)
        inst.components.fueled:SetFirstPeriod(TUNING.TURNON_FUELED_CONSUMPTION, TUNING.TURNON_FULL_FUELED_CONSUMPTION)
		inst.components.fueled:SetDepletedFn(candle_perish)
		inst.components.fueled.ontakefuelfn = candle_takefuel
		inst.components.fueled.accepting = true

		inst:AddTag("smeltable") -- Smelter

        return inst
    end

    --------

    local function bandit()
        local inst = simple_common()

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        simple_master(inst)

        inst.components.equippable.dapperness = TUNING.DAPPERNESS_SMALL
		
		inst:AddComponent("fueled")
		inst.components.fueled.fueltype = "USAGE"
		inst.components.fueled:InitializeFuelLevel(TUNING.BANDITHAT_PERISHTIME)
        inst.components.fueled:SetFirstPeriod(TUNING.TURNON_FUELED_CONSUMPTION, TUNING.TURNON_FULL_FUELED_CONSUMPTION)
		inst.components.fueled:SetDepletedFn(generic_perish)
		inst:AddTag("sneaky")

        return inst
    end

    --------

    local function pith()
        local inst = simple_common()

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        simple_master(inst)

        inst.components.equippable.dapperness = TUNING.DAPPERNESS_SMALL
		inst:AddComponent("fueled")
		inst.components.fueled.fueltype = "USAGE"
		inst.components.fueled:InitializeFuelLevel(TUNING.PITHHAT_PERISHTIME)
        inst.components.fueled:SetFirstPeriod(TUNING.TURNON_FUELED_CONSUMPTION, TUNING.TURNON_FULL_FUELED_CONSUMPTION)
		inst.components.fueled:SetDepletedFn(generic_perish)

		inst:AddTag("venting")
		inst:AddTag("fogproof")

		inst:AddComponent("waterproofer")
		inst.components.waterproofer:SetEffectiveness(TUNING.WATERPROOFNESS_MED)

        return inst
    end

    --------

    local function gasmask()
        local inst = simple_common()

        inst:AddTag("gasmask")
		inst:AddTag("muffler")

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        simple_master(inst)

		inst.components.equippable.dapperness = TUNING.CRAZINESS_SMALL
		inst.components.equippable.poisongasblocker = true

		inst.components.equippable:SetOnEquip( opentop_onequip )

		inst:AddComponent("fueled")
		inst.components.fueled.fueltype = "USAGE"
		inst.components.fueled:InitializeFuelLevel(TUNING.GASMASK_PERISHTIME)
        inst.components.fueled:SetFirstPeriod(TUNING.TURNON_FUELED_CONSUMPTION, TUNING.TURNON_FULL_FUELED_CONSUMPTION)
		inst.components.fueled:SetDepletedFn(generic_perish)
		inst.opentop = true

        return inst
    end

    --------
	
	local function pigcrown()
		local inst = simple_common()
		
		inst:AddTag("pigcrown")
		inst:AddTag("irreplaceable")
		
		inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        simple_master(inst)
		
		inst.components.equippable.dapperness = TUNING.DAPPERNESS_MED_LARGE

		return inst
	end

    --------
	
	local function antmask_onupdate(inst)
		inst.components.armor:SetPercent(inst.components.fueled:GetPercent())
	end

	local function antmask_ontakedamage(inst, damage_amount)
		-- absorbed is the amount of durability that should be consumed
		-- so that's what should be consumed in the fuel
		local absorbed = damage_amount * TUNING.ARMOR_FOOTBALLHAT_ABSORPTION
		local absorbedDamageInPercent = absorbed/inst.components.armor.maxcondition
		if inst.components.fueled then
			local percent = inst.components.fueled:GetPercent()
			local newPercent = percent - absorbedDamageInPercent
			inst.components.fueled:SetPercent(newPercent)
		end
	end
	
    local function antmask()
        local inst = simple_common()

        inst:AddTag("antmask")

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        simple_master(inst)

        inst:AddComponent("armor")
		inst.components.armor:InitCondition(TUNING.ARMOR_FOOTBALLHAT, TUNING.ARMOR_FOOTBALLHAT_ABSORPTION)
		inst.components.armor.ontakedamage = antmask_ontakedamage

        inst:AddComponent("fueled")
		inst.components.fueled.fueltype = "USAGE"
		inst.components.fueled:InitializeFuelLevel(TUNING.ANTMASKHAT_PERISHTIME)
        inst.components.fueled:SetFirstPeriod(TUNING.TURNON_FUELED_CONSUMPTION, TUNING.TURNON_FULL_FUELED_CONSUMPTION)
		inst.components.fueled:SetDepletedFn(generic_perish)
		inst.components.fueled:SetUpdateFn(antmask_onupdate)

        return inst
    end

    --------

    local function peagawkfeather()
        local inst = simple_common()

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        simple_master(inst)

        inst.components.equippable.dapperness = TUNING.DAPPERNESS_LARGE

		inst:AddComponent("fueled")
		inst.components.fueled.fueltype = "USAGE"
		inst.components.fueled:InitializeFuelLevel(TUNING.PEAGAWKHAT_PERISHTIME)
        inst.components.fueled:SetFirstPeriod(TUNING.TURNON_FUELED_CONSUMPTION, TUNING.TURNON_FULL_FUELED_CONSUMPTION)
		inst.components.fueled:SetDepletedFn(generic_perish)

        return inst
    end

    --------

    local function snakeskin()
		--fname = "hat_snakeskin_scaly"
        local inst = simple_common()

	    --waterproofer (from waterproofer component) added to pristine state for optimization
	    inst:AddTag("waterproofer")
		
		--inst.AnimState:SetBuild("hat_snakeskin_scaly")

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end
		inst.override = "hat_snakeskin_scaly"
		simple_master(inst, "snakeskinhat_scaly")
		inst.shelfart = "snakeskinhat_scaly"

        inst:AddComponent("fueled")
        inst.components.fueled.fueltype = "USAGE"
        inst.components.fueled:InitializeFuelLevel(TUNING.SNAKESKINHAT_PERISHTIME)
        inst.components.fueled:SetFirstPeriod(TUNING.TURNON_FUELED_CONSUMPTION, TUNING.TURNON_FULL_FUELED_CONSUMPTION)
        inst.components.fueled:SetDepletedFn(generic_perish)

        inst:AddComponent("waterproofer")
        inst.components.waterproofer:SetEffectiveness(TUNING.WATERPROOFNESS_LARGE)

        inst.components.equippable.insulated = true

        return inst
    end

    --------

local BATVISION = resolvefilepath("images/colour_cubes/bat_vision_on_cc.tex")
local BATVISION_COLOURCUBES = {
	day = 		BATVISION,
	dusk = 		BATVISION,
	night = 	BATVISION,
	full_moon = BATVISION,
}

local function bat_onequip(inst, owner)
		_onequip(inst, owner)
		--if owner ~= ThePlayer then return end
		inst.active = owner
		owner.SoundEmitter:PlaySound("dontstarve_DLC003/common/crafted/batmask/on")

		if owner.components.playervision then
			owner.components.playervision:ForceNightVision(true)
			owner.components.playervision:SetCustomCCTable(BATVISION_COLOURCUBES)
			inst:DoTaskInTime(0, function()
				print("INFO", owner, owner.HUD)
				if owner.HUD and owner.HUD.batview then
					print("HUD")
					owner.HUD.batview:StartSonar()
				end
			end)
		end
	end

	local function bat_onunequip(inst, owner)
		inst.active = nil
		_onunequip(inst, owner)
		if owner ~= ThePlayer then return end
		owner.SoundEmitter:PlaySound("dontstarve_DLC003/common/crafted/batmask/off")
		if owner.components.playervision then
			owner.components.playervision:SetCustomCCTable(nil)
			if owner.HUD then
				owner.HUD.batview:StopSonar()
			end
		end
	end

	local function bat_perish(inst)
		inst.active = nil
		if inst.components.equippable and inst.components.equippable:IsEquipped() then
			local owner = inst.components.inventoryitem ~= nil and inst.components.inventoryitem.owner or nil
			owner.SoundEmitter:PlaySound("dontstarve_DLC003/common/crafted/batmask/off")
			owner.components.playervision:SetCustomCCTable(nil)
			if owner.HUD then
				owner.HUD.batview:StopSonar()
			end
		end
		generic_perish(inst)
	end
	
    local function bat()
        local inst = simple_common()
		--inst.AnimState:SetRayTestOnBB(true)
        inst:AddTag("no_sewing")	
		inst:AddTag("venting")
		inst:AddTag("bat_hat")
		inst:AddTag("clearfog")
		
		inst:AddTag("nightvision")

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        simple_master(inst)

        inst.components.equippable:SetOnEquip(bat_onequip)
		inst.components.equippable:SetOnUnequip(bat_onunequip)

        inst:AddComponent("fueled")
        inst.components.fueled.fueltype = "USAGE"
        inst.components.fueled:InitializeFuelLevel(TUNING.BATHAT_PERISHTIME)
        inst.components.fueled:SetFirstPeriod(TUNING.TURNON_FUELED_CONSUMPTION, TUNING.TURNON_FULL_FUELED_CONSUMPTION)
        inst.components.fueled:SetDepletedFn(bat_perish)
		inst.components.fueled.accepting = true

		inst.transition = false
		
        return inst
    end

    -------

	local function OnLightningStrike(inst, data)
		print("work")
        inst.components.fueled:DoDelta(-inst.components.fueled.maxfuel * TUNING.THUNDERHAT_USAGE_PER_LIGHTINING_STRIKE)
		inst:PushEvent("lightningdamageavoided")
    end

    local function thunder_onequip(inst, owner)
		_onequip(inst, owner)
		--owner:AddTag("lightningrod")
		owner:ListenForEvent("lightningstrike", OnLightningStrike)
		--inst.lightningpriority = 5
	end

	local function thunder_onunequip(inst, owner)
		_onunequip(inst, owner)
		--owner:RemoveTag("lightningrod")
		--owner:ListenForEvent("lightningstrike", OnLightningStrike)
	end

    local function thunder_onequiptomodel(inst, owner, from_ground)
        if inst.components.fueled ~= nil then
            inst.components.fueled:StopConsuming()
        end
    end
	
	

    local function thunder()
        local inst = simple_common()
		inst:AddTag("lightningrod")

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        simple_master(inst)
		
		inst.components.equippable.dapperness = TUNING.DAPPERNESS_SMALL

		inst:AddComponent("fueled")
        inst.components.fueled.fueltype = "USAGE"
        inst.components.fueled:InitializeFuelLevel(TUNING.THUNDERHAT_PERISHTIME)
        inst.components.fueled:SetFirstPeriod(TUNING.TURNON_FUELED_CONSUMPTION, TUNING.TURNON_FULL_FUELED_CONSUMPTION)
        inst.components.fueled:SetDepletedFn(generic_perish)

        inst.components.equippable:SetOnEquip(thunder_onequip)
        inst.components.equippable:SetOnUnequip(thunder_onunequip)
        inst.components.equippable:SetOnEquipToModel(thunder_onequiptomodel)

        return inst
    end

    --------
	
	local function disguise_onequip(inst, owner)
		opentop_onequip(inst, owner)
		
		if owner:HasTag("monster") then
			inst.monster = true
			owner:RemoveTag("monster")
		end
	end

	local function disguise_unequip(inst, owner)
		_onunequip(inst, owner)
        if owner then
			if inst.monster then			
				inst.monster = nil
				owner:AddTag("monster")
			end
		end
	end

	local function disguise()
		local inst = simple_common()
		
		inst:AddTag("disguise")

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        simple_master(inst)

		inst.components.equippable:SetOnEquip(disguise_onequip)
		inst.components.equippable:SetOnUnequip(disguise_unequip)
		inst.opentop = true

		return inst
	end
	
    --------
	
    local function default()
        local inst = simple_common()

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        simple_master(inst)

        return inst
    end

    local fn = nil
    local assets = {Asset("ANIM", "anim/" .. fname .. ".zip")}
    local prefabs = nil

    if name == "metalplate" then
        fn = metalplate
    elseif name == "candle" then
        fn = candle
    elseif name == "bandit" then
        fn = bandit
    elseif name == "pith" then
        fn = pith
    elseif name == "gasmask" then
        fn = gasmask
    elseif name == "pigcrown" then
        fn = pigcrown
    elseif name == "antmask" then
        fn = antmask
    elseif name == "peagawkfeather" then
        fn = peagawkfeather
    elseif name == "snakeskin" then
        fn = snakeskin
		--table.insert(assets, Asset("ANIM", "anim/hat_snakeskin_scaly.zip"))
    elseif name == "bat" then
		table.insert(assets, Asset("IMAGE", "images/colour_cubes/bat_vision_on_cc.tex"))
        fn = bat
    elseif name == "thunder" then
        fn = thunder
    elseif name == "disguise" then
        fn = disguise
    end

    return Prefab(prefabname, fn or default, assets, prefabs)
end

return MakeHat("metalplate"),
MakeHat("candle"),
MakeHat("bandit"),
MakeHat("pith"),
MakeHat("gasmask"),
MakeHat("pigcrown"),
MakeHat("antmask"),
MakeHat("peagawkfeather"),
MakeHat("snakeskin"),
MakeHat("bat"),
MakeHat("thunder"),
MakeHat("disguise")
