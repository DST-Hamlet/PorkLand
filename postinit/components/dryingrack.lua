local AddComponentPostInit = AddComponentPostInit
GLOBAL.setfenv(1, GLOBAL)

local DryingRack = require("components/dryingrack")

local _HasRainImmunity = DryingRack.HasRainImmunity
function DryingRack:HasRainImmunity(...)
    local x, _, z = self.inst.Transform:GetWorldPosition()
    if TheWorld.components.interiorspawner:IsInInteriorRegion(x, z) then
        return true
    end
    return _HasRainImmunity(self, ...)
end

local _IsExposedToRain = DryingRack.IsExposedToRain
function DryingRack:IsExposedToRain(...)
    local x, _, z = self.inst.Transform:GetWorldPosition()
    if TheWorld.components.interiorspawner:IsInInteriorRegion(x, z) then
        return false
    end
    return _IsExposedToRain(self, ...)
end

local _LoadPostPass = DryingRack.LoadPostPass
function DryingRack:LoadPostPass(...)
    if self.enabled then
        if (TheWorld.state.israining or TheWorld.state.isacidraining) and not self:HasRainImmunity() then
            self:PauseDrying()
        else
            self:ResumeDrying()
        end
    end
    return _LoadPostPass(self, ...)
end

