local AddClassPostConstruct = AddClassPostConstruct
GLOBAL.setfenv(1, GLOBAL)

local Controls = require("widgets/controls")
local SpellControls = require("widgets/spellcontrols")

local show_crafting_and_inventory = Controls.ShowCraftingAndInventory
function Controls:ShowCraftingAndInventory(...)
    self.spellcontrols:Show()
    return show_crafting_and_inventory(self, ...)
end

local hide_crafting_and_inventory = Controls.HideCraftingAndInventory
function Controls:HideCraftingAndInventory(...)
    self.spellcontrols:Hide()
    return hide_crafting_and_inventory(self, ...)
end

AddClassPostConstruct("widgets/controls", function(self, owner)
    self.spellcontrols = self:AddChild(SpellControls(owner))
    self.spellcontrols:MoveToBack()
end)
