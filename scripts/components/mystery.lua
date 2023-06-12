local Mystery = Class(function(self, inst)
    self.inst = inst

    inst:DoTaskInTime(0, function()
	    	if not self.rolled then 
	    		self:RollForMystery()         		
	    	end
    	end)
end)

function Mystery:GenerateReward()
	local mid_tier = {"flint", "goldnugget", "oinc", "oinc10"}
	for i=1,NUM_TRINKETS do
		table.insert(mid_tier, "trinket_" .. tostring(i))
	end

	local high_tier = {}
	for i=1,3 do
		table.insert(high_tier, "relic_" .. tostring(i))
	end

	if math.random() < 0.4 then
		return nil
	elseif math.random() < 0.7 then
		return mid_tier[math.random(#mid_tier)]
	else
		return high_tier[math.random(#high_tier)]
	end
end

function Mystery:AddReward(reward)
	local color = 0.5 + math.random() * 0.5
    self.inst.AnimState:SetMultColour(color-0.15, color-0.15, color, 1)

	self.inst:AddTag("mystery")
	self.reward = reward or self:GenerateReward()

	self.inst:ListenForEvent("onremove", function()
		if self.inst:HasTag("mystery") and self.inst.components.mystery.investigated then
			self.inst.components.lootdropper:SpawnLootPrefab(self.reward)
		end
	end)
end

function Mystery:RollForMystery()
	self.rolled = true
	if math.random() <= 0.05 then
		self.inst:AddComponent("hiddendanger")       
    	self.inst.components.hiddendanger.effect = "peculiar_marker_fx"		
		self:AddReward()
	end
end

function Mystery:OnLoad(data)

	if data.reward then 
		self.reward = data.reward
	end
	if data.investigated then
		self.investigated = data.investigated
	end

	if data.reward then
		if not self.inst.components.hiddendanger then
			self.inst:AddComponent("hiddendanger")       
		end
    	self.inst.components.hiddendanger.effect = "peculiar_marker_fx"			
		self:AddReward(data.reward)
	end
	if data.investigated then
		if self.inst.components.hiddendanger then
			self.inst:DoTaskInTime(0,function()
					self.inst.components.hiddendanger:ChangeFx("identified_marker_fx")
				end)
		end
	end
	if data.rolled then
		self.rolled = data.rolled
	end
end

function Mystery:OnSave()
	local data = {}

	if self.reward then
		data.reward = self.reward
	end

	if self.investigated then
		data.investigated = self.investigated
	end
	data.rolled = self.rolled
	return data
end

function Mystery:IsActionValid(action, right)
    return self.inst:HasTag("mystery") and action == ACTIONS.SPY
end

function Mystery:Investigate(doer)	
	if self.reward then
		GetPlayer().components.talker:Say(GetString(GetPlayer().prefab, "ANNOUNCE_MYSTERY_FOUND"))
		self.investigated = true
		if self.inst.components.hiddendanger then
			self.inst.components.hiddendanger:ChangeFx("identified_marker_fx")
		end
	else
		GetPlayer().components.talker:Say(GetString(GetPlayer().prefab, "ANNOUNCE_MYSTERY_NOREWARD"))
		self.inst:RemoveTag("mystery")
		if self.inst.components.hiddendanger then
			self.inst.components.hiddendanger:Clear()
		end
	end
end

return Mystery