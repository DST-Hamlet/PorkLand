local AddComponentPostInit = AddComponentPostInit
GLOBAL.setfenv(1, GLOBAL)

local Edible = require("components/edible")

local _OnEaten = Edible.OnEaten
function Edible:OnEaten(eater, ...)
    if eater and self.antihistamin and eater.components.hayfever then
        eater.components.hayfever:SetNextSneezeTime(self.antihistamine)
    end

    _OnEaten(self, eater, ...)
end

-- AddComponentPostInit("edible", function(self)
    -- self.antihistamine = 0  -- delayed hayfever
-- end)
