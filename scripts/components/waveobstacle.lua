local WaveObstacle = Class(function(self, inst)
    self.inst = inst
    self.hittestfn = nil
    self.oncollidefn = nil
    self.ondestroyfn = nil
    self.destroychance = 0.01
	
	self.inst:AddTag("waveobstacle")
end)

function WaveObstacle:IsHit(wave)
	return self.hittestfn == nil or self.hittestfn(self.inst, wave)
end

function WaveObstacle:OnCollide(wave)
	if self.oncollidefn then
		self.oncollidefn(self.inst, wave)
	end
	if self.ondestroyfn and math.random() < self.destroychance then
		self.ondestroyfn(self.inst)
	end
end

function WaveObstacle:SetOnCollideFn(fn)
	self.oncollidefn = fn
end

function WaveObstacle:SetOnDestroyFn(fn)
	self.ondestroyfn = fn
end

function WaveObstacle:SetDestroyChance(chance)
	self.destroychance = chance
end

return WaveObstacle