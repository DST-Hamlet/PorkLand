local PLENV = env
GLOBAL.setfenv(1, GLOBAL)

local Edible = require("components/edible")

local Old_OnEaten = Edible.OnEaten
function Edible:OnEaten(eater, ...)

	if eater ~= nil and self.antihistamine and eater.components.hayfever ~= nil then
        eater.components.hayfever:SetNextSneezeTime(self.antihistamine)
	end

    Old_OnEaten(self, eater, ...)
end

PLENV.AddComponentPostInit("edible", function(self)
    self.antihistamine = 0
end)
