GLOBAL.setfenv(1, GLOBAL)

local easing = require("easing")
local Moisture = require("components/moisture")

local _GetMoistureRate = Moisture.GetMoistureRate
function Moisture:GetMoistureRate(...)
    if not TheWorld.state.fullfog then
        return _GetMoistureRate(self, ...)
    end

    local waterproofmult =
        (   self.inst.components.sheltered ~= nil and
            self.inst.components.sheltered.sheltered and
            self.inst.components.sheltered.waterproofness or 0
        ) +
        (   self.inst.components.inventory ~= nil and
            self.inst.components.inventory:GetFogWaterproofness() or 0
        ) +
        (   self.inherentWaterproofness or 0
        ) +
        (
            self.waterproofnessmodifiers:Get() or 0
        )
    if waterproofmult >= 1 then
        return 0
    end

    local rate = easing.inSine(TheWorld.state.precipitationrate, self.minMoistureRate, self.maxMoistureRate, 1)
    return rate * (1 - waterproofmult) * TUNING.FOG_MOISTURE_RATE_SCALE  -- fog moisture rate
end
