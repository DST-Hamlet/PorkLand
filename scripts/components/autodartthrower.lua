local Autodartthrower = Class(function(self, inst)
	self.inst = inst
end)

function Autodartthrower:OnEntitySleep()
	self:TurnOff()
end

function Autodartthrower:OnEntityWake()
	if self.on then
		self:TurnOn()
	end
end

function Autodartthrower:TurnOn()
	if self.inst.components.disarmable.armed then
		self.on = true
		self.inst:StartUpdatingComponent(self)
		if self.turnonfn then
			self.turnonfn(self.inst)
		end
	end
end

function Autodartthrower:TurnOff()
	self.on = nil
	self.inst:StopUpdatingComponent(self)
	if self.turnofffn then
		self.turnofffn(self.inst)
	end	
end

function Autodartthrower:OnUpdate(dt)
	if self.updatefn then
		self.updatefn(self.inst,dt)
	end
end

function Autodartthrower:OnSave()
	local data = {}	
		data.on = self.on
	return data
end

function Autodartthrower:OnLoad(data)
	if data then
		if data.on then
			self:TurnOn()
		end
	end
end


return Autodartthrower