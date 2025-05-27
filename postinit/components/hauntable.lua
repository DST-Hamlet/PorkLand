GLOBAL.setfenv(1, GLOBAL)

----------------------------------------------------------------------------------------
local Hauntable = require("components/hauntable")

local _StartShaderFx = Hauntable.StartShaderFx
function Hauntable:StartShaderFx(...)
    if self.inst.components.rotatingbillboard then
        self.inst.components.rotatingbillboard:SetMaskHaunt(true)
    else
        if self.inst.replica.sailable then
            self.inst.replica.sailable:UpdateHaunt(true)
        end
        _StartShaderFx(self, ...)
    end
end

local _StopShaderFX = Hauntable.StopShaderFX
function Hauntable:StopShaderFX(...)
    if self.inst.components.rotatingbillboard then
        if self.inst:IsValid() then
            self.inst.components.rotatingbillboard:SetMaskHaunt(false)
        end
    else
        if self.inst:IsValid() and self.inst.replica.sailable then
            self.inst.replica.sailable:UpdateHaunt(false)
        end
        _StopShaderFX(self, ...)
    end
end
