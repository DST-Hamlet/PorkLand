local Sinkable = Class(function(self, inst)
    self.inst = inst
    self.sunken = false
	self.inst:ListenForEvent("retrieve", function() self:onfished() end)
	self.oldname = inst.name
end)

local function onfinishcallback(inst, worker)
	inst:RemoveComponent("workable")
   	worker.components.inventory:GiveItem(inst)
end

function Sinkable:onfished()
	self.inst:Hide()
	self.inst:RemoveTag("sunken")
	self.sunken = false
	self.inst.name = self.oldname
end

function Sinkable:onhitwater()
	if self.inst:GetIsOnWater() then
		self.inst:AddTag("sunken")
		self.sunken = true
		self.oldname = self.inst.name
		self.inst.name = STRINGS.NAMES.SUNKEN_RELIC
  		self.inst:AddComponent("workable")
  		self.inst.components.workable:SetWorkAction(ACTIONS.FISH)
        self.inst.components.workable:SetWorkLeft(1)
        self.inst.components.workable:SetOnFinishCallback(onfinishcallback)
		-- don't give up the item when destroyed.
		-- self.inst.components.workable:SetShouldDoWorkLeftOnDestroy(function() return false end)
	end
end

function Sinkable:OnSave()
	return {
		sunken = self.inst:HasTag("sunken"),
		oldname = self.oldname
	}
end

function Sinkable:OnLoad(data)
	if data then
	 	if data.oldname then
	 		self.oldname = data.oldname
	 	end
	end
end

return Sinkable
