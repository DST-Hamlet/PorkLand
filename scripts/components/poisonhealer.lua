local Poisonhealer = Class(function(self, inst)
    self.inst = inst
    self.enabled = true --Used for snakeoil. We don't want it to actually do anything.
end)

function Poisonhealer:CollectInventoryActions(doer, actions)
    if doer.components.poisonable then
        table.insert(actions, ACTIONS.CUREPOISON)
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

return Poisonhealer
