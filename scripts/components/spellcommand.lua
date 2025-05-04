local SpellCommand = Class(function(self, inst)
    self.inst = inst

    self.spell_display_name = nil
    self.selected_spell_id = nil
    self.on_run = nil
end)

function SpellCommand:SetSpell(spell_display_name, on_run)
    self.spell_display_name = spell_display_name
    self.on_run = on_run
end

function SpellCommand:SetSpellName(spell_display_name)
    self.spell_display_name = spell_display_name
end

function SpellCommand:GetSpellName()
    return self.spell_display_name
end

function SpellCommand:SetSelectedSpell(id)
    self.selected_spell_id = id
end

function SpellCommand:GetSelectedSpell()
    return self.selected_spell_id
end

function SpellCommand:ReselectSelectedSpellInSpellBook()
    if not self.selected_spell_id then
        return
    end
    for index, item in ipairs(self.inst.components.spellbook.items) do
        if item.id and item.id == self.selected_spell_id then
            self.inst.components.spellbook:SelectSpell(index)
        end
    end
end

function SpellCommand:SetOnRun(on_run)
    self.on_run = on_run
end

function SpellCommand:Run(buffered_action)
    if self.on_run then
       return self.on_run(self.inst, buffered_action)
    end
end

return SpellCommand
