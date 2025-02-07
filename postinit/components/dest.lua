GLOBAL.setfenv(1, GLOBAL)

require("components/locomotor")

local _DestGetPoint = Dest.GetPoint
function Dest:GetPoint(...)
    if self.inst ~= nil and self.inst:IsValid() then
        if self.inst.DestOverride then
            return self.inst:DestOverride()
        end
    end
    return _DestGetPoint(self, ...)
end
