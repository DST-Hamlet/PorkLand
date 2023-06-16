local PeriodicPoopManager = Class(function(self, inst)
    self.inst = inst
	self.poop_count_per_city = {}
	self.max_poop_per_city = { 5, 10 }
	self.poop_data = {}
end)


function PeriodicPoopManager:OnSave()
	local data = 
	{
		poop_data = self.poop_data
	}

	return data
end

function PeriodicPoopManager:LoadPostPass(ents, data)
	for k,v in pairs(data.poop_data) do
		if ents[k] and ents[k].entity and v then
			ents[k].entity.cityID = v
		end
	end

end

function PeriodicPoopManager:OnPoop(city_id, poop)
	if self.poop_count_per_city[city_id] then
		self.poop_count_per_city[city_id] = self.poop_count_per_city[city_id] + 1
	else
		self.poop_count_per_city[city_id] = 1
	end

	self.poop_data[poop.GUID] = city_id
end

function PeriodicPoopManager:OnPickedUp(city_id, poop)
	self.poop_count_per_city[city_id] = self.poop_count_per_city[city_id] or 0

	self.poop_count_per_city[city_id] = self.poop_count_per_city[city_id] - 1
	self.poop_data[poop.GUID] = nil

	local x,y,z = GetPlayer().Transform:GetWorldPosition()
	local radius = 20
	local ents = TheSim:FindEntities(x,y,z, radius, {"city_pig"}, {"guard"})

	local closest_pig = nil
	for _, pig in pairs(ents) do
		if pig.components.citypossession and pig.components.citypossession.cityID == city_id then
			closest_pig = pig
			break
		end
	end

	if closest_pig then
		closest_pig.poop_tip = true
	end

end

function PeriodicPoopManager:AllowPoop(city_id)
	if not self.poop_count_per_city[city_id] then
		self.poop_count_per_city[city_id] = 0
	end

	--local result = self.poop_count_per_city[city_id] < 7
	return self.poop_count_per_city[city_id] < self.max_poop_per_city[city_id]
end

return PeriodicPoopManager