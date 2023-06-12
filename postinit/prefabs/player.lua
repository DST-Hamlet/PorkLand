local AddPlayerPostInit = AddPlayerPostInit
GLOBAL.setfenv(1, GLOBAL)

local function IsPoisonDisabled()
	local world = TheWorld
	return world and world.components.globalsettings and 
		world.components.globalsettings.settings.poisondisabled and 
			world.components.globalsettings.settings.poisondisabled == true
end

local function BeginGas(inst)
	if inst.gasTask == nil then
		inst.gasTask = inst:DoPeriodicTask(TUNING.GAS_INTERVAL,
			function()				
				local player = ThePlayer

				local safe = false
				-- check armour
				if player.components.inventory then
					for k,v in pairs (player.components.inventory.equipslots) do
						if v.components.equippable and v.components.equippable:IsPoisonGasBlocker() then
							safe = true
						end		
					end
				end

				if player:HasTag("has_gasmask") then
					safe = true
				end

				if IsPoisonDisabled() then
					safe = true
				end
				
				if not safe then
					player.components.health:DoGasDamage(TUNING.GAS_DAMAGE_PER_INTERVAL)			
					player:PushEvent("poisondamage")	
					player.components.talker:Say(GetString(player.prefab, "ANNOUNCE_GAS_DAMAGE"))
				end
			end)
	end
end

local function EndGas(inst)
	if inst.gasTask then
		inst.gasTask:Cancel()
		inst.gasTask = nil
	end
end

local function OnGasChange(inst, data)
	if not inst.gassources then
		inst.gassources = 0
	end
	if data and data.tags and table.contains(data.tags, "Gas_Jungle") then
		inst.gassources = inst.gassources +1	
		if inst.gassources > 0 and not inst.gasTask then
			BeginGas(inst)
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
	inst:AddComponent("canopytracker")
	
	inst:ListenForEvent("changearea", OnGasChange)
    inst:ListenForEvent("death", OnDeath)
    inst:ListenForEvent("respawnfromghost", OnRespawnFromGhost)

end)
