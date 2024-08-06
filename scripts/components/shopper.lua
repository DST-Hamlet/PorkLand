	--Sits on the player prefab, not a pig. 

local Shopper = Class(function(self, inst)
    self.inst = inst
end)

local function FindItem(inventory, list)	
	local item = inventory:FindItem(function(look) 
		for k,v in ipairs(list) do 			
			if look.prefab == v then 				
				return look
			end 
		end 
	end)	
	return item					
end 

function Shopper:PayMoney(inventory,cost)
	local hasoincs,oincamount = inventory:Has("oinc", 0, true)
	local hasoinc10s,oinc10amount = inventory:Has("oinc10", 0, true)
	local hasoinc100s,oinc100amount = inventory:Has("oinc100", 0, true)
	local debt = cost

	local oincused = 0
	local oinc10used = 0
	local oinc100used = 0
	local oincgained = 0
	local oinc10gained = 0	


	if self.inst.components.builder and self.inst.components.builder.freebuildmode then
		return
	else
		while debt > 0 do
			while debt > 0 and oincamount > 0 do
				oincamount = oincamount - 1
				debt = debt - 1
				oincused = oincused +1
			end		
			if debt > 0 then
				if oinc10amount >0 then
					oinc10amount = oinc10amount -1
					oinc10used = oinc10used +1
					for i=1,10 do
						oincamount = oincamount + 1
						oincgained = oincgained + 1
					end
				elseif oinc100amount > 0 then
					oinc100amount = oinc100amount -1
					oinc100used = oinc100used +1
					for i=1,10 do
						oinc10amount = oinc10amount + 1
						oinc10gained = oinc10gained + 1
					end
				end
			end
		end

		local oincresult = oincgained - oincused
		if oincresult > 0 then
			for i=1,oincresult do
				local coin = SpawnPrefab("oinc")
				inventory:GiveItem( coin )	
			end
		end
		if oincresult < 0 then
			for i=1,math.abs(oincresult)do
				inventory:ConsumeByName("oinc", 1, true )
			end
		end

		local oinc10result = oinc10gained - oinc10used
		if oinc10result > 0 then
			for i=1,oinc10result do
				local coin = SpawnPrefab("oinc10")
				inventory:GiveItem( coin )	
			end
		end
		if oinc10result < 0 then
			for i=1,math.abs(oinc10result)do
				inventory:ConsumeByName("oinc10", 1, true )
			end
		end

		local oinc100result = 0 -oinc100used 
		if oinc100result < 0 then
			for i=1,math.abs(oinc100result)do
				inventory:ConsumeByName("oinc100", 1, true )
			end
		end
	end
end

function Shopper:GetMoney(inventory)
	local money = 0

	local hasoincs,oincamount = inventory:Has("oinc", 0, true)
	local hasoinc10s,oinc10amount = inventory:Has("oinc10", 0, true)
	local hasoinc100s,oinc100amount = inventory:Has("oinc100", 0, true)
		
	money = oincamount + (oinc10amount *10)+ (oinc100amount *100)
	return money
end

function Shopper:IsWatching(prefab)
	if prefab:HasTag("cost_one_oinc") or prefab.components.shopped then
		local x,y,z = prefab.Transform:GetWorldPosition()
	  	local ents = TheSim:FindEntities(x,y,z, 50, {"shopkeep"},{"INLIMBO"})
	  	if #ents > 0 then  		
	  		for i,ent in ipairs(ents)do
	  			if not ent.components.sleeper or not ent.components.sleeper:IsAsleep() then
	  				return true
	  			end
	  		end
		end	
	end
	return false

end 

function Shopper:CanPayFor(prefab)	
	local player = self.inst 
	local inventory = player.components.inventory

	if self:IsWatching(prefab) == false then
		print("NOT WATCHED")
		return true 
	end 

	if prefab.components.shopped then
		local shop =  nil
		if prefab.components.shopped.shop ~= nil then 
			shop = prefab.components.shopped.shop
		else 
			return false 
		end

		if prefab.components.shopdispenser == nil or prefab.components.shopdispenser:GetItem() == nil then 
			return false 
		end 
		
		local prefab_wanted = prefab.costprefab
		print("TESTING prefab_wanted",prefab_wanted)
		
		if prefab_wanted == "oinc" then
 			if self:GetMoney(inventory) >= prefab.cost then
 				return true
 			end
		else			
			if inventory ~= nil and prefab_wanted ~= nil then 
				local item = inventory:FindItem(function(look) return look.prefab == prefab_wanted end)
				if item ~= nil then
					return true
				end 
			end 			
		end
	else
		if prefab:HasTag("cost_one_oinc") then
 			if self:GetMoney(inventory) >= 1 then
 				return true
 			end
		end
	end
	return false, "REPAIRBOAT"
end

function Shopper:PayFor(prefab)
	local player = self.inst 
	local inventory = player.components.inventory

	if prefab:HasTag("cost_one_oinc") then
		self:PayMoney(inventory,1)
	else
		local prefab_wanted = prefab.costprefab
		local shop = prefab.components.shopped.shop.components.shopinterior
		if prefab.components.shopdispenser == nil or prefab.components.shopdispenser:GetItem() == nil then 
			return false 
		end 

		if inventory ~= nil and prefab_wanted ~= nil then 

			if prefab_wanted == "oinc" then 
				self:PayMoney(inventory,prefab.cost)
				shop:BoughtItem(prefab, player)			
			else
				local item = inventory:FindItem(function(look) return look.prefab == prefab_wanted end)
				if item ~= nil then
					inventory:RemoveItem(item)
					shop:BoughtItem(prefab, player)
				end 
			end		
		end 
	end
end 

function Shopper:Take(prefab)
	local player = self.inst 
	local inventory = player.components.inventory
	--local prefab_wanted = prefab.costprefab
	local shop = prefab.components.shopped.shop.components.shopinterior

	if prefab.components.shopdispenser == nil or prefab.components.shopdispenser:GetItem() == nil then 
		return false 
	end 

	if inventory ~= nil then
		prefab:AddTag("robbed")
		player.components.kramped:OnNaughtyAction(6) 
		shop:BoughtItem(prefab, player)
	end 
end 

return Shopper