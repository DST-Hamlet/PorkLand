GLOBAL.setfenv(1, GLOBAL)

local Edible = require("components/edible")

local _OnEaten = Edible.OnEaten
function Edible:OnEaten(eater, ...)
    if eater and self.antihistamine ~= nil and eater.components.hayfever then
        eater.components.hayfever:SetNextSneezeTime(self.antihistamine)
    end

	if eater and self.caffeinedelta and self.caffeineduration and eater.components.locomotor then
		eater.components.locomotor:SetExternalSpeedMultiplier("CAFFEINE", self.caffeinedelta, self.caffeineduration)
        self.caffeine_timer = self.caffeineduration
	end

    _OnEaten(self, eater, ...)
end
