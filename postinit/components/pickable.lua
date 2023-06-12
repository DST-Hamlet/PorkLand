GLOBAL.setfenv(1, GLOBAL)

local Pickable = require("components/pickable")

local _CanBePicked = Pickable.CanBePicked
function Pickable:CanBePicked(...)
    if self.inst:HasTag("nettle_plant") then
        if self.inst.wet and self.inst:HasTag("pickable") then
            return true
        else
            return false
        end
    end

    return _CanBePicked(self, ...)
end
