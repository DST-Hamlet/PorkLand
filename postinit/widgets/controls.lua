local AddClassPostConstruct = AddClassPostConstruct
GLOBAL.setfenv(1, GLOBAL)

local SpellControls = require("widgets/spellcontrols")

AddClassPostConstruct("widgets/controls", function(self, owner)
    self.spellcontrols = self:AddChild(SpellControls(owner))
    self.spellcontrols:MoveToBack()
end)
