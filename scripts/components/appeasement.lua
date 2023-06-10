local Appeasement = Class(function(self, inst)
    self.inst = inst
    self.appeasementvalue = 0 
end)

function Appeasement:CollectUseActions(doer, target, actions)
    if target.components.appeasable and target.components.appeasable.enabled then
        table.insert(actions, ACTIONS.GIVE)
    end
end


return Appeasement