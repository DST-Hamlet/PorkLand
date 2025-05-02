GLOBAL.setfenv(1, GLOBAL)
local HoverText = require("widgets/hoverer")

local on_update = HoverText.OnUpdate
function HoverText:OnUpdate(...)
    local is_aoe_targeting
    if self.owner.components.playercontroller then
        is_aoe_targeting = self.owner.components.playercontroller.IsAOETargeting
        self.owner.components.playercontroller.IsAOETargeting = function(self, ...)
            return is_aoe_targeting(self, ...) or self.casting_action_override_spell
        end
    end
    on_update(self, ...)
    if is_aoe_targeting then
        self.owner.components.playercontroller.IsAOETargeting = is_aoe_targeting
    end
end
