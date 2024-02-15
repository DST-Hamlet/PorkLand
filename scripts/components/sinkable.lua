local onsunken = function(self, onsunken)
    if onsunken then
        self.inst:AddTag("fishable")
    else
        self.inst:RemoveTag("fishable")
    end
end

local Sinkable = Class(function(self, inst)
    self.inst = inst

    self.oldname = inst.name
    self.sunken = nil
    self.inst:ListenForEvent("retrieve", function() self:OnFished() end)
end,
nil,
{
    sunken = onsunken
})

function Sinkable:OnRemoveFromEntity()
    self.inst:RemoveTag("fishable")

    self.inst:RemoveEventCallback("retrieve", function() self:OnFished() end)
end

function Sinkable:InSunkening()
    return self.sunken
end

function Sinkable:OnFished()
	self.inst:Hide()
	self.inst.name = self.oldname
    self.sunken = false
    self.inst.components.inventoryitem.canbepickedup = true
end

function Sinkable:OnHitWater()
	if self.inst:IsOnOcean() then
		self.sunken = true
		self.oldname = self.inst.name
		-- self.inst.name = STRINGS.NAMES.SUNKEN_RELIC
        self.inst:AddComponent("workable")
        self.inst.components.workable:SetWorkAction(ACTIONS.FISH)
        self.inst.components.workable:SetWorkLeft(1)
        self.inst.components.workable:SetOnFinishCallback(function(inst, worker)
            inst:RemoveComponent("workable")
            worker.components.inventory:GiveItem(inst)
        end)
        self.inst.components.inventoryitem.canbepickedup = false
	end
end

function Sinkable:OnSave()
	return {
		oldname = self.oldname
	}
end

function Sinkable:OnLoad(data)
	if data ~= nil then
	 	if data.oldname ~= nil then
	 		self.oldname = data.oldname
	 	end
	end
end

return Sinkable
