local ShopDispenser = Class(function(self, inst)
    self.inst = inst
    self.item_served = nil
end)

function ShopDispenser:SetItem(prefab)
	self.item_served = prefab.prefab
end 

function ShopDispenser:RemoveItem(prefab)
	self.item_served = nil
end 



function ShopDispenser:GetItem()
	return self.item_served	
end

function ShopDispenser:OnSave()
	local data = {}
	data.item_served = self.item_served
	return data
end

function ShopDispenser:OnLoad(data)
	if data then
		if data.item_served then
	 		self.item_served = data.item_served 
	 	end
	end
end

return ShopDispenser 