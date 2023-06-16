local TRADER = {
	pigman_collector = {	items= {"stinger","silk","mosquitosack","chitin","venus_stalk","venomgland","spidergland","lotus_flower"},					
							delay=0, reset=0, current=0, desc=STRINGS.CITY_PIG_COLLECTOR_TRADE,  reward = "oinc",   rewardqty=3},
	pigman_banker = {		items= {"redgem","bluegem","greengem", "orangegem", "yellowgem"},
							delay=0, reset=0, current=0, desc=STRINGS.CITY_PIG_BANKER_TRADE, 	 reward = "oinc10", rewardqty=1},
	pigman_beautician = {	items= {"feather_crow","feather_robin","feather_robin_winter","peagawkfeather", "feather_thunder", "doydoyfeather"},					
							delay=0, reset=1, current=0, desc=STRINGS.CITY_PIG_BEAUTICIAN_TRADE, reward = "oinc",   rewardqty=2},
	pigman_mechanic = {		items= {"boards","rope","cutstone","papyrus"},
							delay=0, reset=1, current=0, desc=STRINGS.CITY_PIG_MECHANIC_TRADE, 	 reward = "oinc",   rewardqty=2},
	pigman_professor = {	items= {"relic_1", "relic_2", "relic_3"}, 
							delay=0, reset=0, current=0, desc=STRINGS.CITY_PIG_PROFESSOR_TRADE,  reward = "oinc10", rewardqty=1},								
	pigman_hunter = 		{items= {"houndstooth","stinger"},	   	delay=0, reset=1, current=0, desc=STRINGS.CITY_PIG_HUNTER_TRADE, 		reward = "oinc",   rewardqty=5},
	pigman_mayor = 			{items= {"goldnugget"},	   			delay=0, reset=0, current=0, desc=STRINGS.CITY_PIG_MAYOR_TRADE, 	    reward = "oinc",   rewardqty=5},
	pigman_florist = 		{items= {"petals"},   		   			delay=0, reset=1, current=0, desc=STRINGS.CITY_PIG_FLORIST_TRADE,    	reward = "oinc",   rewardqty=1},
	pigman_storeowner = 	{items= {"clippings"},		   			delay=0, reset=0, current=0, desc=STRINGS.CITY_PIG_STOREOWNER_TRADE, 	reward = "oinc",   rewardqty=1},
	pigman_farmer = 		{items= {"cutgrass","twigs"}, 			delay=0, reset=1, current=0, desc=STRINGS.CITY_PIG_FARMER_TRADE, 		reward = "oinc",   rewardqty=1},
	pigman_miner = 			{items= {"rocks"},			   			delay=0, reset=1, current=0, desc=STRINGS.CITY_PIG_MINER_TRADE, 	    reward = "oinc",   rewardqty=1},
	pigman_erudite = 		{items= {"nightmarefuel"},	   			delay=0, reset=1, current=0, desc=STRINGS.CITY_PIG_ERUDITE_TRADE,    	reward = "oinc",   rewardqty=5},
	pigman_hatmaker =		{items= {"silk"},			   			delay=0, reset=1, current=0, desc=STRINGS.CITY_PIG_HATMAKER_TRADE,		reward = "oinc",   rewardqty=5},
	pigman_queen = 			{items= {"pigcrownhat","pig_scepter","relic_4","relic_5"},
	         				delay=0, reset=0, current=0, desc=STRINGS.CITY_PIG_QUEEN_TRADE,		reward = "pedestal_key",   rewardqty=1},
	pigman_usher =		    {items= {"honey","jammypreserves","icecream","pumpkincookie","waffles","berries","berries_cooked"},                 
							delay=0, reset=1, current=0, desc=STRINGS.CITY_PIG_USHER_TRADE,  reward = "oinc",   rewardqty=4},

--	pigman_royalguard = 	{items={"spear","spear_wathgrithr"},
--															num=3, current=0,	desc=STRINGS.CITY_PIG_GUARD_TRADE, 		reward = "oinc"},
--	pigman_royalguard_2 = 	{items={"spear","spear_wathgrithr"},				
--															num=3, current=0,	desc=STRINGS.CITY_PIG_GUARD_TRADE, 		reward = "oinc"},	
--	pigman_shopkeep = 		{items={},						num=5, current=0,	desc=STRINGS.CITY_PIG_SHOPKEEP_TRADE, 	reward = "oinc"},
}

local Economy = Class(function(self, inst)
    self.inst = inst
	self.cities = {} 

    self.inst:WatchWorldState("isday",  function() self:processdelays() end)

    for i=1,NUM_TRINKETS do
		table.insert(TRADER.pigman_collector.items, "trinket_" .. i)
	end

	self.inst:DoTaskInTime(0.1, function()
		-- Fixup for beta glitch when a world was saved without a city on it.
		if not self.cities or #self.cities < 1 then
			self:AddCity(1)  
		end
	end)
end)

function Economy:OnSave()	
	local refs = {}
	local data = {}
	data.cities = self.cities

	for city,data in pairs(self.cities) do
		for item,itemdata in pairs(data) do
			for guid,guiddata in pairs(itemdata.GUIDS) do
				table.insert(refs,guid)
			end
		end
	end

	return data, refs
end 

function Economy:OnLoad(data)
	if data and data.cities then
		self.cities = data.cities
	end
end

function Economy:LoadPostPass(ents, data)
	for city, data in pairs(self.cities)do
		for item, itemdata in pairs(data) do
			local newguids = {}
			for guid, guiddata in pairs(itemdata.GUIDS) do
			 	local child = ents[guid]
			    if child then
			    	newguids[child.entity.GUID] = guiddata
			    end
			end
			itemdata.GUIDS = newguids
		end
	end
end

function Economy:processdelays()
	print("resetting delays")

	for c, city in ipairs(self.cities) do
		for i, trader in pairs(city) do
			for guid, data in pairs(trader.GUIDS) do
				if data > 0 then
					data = data -1
					trader.GUIDS[guid] = data
				end
			end		
		end
	end
end

function Economy:GetTradeItems(traderprefab)
	if TRADER[traderprefab] then
		return TRADER[traderprefab].items
	end
end
function Economy:GetTradeItemDesc(traderprefab)		
	if not TRADER[traderprefab] then
		return nil
	end
	return TRADER[traderprefab].desc
end

function Economy:GetDelay(traderprefab, city, inst)
	return self.cities[city][traderprefab].GUIDS[inst.GUID] or 0
end

-- function Economy:GetNumberWanted(traderprefab,city)
-- 	return self.cities[city][traderprefab].num - self.cities[city][traderprefab].current
-- end

function Economy:MakeTrade(traderprefab, city, inst)
	self.cities[city][traderprefab].GUIDS[inst.GUID] = self.cities[city][traderprefab].reset

	return self.cities[city][traderprefab].reward, self.cities[city][traderprefab].rewardqty
end

function Economy:AddCity(city)  
	self.cities[city] = deepcopy(TRADER)

	for i,item in pairs(self.cities[city]) do
		item.GUIDS = {}
	end
end

return Economy