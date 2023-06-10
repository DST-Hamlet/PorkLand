local Poisonhealer = Class(function(self, inst)
	self.inst = inst
	self.enabled = true --Used for snakeoil. We don't want it to actually do anything.
end)

function Poisonhealer:CollectInventoryActions(doer, actions)
	if doer.components.poisonable then
		--table.insert(actions, ACTIONS.CUREPOISON)--暂时注释掉，等ACTION完善
	end
end

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

function Poisonhealer:CollectUseActions(doer, target, actions)
	--if target.components.health and target.components.health.canheal then
	if target.components.poisonable and (target == self.inst or target.components.poisonable:IsPoisoned() ) then
		--table.insert(actions, ACTIONS.CUREPOISON)--暂时注释掉，等ACTION完善
	end
end

return Poisonhealer
