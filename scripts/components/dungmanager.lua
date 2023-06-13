
local Dungmanager = Class(function(self, inst)
    self.inst = inst    
    self.dungpiles = {}
    self.dungtotal = 0

    self.beetles = {}
    self.beetletotal = 0
end)

function Dungmanager:OnSave()	
	local refs = {}
	local data = {}	
	data.dungpiles = {}
	for GUID, ent in pairs(self.dungpiles) do
		table.insert(data.dungpiles, self.dungpiles.GUID)
		table.insert(refs, self.dungpiles.GUID)
	end	
	data.beetles = {}
	for GUID, ent in pairs(self.beetles) do
		table.insert(data.beetles, self.beetles.GUID)
		table.insert(refs, self.beetles.GUID)
	end		
	return data, refs
end 

function Dungmanager:OnLoad(data)

end 

function Dungmanager:LoadPostPass(ents, data)
	if data.dungpiles then
		for i,GUID in ipairs(data.dungpiles)do		
			local dung = ents[GUID].entity
			if dung then
				self.dungpiles[dung.GUID] = dung
				self.dungtotal = self.dungtotal + 1
			end
		end
	end
	if data.beetles then
		for i,GUID in ipairs(data.beetles)do		
			local beetle = ents[GUID].entity
			if beetle then
				self.beetles[beetle.GUID] = beetle
				self.beetletotal = self.beetletotal + 1
			end
		end
	end	
end

function Dungmanager:removeDung(dung)
	if self.dungpiles[dung.GUID] then
		self.dungpiles[dung.GUID] = nil
		self.dungtotal = self.dungtotal - 1
	end
end

function Dungmanager:registerDung(dung)
	if dung and not self.dungpiles[dung.GUID] then
		print("REGISTERING DUNG")
		
		self.dungpiles[dung.GUID] = dung
		self.dungtotal = self.dungtotal + 1
		
		dung:ListenForEvent( "onremove", function() self:removeDung(dung)  end, dung )

		-- if beetles outnumber dung

		-- if dung outnumbers

	end
end

function Dungmanager:removeBeetle(beetle)
	if self.beetles[beetle.GUID] then
		self.beetles[beetle.GUID] = nil
		self.beetletotal = self.beetletotal - 1
	end
end

function Dungmanager:registerBeetle(beetle)
	if beetle and not self.beetles[beetle.GUID] then

		self.beetles[beetle.GUID] = beetle
		self.beetletotal = self.beetletotal + 1
		
		beetle:ListenForEvent( "onremove", function() self:removeBeetle(beetle)  end, beetle )
		print("REGISTERING BEETLE", self.beetletotal)
	end
end

return Dungmanager