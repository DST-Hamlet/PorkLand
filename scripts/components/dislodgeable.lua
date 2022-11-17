local Dislodgeable = Class(function(self, inst)
    self.inst = inst

    self.canbedislodged = nil
    self.hasbeendislodged = nil

    self.product = nil
    self.numtoharvest = 1
    self.ondislodgedfn = nil
    self.caninteractwith = true
end)

function Dislodgeable:SetUp(product, numtoharvest)
    self.canbedislodged = true
    self.hasbeendislodged = false
    self.product = product
    self.numtoharvest = numtoharvest
end

function Dislodgeable:OnSave()
	local data = {
        hasbeendislodged = self.hasbeendislodged,
		caninteractwith = self.caninteractwith,
	}
    if next(data) then
		return data
	end
end

function Dislodgeable:OnLoad(data)
    if data.caninteractwith then
    	self.caninteractwith = data.caninteractwith
    end
    if data.hasbeendislodged then
    	self.hasbeendislodged = data.hasbeendislodged
    end
end

function Dislodgeable:SetDislodged()
    self.canbedislodged = false
    self.hasbeendislodged = true
end

function Dislodgeable:Dislodge(dislodger)
    if self.canbedislodged and self.caninteractwith then
        if self.inst.components.lootdropper then
        local pt =self.inst:GetPosition()
        local numtoharvest = self.numtoharvest
            for i =1,numtoharvest do
                self.inst.components.lootdropper:SpawnLootPrefab(self.product, pt)
            end
        end
        local product = SpawnPrefab(self.product)
            if product.components.inventoryitem ~= nil then
                product.components.inventoryitem:InheritMoisture(TheWorld.state.wetness, TheWorld.state.iswet)
            end
            if self.ondislodgedfn then
                self.ondislodgedfn(self.inst, dislodger, product)
            end
        self:SetDislodged()
    	self.inst:PushEvent("dislodged", {dislodger = dislodger, product = product})
    end
end

function Dislodgeable:CollectSceneActions(doer, actions)
    if self.canbedislodged and self.caninteractwith and
    doer.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS) and
    doer.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS):HasTag("dislodger") then
        table.insert(actions, ACTIONS.DISLODGE)
    end
end

function Dislodgeable:CanBeDislodged()
	if self.canbedislodgedfn then
		if not self.canbedislodgedfn(self.inst) then
			return false
		end
	end

    return self.canbedislodged
end

function Dislodgeable:SetOnDislodgedFn(fn)
	self.ondislodgedfn = fn
end

return Dislodgeable
