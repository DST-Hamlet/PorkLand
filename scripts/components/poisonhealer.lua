local Poisonhealer = Class(function(self, inst)
	self.inst = inst
	self.enabled = true --Used for snakeoil. We don't want it to actually do anything.
  
  self.inst:AddTag("poison_antidote")
end)

function Poisonhealer:Cure(target)
	if target.components.poisonable then
		if self.enabled then

			if self.oncure then
				self.oncure(self.inst, target)
			end

			target.components.poisonable:Cure(self.inst)
		end
		return true
	end
end

return Poisonhealer
