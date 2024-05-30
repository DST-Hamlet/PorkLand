GLOBAL.setfenv(1, GLOBAL)

local PL_ICONS = require("prefabs/visualvariant_defs").PL_ICONS

local _GetImage = Ingredient.GetImage
function Ingredient:GetImage(...)
    if self.image == nil then
        if TheWorld:HasTag("porkland") and PL_ICONS[self.type] ~= nil then
            self.image = PL_ICONS[self.type] .. ".tex"
        end
    end
    return _GetImage(self, ...)
end
