local SpellCommand = Class(function(self, inst)
    self.inst = inst

    self.commands = {}
    self.ui_background = nil

    self.spell_display_name = nil
    self.selected_command_id = nil
    self.on_run = nil
end)

function SpellCommand:SetSpellCommands(commands)
    self.commands = commands
end

function SpellCommand:GetSpellCommands()
    return self.commands
end

function SpellCommand:GetSpellCommandById(id)
    for i, command in ipairs(self.commands) do
        if command.id == id then
            return command, i
        end
    end
end

function SpellCommand:SetSelectedCommand(id)
    self.selected_command_id = id
end

function SpellCommand:GetSelectedCommandId()
    return self.selected_command_id
end

function SpellCommand:GetSelectedCommand()
    return self:GetSpellCommandById(self.selected_command_id)
end

function SpellCommand:GetSeletedCommandName()
    local command = self:GetSelectedCommand()
    return command and command.label
end

function SpellCommand:RunCommand(id, doer, position, target)
    local command = self:GetSpellCommandById(id)
    if command and command.on_execute_on_server then
        command.on_execute_on_server(self.inst, doer, position, target)
    end
end

return SpellCommand
