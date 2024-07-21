GLOBAL.setfenv(1, GLOBAL)

local easing = require("easing")
local Moisture = require("components/moisture")

local _GetMoistureRate = Moisture.GetMoistureRate
function Moisture:GetMoistureRate(...)
    local x, y, z = self.inst.Transform:GetWorldPosition()
    if TheWorld.components.interiorspawner:IsInInteriorRegion(x, z) then
        return 0
    end
    if not TheWorld.state.fullfog then
        return _GetMoistureRate(self, ...)
    end
    return self:_GetMoistureRateAssumingRain() * TUNING.FOG_MOISTURE_RATE_SCALE  -- fog moisture rate
end

local MUST_TAGS = {"blows_air"}
local _GetDryingRate = Moisture.GetDryingRate
function Moisture:GetDryingRate(...)
    local rate = _GetDryingRate(self, ...)

    local x, y, z = self.inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, 30, MUST_TAGS)

    if #ents > 0  then
        rate = rate + TUNING.HYDRO_BONUS_COOL_RATE
    end
    return rate
end
