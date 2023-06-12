GLOBAL.setfenv(1, GLOBAL)

local easing = require("easing")
local Moisture = require("components/moisture")

local _GetMoistureRate = Moisture.GetMoistureRate
function Moisture:GetMoistureRate(...)
    local sprinkler_rate = 0
    local x, y, z = self.inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, 8)
    for i, v in ipairs(ents) do
        if v:HasTag("sprinkler") and v.on then
            sprinkler_rate = sprinkler_rate + TUNING.MOISTURE_SPRINKLER_PERCENT_INCREASE_PER_SPRAY * 5
        end
    end

    if sprinkler_rate < 0 and not TheWorld.state.fullfog then
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

    local rate = easing.inSine(TheWorld.state.precipitationrate, self.minMoistureRate, self.maxMoistureRate, 1) + sprinkler_rate
    return rate * (1 - waterproofmult) * (TheWorld.state.fullfog and TUNING.FOG_MOISTURE_RATE_SCALE or 1)  -- fog moisture rate
end
