local AddComponentPostInit = AddComponentPostInit
GLOBAL.setfenv(1, GLOBAL)

local easing = require("easing")
local Moisture = require("components/moisture")

function Moisture:GetMoistureRate(...)
    local rate = self:_GetMoistureRateAssumingRain()
    local waterproofmult =
        (   self.inst.components.sheltered ~= nil and
            self.inst.components.sheltered.sheltered and
            self.inst.components.sheltered.waterproofness or 0
        ) +
        (   self.inst.components.inventory ~= nil and
            self.inst.components.inventory:GetWaterproofness() or 0
        ) +
        (   self.inherentWaterproofness or 0
        ) +
        (
            self.waterproofnessmodifiers:Get() or 0
        )
    if waterproofmult >= 1 then
        waterproofmult = 1
    end
    local x, _, z = self.inst.Transform:GetWorldPosition()
    if TheWorld.components.interiorspawner:IsInInteriorRegion(x, z) then
        rate = 0
    elseif TheWorld.state.fullfog then
        rate = rate * TUNING.FOG_MOISTURE_RATE_SCALE
    end
    rate = rate + self:GetExternalMoistureRate() * (1 - waterproofmult)
    return rate  -- fog moisture rate
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
