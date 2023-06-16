local AddPlayerPostInit = AddPlayerPostInit
GLOBAL.setfenv(1, GLOBAL)

local function IsPoisonDisabled()
	return TheWorld and TheWorld.components.globalsettings and 
		TheWorld.components.globalsettings.settings.poisondisabled and 
			TheWorld.components.globalsettings.settings.poisondisabled == true
end

local function BeginGas(inst)
	local safe = false
	-- check armour
	if inst.components.inventory then
		for k,v in pairs (inst.components.inventory.equipslots) do
			if v.components.equippable and v.components.equippable:IsPoisonGasBlocker() then
				safe = true
			end		
		end
	end

	if inst:HasTag("has_gasmask") or IsPoisonDisabled() then
		safe = true
	end
	
	if not safe then
		inst.components.health:DoGasDamage(TUNING.GAS_DAMAGE_PER_INTERVAL)			
		inst:PushEvent("poisondamage")	
		inst.components.talker:Say(GetString(inst.prefab, "ANNOUNCE_GAS_DAMAGE"))
	end
end

local function EndGas(inst)
	if inst.gasTask then
		inst.gasTask:Cancel()
		inst.gasTask = nil
	end
end

local function OnChangeArea(inst, area)
	-- DST lunacy
	local enable_lunacy = area ~= nil and area.tags and table.contains(area.tags, "lunacyarea")
	inst.components.sanity:EnableLunacy(enable_lunacy, "lunacyarea")
	
	-- PL Gas
	if not inst.gassources then
		inst.gassources = 0
	end
	if area and area.tags and table.contains(area.tags, "Gas_Jungle") then
		inst.gassources = inst.gassources +1	
		if inst.gassources > 0 and not inst.gasTask then
			inst.gasTask = inst:DoPeriodicTask(TUNING.GAS_INTERVAL, BeginGas)
		end
	else
		inst.gassources = math.max(0,inst.gassources - 1)
		if inst.gassources < 1 then
			EndGas(inst)
		end
	end
end

local function OnDeath(self, data)
	if self.components.poisonable then
		self.components.poisonable:SetBlockAll(true)
	end
end

local function OnRespawnFromGhost(self, data)
	if self.components.poisonable and not inst:HasTag("beaver") then
		self.components.poisonable:SetBlockAll(false)
	end
end

AddPlayerPostInit(function(inst)
    if not TheWorld.ismastersim then
        return
    end
	
	inst:AddComponent("infestable")
	--inst:AddComponent("canopytracker") -- lot of problem
	
	inst:ListenForEvent("changearea", OnChangeArea)
    inst:ListenForEvent("death", OnDeath)
    inst:ListenForEvent("respawnfromghost", OnRespawnFromGhost)

end)
