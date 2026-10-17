GLOBAL.setfenv(1, GLOBAL)

----------------------------------------------------------------------------------------
local Hauntable = require("components/hauntable")

local _StartShaderFx = Hauntable.StartShaderFx
function Hauntable:StartShaderFx(...)
    if self.inst.replica.sailable then
        self.inst.replica.sailable:UpdateHaunt(true)
    end
    _StartShaderFx(self, ...)
end

local _StopShaderFX = Hauntable.StopShaderFX
function Hauntable:StopShaderFX(...)
    if self.inst:IsValid() and self.inst.replica.sailable then
        self.inst.replica.sailable:UpdateHaunt(false)
    end
    _StopShaderFX(self, ...)
end
