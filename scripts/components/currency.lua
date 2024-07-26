local Currency = Class(function(self, inst)
    self.inst = inst
    self.value = 1
end)

function Currency:CollectUseActions(doer, target, actions)
    if target.components.payable and target.components.payable.enabled then
        table.insert(actions, ACTIONS.GIVE)
    end
end

return Currency
