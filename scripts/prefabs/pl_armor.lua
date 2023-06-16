local function onequip(inst, owner)
	owner.AnimState:OverrideSymbol("swap_body", inst.overridesymbol, "swap_body")
	if inst.OnBlocked then
		inst:ListenForEvent("blocked", inst.OnBlocked, owner)
	end
	if inst.components.fueled then
		inst.components.fueled:StartConsuming()
	end
end

local function onunequip(inst, owner)
	owner.AnimState:ClearOverrideSymbol("swap_body")
	if inst.OnBlocked then
		inst:RemoveEventCallback("blocked", inst.OnBlocked, owner)
	end
	if inst.components.fueled then
		inst.components.fueled:StopConsuming()
	end
end

local function onequiptomodel(inst, owner, from_ground)
	if inst.components.fueled ~= nil then
		inst.components.fueled:StopConsuming()
	end
end

local function commonfn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddNetwork()
	inst.entity:AddSoundEmitter()

	MakeInventoryPhysics(inst)

	MakeInventoryFloatable(inst)
	--inst.components.floater:UpdateAnimations("idle_water", "anim")

	return inst
end

local function masterfn(inst, image)
	inst:AddComponent("inspectable")

	MakeHauntableLaunch(inst)

	inst:AddComponent("inventoryitem")
	if image then inst.components.inventoryitem.imagename = image
	end

	inst:AddComponent("equippable")
	inst.components.equippable.equipslot = EQUIPSLOTS.BODY

	inst.components.equippable:SetOnEquip(onequip)
	inst.components.equippable:SetOnUnequip(onunequip)
	inst.components.equippable:SetOnEquipToModel(onequiptomodel)
end

-------------------------------------------------------------

local metalplate_assets = {
	Asset("ANIM", "anim/armor_metalplate.zip"),
}

local function metalplate_OnBlocked(owner)
  owner.SoundEmitter:PlaySound("dontstarve/wilson/hit_armour") 
end

local function metalplate_fn()
	local inst = commonfn()

	inst.AnimState:SetBank("armor_metalplate")
    inst.AnimState:SetBuild("armor_metalplate")
	inst.AnimState:PlayAnimation("anim")

	inst.foleysound = "dontstarve_DLC003/movement/iron_armor/foley_player"

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	masterfn(inst)

	inst.overridesymbol = "armor_metalplate"

	inst.OnBlocked = metalplate_OnBlocked

	inst:AddComponent("armor")
	inst.components.armor:InitCondition(TUNING.ARMORMETAL, TUNING.ARMORMETAL_ABSORPTION)

    inst.components.equippable.walkspeedmult = TUNING.ARMORMETAL_SLOW
	return inst
end

-------------------------------------------------------------

local weevole_assets = {
	Asset("ANIM", "anim/armor_weevole.zip"),
}

local function weevole_OnBlocked(owner)
	owner.SoundEmitter:PlaySound("dontstarve/wilson/hit_armour")
end

local function weevole_fn()
	local inst = commonfn()

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

	masterfn(inst)

	inst.overridesymbol = "armor_weevole"

	inst.OnBlocked = weevole_OnBlocked

	inst:AddComponent("armor")
    inst.components.armor:InitCondition(TUNING.ARMOR_WEEVOLE_DURABILITY, TUNING.ARMOR_WEEVOLE_ABSORPTION)

    inst:AddComponent("waterproofer")
    inst.components.waterproofer:SetEffectiveness(TUNING.WATERPROOFNESS_MED)

	return inst
end

-------------------------------------------------------------

local vortexcloak_assets = {
	Asset("ANIM", "anim/armor_vortex_cloak.zip"),
    Asset("ANIM", "anim/cloak_fx.zip"),
	Asset("ANIM", "anim/vortex_cloak_fx.zip"),
    Asset("MINIMAP_IMAGE", "armor_vortex_cloak"),
}

local function setsoundparam(inst)
    local param = Remap(inst.components.armor.condition, 0, inst.components.armor.maxcondition,0, 1 )
    inst.SoundEmitter:SetParameter( "vortex", "intensity", param )
end

local function spawnwisp(owner)
    local wisp = SpawnPrefab("armorvortexcloak_fx")
    local x,y,z = owner.Transform:GetWorldPosition()
    wisp.Transform:SetPosition(x+math.random()*0.25 -0.25/2,y,z+math.random()*0.25 -0.25/2)    
end

local function vortexcloak_OnBlocked(owner, data, inst)
	if inst.components.armor.condition and inst.components.armor.condition > 0 then
		owner:AddChild(SpawnPrefab("vortex_cloak_fx"))
		print("deff")
	end
	setsoundparam(inst)
end

local function vortexcloak_onequip(inst, owner)
	owner.AnimState:OverrideSymbol("swap_body", "armor_vortex_cloak", "swap_body")
    owner.SoundEmitter:PlaySound("dontstarve_DLC003/common/crafted/vortex_armour/equip_off")

    inst:ListenForEvent("blocked",  inst._onblocked, owner)
    inst:ListenForEvent("attacked", inst._onblocked, owner)

    if inst.components.armor.condition > 0 then
        owner:AddTag("not_hit_stunned")
    end

    --owner.components.inventory:SetOverflow(inst)
	if inst.components.container ~= nil then
		inst.components.container:Open(owner)
	end

    inst.wisptask = inst:DoPeriodicTask(0.1,function() spawnwisp(owner) end)

    inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/crafted/vortex_armour/LP","vortex")

    setsoundparam(inst)
end

local function vortexcloak_onunequip(inst, owner)
    owner.AnimState:ClearOverrideSymbol("swap_body")
    owner.SoundEmitter:PlaySound("dontstarve_DLC003/common/crafted/vortex_armour/equip_on")

	inst:RemoveEventCallback("blocked", inst._onblocked, owner)
    inst:RemoveEventCallback("attacked", inst._onblocked, owner) 

    owner:RemoveTag("not_hit_stunned")

    --owner.components.inventory:SetOverflow(nil)
	if inst.components.container ~= nil then
		inst.components.container:Close(owner)
	end

    if inst.wisptask then
        inst.wisptask:Cancel()
        inst.wisptask= nil
    end

    inst.SoundEmitter:KillSound("vortex")
end

local function CLIENT_PlayFuelSound(inst)
	local parent = inst.entity:GetParent()
	local container = parent ~= nil and (parent.replica.inventory or parent.replica.container) or nil
	if container ~= nil and container:IsOpenedBy(ThePlayer) then
		TheFocalPoint.SoundEmitter:PlaySound("dontstarve_DLC003/common/crafted/vortex_armour/add_fuel")
	end
end

local function SERVER_PlayFuelSound(inst, owner)
	if owner == nil then
		inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/crafted/vortex_armour/add_fuel")
	elseif inst.components.equippable:IsEquipped() and owner.SoundEmitter ~= nil then
		owner.SoundEmitter:PlaySound("dontstarve_DLC003/common/crafted/vortex_armour/add_fuel")
	else
		inst.playfuelsound:push()
		--Dedicated server does not need to trigger sfx
		if not TheNet:IsDedicated() then
			CLIENT_PlayFuelSound(inst)
		end
	end
end

local function ontakefuel(inst, fuelvalue)
	print(fuelvalue)
    if inst.components.armor.condition and inst.components.armor.condition < 0 then
        inst.components.armor:SetCondition(0)
    end

    local owner = inst.components.inventoryitem.owner

    if not owner:HasTag("not_hit_stunned") then
        owner:AddTag("not_hit_stunned")
    end

    local new_condition = math.min(inst.components.armor.condition + (TUNING.ARMORVORTEX * TUNING.ARMORVORTEX_REFUEL_PERCENT), TUNING.ARMORVORTEX)
        --fuel:HasTag("ancient_remnant") and TUNING.ARMORVORTEX
       -- or math.min(inst.components.armor.condition + (TUNING.ARMORVORTEX * TUNING.ARMORVORTEX_REFUEL_PERCENT), TUNING.ARMORVORTEX)

    inst.components.armor:SetCondition(new_condition)
    
    SERVER_PlayFuelSound(inst, owner)
end

local function onempty(inst)
    ThePlayer:RemoveTag("not_hit_stunned")
end

local function vortexcloak_fn()
	local inst = commonfn()

	inst.AnimState:SetBank("armor_vortex_cloak")
    inst.AnimState:SetBuild("armor_vortex_cloak")
	inst.AnimState:PlayAnimation("anim")

	local minimap = inst.entity:AddMiniMapEntity()
    minimap:SetIcon("armor_vortex_cloak.tex")

    inst:AddTag("vortex_cloak")
	inst:AddTag("backpack")

    inst.foleysound = "dontstarve_DLC003/common/crafted/vortex_armour/foley"

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		inst.OnEntityReplicated = function(inst) 
			inst.replica.container:WidgetSetup("vortexcloak") 
		end
		return inst
	end

	masterfn(inst)

	inst.overridesymbol = "armor_vortex_cloak"
	inst.components.inventoryitem.cangoincontainer = false
	
	inst:AddComponent("armor")
    inst.components.armor:InitCondition(TUNING.ARMORVORTEX, TUNING.ARMORVORTEX_ABSORPTION)
    --inst.components.armor:SetImmuneTags({"shadow"})
    --inst.components.armor.bonussanitydamage = TUNING.ARMORVORTEX_DMG_AS_SANITY -- Sanity drain when hit (damage percentage)
    inst.components.armor.onfinished = onempty

    inst.components.equippable:SetOnEquip(vortexcloak_onequip)
    inst.components.equippable:SetOnUnequip(vortexcloak_onunequip)
	
	inst:AddComponent("container")
    inst.components.container:WidgetSetup("vortexcloak")
    --inst.components.container.skipclosesnd = true
    --inst.components.container.skipopensnd = true

    inst:AddComponent("fueled")
    inst.components.fueled:InitializeFuelLevel(4 * TUNING.LARGE_FUEL)
    inst.components.fueled.fueltype = "NIGHTMARE"
    inst.components.fueled.secondaryfueltype = "ANCIENT_REMNANT"
    inst.components.fueled:SetTakeFuelFn(ontakefuel)
    inst.components.fueled.accepting = true
	
	inst._onblocked = function(owner, data) vortexcloak_OnBlocked(owner, data, inst) end
	inst.components.equippable.poisonblocker = true

	return inst
end
local function vortexcloak_fxfn()
    local inst = CreateEntity()
    
    inst.entity:AddTransform()
    inst.entity:AddSoundEmitter()
    inst.entity:AddAnimState()
	inst.entity:AddNetwork()

    inst.AnimState:SetBank("cloakfx")
    inst.AnimState:SetBuild("cloak_fx")
    inst.AnimState:PlayAnimation("idle",true)

    inst:AddTag("FX")
    inst:AddTag("NOBLOCK")
    inst:AddTag("NOCLICK")

	if not TheWorld.ismastersim then
        return inst
    end

    for i=1,14 do
        inst.AnimState:Hide("fx"..i)
    end

    inst.AnimState:Show("fx"..math.random(1,14))

    inst.persists = false
    inst:ListenForEvent("animover", inst.Remove)
    inst:ListenForEvent("entitysleep", inst.Remove)

    return inst
end

local function vortexcloak_fx2fn()
    local inst = CreateEntity()
    
    inst.entity:AddTransform()
    inst.entity:AddSoundEmitter()
    inst.entity:AddAnimState()
	inst.entity:AddNetwork()

    inst.AnimState:SetBank("vortex_cloak_fx")
    inst.AnimState:SetBuild("vortex_cloak_fx")
    inst.AnimState:PlayAnimation("idle",true)    

    inst:AddTag("FX")
	
	if not TheWorld.ismastersim then
        return inst
    end

	inst:ListenForEvent("animover", inst.Remove) 
	
    return inst
end

-------------------------------------------------------------

local snakeskin_assets = {
	Asset("ANIM", "anim/armor_snakeskin_scaly.zip"),
}

local function snakeskin_fn()
	local inst = commonfn()

    inst.AnimState:SetBank("armor_snakeskin_scaly")
    inst.AnimState:SetBuild("armor_snakeskin_scaly")
    inst.AnimState:PlayAnimation("anim")

	--waterproofer (from waterproofer component) added to pristine state for optimization
	inst:AddTag("waterproofer")

    --inst.foleysound = "ia/common/foley/snakeskin_jacket"
    inst.foleysound =  "dontstarve_DLC002/common/foley/snakeskin_jacket"

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	masterfn(inst, "armor_snakeskin_scaly")

	inst.overridesymbol = "armor_snakeskin_scaly"

    inst:AddComponent("fueled")
    inst.components.fueled.fueltype = "USAGE"
    inst.components.fueled:InitializeFuelLevel(TUNING.ARMOR_SNAKESKIN_PERISHTIME)
    inst.components.fueled:SetFirstPeriod(TUNING.TURNON_FUELED_CONSUMPTION, TUNING.TURNON_FULL_FUELED_CONSUMPTION)
    inst.components.fueled:SetDepletedFn(inst.Remove)

    inst:AddComponent("waterproofer")
    inst.components.waterproofer.effectiveness = TUNING.WATERPROOFNESS_HUGE
    inst.components.equippable.insulated = true

	inst:AddComponent("insulator")
    inst.components.insulator:SetInsulation(TUNING.INSULATION_SMALL)

	return inst
end

-------------------------------------------------------------

local antsuit_assets = {
	Asset("ANIM", "anim/antsuit.zip"),
}

local function antsuit_onequip(inst, owner) 
    owner.AnimState:OverrideSymbol("swap_body", "antsuit", "swap_body")
    inst.components.fueled:StartConsuming()
    owner:AddTag("has_antsuit")
end

local function antsuit_onunequip(inst, owner) 
    owner.AnimState:ClearOverrideSymbol("swap_body")
    inst.components.fueled:StopConsuming()
    owner:RemoveTag("has_antsuit")
end

local function onupdate(inst)
    inst.components.armor:SetPercent(inst.components.fueled:GetPercent())
end

local function ontakedamage(inst, damage_amount)
    inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/crafted/antsuit/hit")
	local absorbed = damage_amount*TUNING.ARMORWOOD_ABSORPTION
	local absorbedDamageInPercent = absorbed/inst.components.armor.maxcondition
	if inst.components.fueled then
		local percent = inst.components.fueled:GetPercent()
		local newPercent = percent - absorbedDamageInPercent
		inst.components.fueled:SetPercent(newPercent)
	end
end

local function antsuit_fn()
	local inst = commonfn()

    inst.AnimState:SetBank("antsuit")
    inst.AnimState:SetBuild("antsuit")
    inst.AnimState:PlayAnimation("anim")

    inst.foleysound =  "dontstarve_DLC003/common/crafted/antsuit/foley"

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	masterfn(inst)

	inst.overridesymbol = "antsuit"

    inst:AddComponent("armor")
    inst.components.armor:InitCondition(TUNING.ARMORWOOD, TUNING.ARMORWOOD_ABSORPTION)
	inst.components.armor.ontakedamage = ontakedamage

    inst:AddComponent("fueled")
    inst.components.fueled.fueltype = "USAGE"
    inst.components.fueled:InitializeFuelLevel(TUNING.ANTSUIT_PERISHTIME)
    inst.components.fueled:SetFirstPeriod(TUNING.TURNON_FUELED_CONSUMPTION, TUNING.TURNON_FULL_FUELED_CONSUMPTION)
    inst.components.fueled:SetDepletedFn(inst.Remove)
    inst.components.fueled:SetUpdateFn(onupdate)
	
	inst.components.equippable:SetOnEquip(antsuit_onequip)
	inst.components.equippable:SetOnUnequip(antsuit_onunequip)

	return inst
end

return Prefab("armor_metalplate", metalplate_fn, metalplate_assets),
Prefab("armor_weevole", weevole_fn, weevole_assets),
Prefab("armorvortexcloak", vortexcloak_fn, vortexcloak_assets),
Prefab("armorvortexcloak_fx", vortexcloak_fxfn, vortexcloak_assets),
Prefab("vortex_cloak_fx", vortexcloak_fx2fn, vortexcloak_assets),
Prefab("armor_snakeskin", snakeskin_fn, snakeskin_assets),
Prefab("antsuit", antsuit_fn, antsuit_assets)