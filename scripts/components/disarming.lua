local Disarming = Class(function(self, inst)
    self.inst = inst
end)

function Disarming:DoDisarming(target, doer)
    if target.components.disarmable and target.components.disarmable.armed then

        if self.ondisarm then
            self.ondisarm(self.inst, target, doer)
        end

        target.components.disarmable:disarm(doer, self.inst)

        return true
    end
end

return Disarming
