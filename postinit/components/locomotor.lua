GLOBAL.setfenv(1, GLOBAL)
local LocoMotor = require("components/locomotor")

local function GetWindSpeed(self)
    local wind_speed = 1

    -- get a wind speed adjustment
    if TheWorld.net.components.plateauwind and TheWorld.net.components.plateauwind:GetIsWindy()
        and not self.inst:HasTag("windspeedimmune")
        and not self.inst:HasTag("playerghost") then

        local windangle = self.inst.Transform:GetRotation() - TheWorld.net.components.plateauwind:GetWindAngle()
        local windproofness = 1.0 -- ziwbi: There are no wind proof items in Hamelt... yet
        local windfactor = TUNING.WIND_PUSH_MULTIPLIER * windproofness * TheWorld.net.components.plateauwind:GetWindSpeed() * math.cos(windangle * DEGREES) + 1.0
        wind_speed = math.max(0.1, windfactor)
    end

    return wind_speed
end

local GetSpeedMultiplier = LocoMotor.GetSpeedMultiplier
function LocoMotor:GetSpeedMultiplier()
    return GetSpeedMultiplier(self) * GetWindSpeed(self)
end
