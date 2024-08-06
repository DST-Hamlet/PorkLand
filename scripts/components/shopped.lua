local Shopped = Class(function(self, inst)
    self.inst = inst
    self.shop = nil 
end)

function Shopped:GetWanted()	
	return self.shop.components.shopinterior:GetWanted()
end 

function Shopped:SetShop(shop, shoptype)
	self.shop = shop 
	self.shoptype = shoptype
end 


function Shopped:OnSave()
	local data = {}
	local refs = {}
	assert(self.shop,"no SHOP on "..self.inst.prefab)	
	if self.shop then		
		data.shop = self.shop.GUID
		table.insert(refs,self.shop.GUID)	
	end

	if self.shoptype then
		data.shoptype = self.shoptype
	end

	if self.inst:HasTag("robbed") then
		data.robbed = true
	end

	if next(data) then
		return data, refs
	end
end

function Shopped:OnLoad(data)
	if data and data.shoptype then
		self.shoptype = data.shoptype		
	end
	if data and data.robbed then
		self.inst:AddTag("robbed")
	end
end

function Shopped:LoadPostPass(ents, data)
	if data and data.shop then
		self.shop = ents[data.shop].entity
	end
end

function Shopped:CollectSceneActions(doer, actions)
    if doer.components.shopper and self.inst.components.shopdispenser.item_served then
        table.insert(actions, ACTIONS.SHOP)
    end
end

return Shopped 