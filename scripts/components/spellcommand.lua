local SpellCommand = Class(function(self, inst)
    self.inst = inst

    self.on_run = nil
end)

function SpellCommand:SetOnRun(on_run)
    self.on_run = on_run
end

function SpellCommand:Run(buffered_action)
    if self.on_run then
       return self.on_run(self.inst, buffered_action)
    end
end

return SpellCommand
