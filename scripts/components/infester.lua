local Infester = Class(function(self, inst)
    self.inst = inst
    self.infesting = false
    self.inst:ListenForEvent("death", function() self:Uninfest() end)
    self.inst:ListenForEvent("freeze", function() self:Uninfest() end)
    self.basetime = 8
    self.randtime = 8
    self.inst:AddTag("infester")

	self.onuninfestfn = nil
end)

function Infester:Uninfest()
	self.infesting = false
	if self.target then
		self.target:RemoveChild(self.inst)
		local pos =Vector3(self.target.Transform:GetWorldPosition())
		self.inst.Transform:SetPosition(pos.x,pos.y,pos.z)

		self.target.components.infestable:uninfest(self.inst)

		self.target = nil
	end
	if self.inst.bitetask then
		self.inst.bitetask:Cancel()
		self.inst.bitetask = nil
	end

	if self.onuninfestfn then
		self.onuninfestfn(self.inst)
	end

	self.inst:ClearBufferedAction()
	self.inst:StopUpdatingComponent(self)
end

function Infester:bite()
	if self.bitefn then
		self.bitefn(self.inst)
	end
	self.inst.bitetask = self.inst:DoTaskInTime(self.basetime+(math.random()*self.randtime),function() self:bite() end)
end

function Infester:Infest(target)
	if target:HasTag("player") and not target:HasTag("playerghost") and target.components.infestable then
		self.infesting = true
		self.target = target

		if self.stopinfesttestfn then
			self.inst:StartUpdatingComponent(self)
		end

		self.inst.bitetask = self.inst:DoTaskInTime(self.basetime+(math.random()*self.randtime),function() self:bite() end)

		target:AddChild(self.inst)
		self.inst.AnimState:SetFinalOffset(1)
		self.inst.Transform:SetPosition(0,0,0)
		target.components.infestable:infest(self.inst)
	end
end

function Infester:OnUpdate( dt )
	if self.stopinfesttestfn then
		if self.stopinfesttestfn(self.inst) then
			self:Uninfest()
		end
	end
	--[[
	if self.target then
		local pos = Vector3(self.target.Transform:GetWorldPosition())
		self.inst.Transform:SetPosition(pos.x,pos.y,pos.z)
	end
]]
end

return Infester

