GLOBAL.setfenv(1, GLOBAL)

local WaterProofer = require("components/waterproofer")

local _GetEffectiveness = WaterProofer.GetEffectiveness
function WaterProofer:GetEffectiveness(...)
    if not TheWorld.state.fullfog or self.inst:HasTag("fogproof") then
        return _GetEffectiveness(self, ...)
    end

    return 0
end
