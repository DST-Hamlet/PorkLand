local AddComponentPostInit = AddComponentPostInit
GLOBAL.setfenv(1, GLOBAL)

local function GetWindSpeed(self)
    local wind_speed = 1

    if TheWorld.net.components.plateauwind 
        and TheWorld.net.components.plateauwind:GetIsWindy() 
        and not self.inst:HasTag("windspeedimmune") 
        and not self.inst:HasTag("playerghost") then 
        
            -- get a wind speed adjustment
        local windangle = self.inst.Transform:GetRotation() - TheWorld.net.components.plateauwind:GetWindAngle()
        local windproofness = 1.0 -- ziwbi: There are no wind proof items in Hamelt... yet
        local windfactor = TUNING.WIND_PUSH_MULTIPLIER * windproofness * TheWorld.net.components.plateauwind:GetWindSpeed() * math.cos(windangle * DEGREES) + 1.0
        wind_speed = math.max(0.1, windfactor)
    end

    return wind_speed
end

AddComponentPostInit("locomotor", function(self)
    local GetSpeedMultiplier = self.GetSpeedMultiplier
    self.GetSpeedMultiplier = function(self)
        return GetSpeedMultiplier(self) * GetWindSpeed(self)
    end
end)
