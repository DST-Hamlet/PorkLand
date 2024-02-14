GLOBAL.setfenv(1, GLOBAL)

local Edible = require("components/edible")

local _OnEaten = Edible.OnEaten
function Edible:OnEaten(eater, ...)
    if eater and self.antihistamine ~= nil and eater.components.hayfever then
        eater.components.hayfever:SetNextSneezeTime(self.antihistamine)
    end

	if self.caffeinedelta ~= 0 and self.caffeineduration ~= 0 and eater and eater.components.locomotor then
		eater.components.locomotor:SetSpeedModifier_Additive("CAFFEINE", self.caffeinedelta)
        eater:DoTaskInTime(self.caffeineduration, function()
            eater.components.locomotor:RemoveSpeedModifier_Additive("CAFFEINE")
        end)
	end

    _OnEaten(self, eater, ...)
end
