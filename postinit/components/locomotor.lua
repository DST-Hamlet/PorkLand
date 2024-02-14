GLOBAL.setfenv(1, GLOBAL)

local LocoMotor = require("components/locomotor")

LocoMotor._modifiers_addictive = {}
LocoMotor._speed_modifier_additive = 0

function LocoMotor:SetSpeedModifier_Additive(key, addition)
    if not key then
        return
    end

    self:RemoveSpeedModifier_Additive(key)
    if addition == 0 then
        return
    end

    self._modifiers_addictive[key] = addition
    self._speed_modifier_additive = self._speed_modifier_additive + addition
end

function LocoMotor:RemoveSpeedModifier_Additive(key)
    self._speed_modifier_additive = self._speed_modifier_additive - self._modifiers_addictive[key]
    self._modifiers_addictive[key] = nil
end

local _GetSpeedMultiplier = LocoMotor.GetSpeedMultiplier
function LocoMotor:GetSpeedMultiplier()
    local mult = _GetSpeedMultiplier(self) * (TheWorld.net.components.plateauwind and TheWorld.net.components.plateauwind:GetWindSpeed() or 1)
    local adders = self._speed_modifier_additive
    local desired_speed = self.isrunning and self:RunSpeed() or self.walkspeed

    return (1 + adders * mult/desired_speed)
end
