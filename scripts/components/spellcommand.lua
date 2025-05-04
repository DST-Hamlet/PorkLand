local SpellCommand = Class(function(self, inst)
    self.inst = inst

    self.spell_display_name = nil
    self.on_run = nil
end)

function SpellCommand:SetSpell(spell_display_name, on_run)
    self.spell_display_name = spell_display_name
    self.on_run = on_run
end

function SpellCommand:GetSpellName()
    return self.spell_display_name
end

-- function SpellCommand:SetOnRun(on_run)
--     self.on_run = on_run
-- end

function SpellCommand:Run(buffered_action)
    if self.on_run then
       return self.on_run(self.inst, buffered_action)
    end
end

return SpellCommand
