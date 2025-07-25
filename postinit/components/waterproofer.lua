GLOBAL.setfenv(1, GLOBAL)

local WaterProofer = require("components/waterproofer")

local _GetEffectiveness = WaterProofer.GetEffectiveness
function WaterProofer:GetEffectiveness(...)
    if (is_fogtest and not self.inst:HasTag("fogproof")) then
        return 0
    end

    return _GetEffectiveness(self, ...)
end
