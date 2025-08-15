local AddComponentPostInit = AddComponentPostInit
GLOBAL.setfenv(1, GLOBAL)

local easing = require("easing")
local Moisture = require("components/moisture")

function Moisture:_GetMoistureRateAssumingFog()
    is_fogtest = true
    local waterproofmult = self:GetWaterproofness()
    
    is_fogtest = false

    if waterproofmult >= 1 then
        return 0
    end

    local rate = easing.inSine(TheWorld.state.precipitationrate, self.minMoistureRate, self.maxMoistureRate, 1)
    return rate * (1 - waterproofmult)
end

local _GetMoistureRate = Moisture.GetMoistureRate
function Moisture:GetMoistureRate(...)
    local rate = 0

    -- 天气影响
    
    if TheWorld.state.fogstate == FOG_STATE.FOGGY or TheWorld.state.fogstate == FOG_STATE.SETTING then
        rate = self:_GetMoistureRateAssumingFog() * TUNING.FOG_MOISTURE_RATE_SCALE
    else
        rate = _GetMoistureRate(self, ...)
    end

    local x, _, z = self.inst.Transform:GetWorldPosition()
    if TheWorld.components.interiorspawner:IsInInteriorRegion(x, z) then
        rate = 0
    end

    -- 非天气影响

    if self.inst.components.inventory and self.inst.components.inventory:IsFloaterHeld() then
		rate = _GetMoistureRate(self, ...)
    end
    
    local waterproofmult = self:GetWaterproofness()
    rate = rate + self:GetExternalMoistureRate() * (1 - waterproofmult)

    return rate
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

function Moisture:AddExternalMoistureRate(src, bonus, key)
    self.externalmoisturerate:SetModifier(src, bonus, key)
end

function Moisture:RemoveExternalMoistureRate(src, key)
    self.externalmoisturerate:RemoveModifier(src, key)
end

function Moisture:GetExternalMoistureRate()
    return self.externalmoisturerate:Get()
end

AddComponentPostInit("moisture", function(self, inst)
    self.externalmoisturerate = SourceModifierList(inst, 0, SourceModifierList.additive)
end)
