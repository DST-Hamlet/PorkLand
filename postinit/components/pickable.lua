GLOBAL.setfenv(1, GLOBAL)

local Pickable = require("components/pickable")

local _CanBePicked = Pickable.CanBePicked
function Pickable:CanBePicked(...)
    if self.inst:HasTag("nettle_plant") then
        if self.inst.wet then
            return true
        end
    end

    _CanBePicked(self, ...)
end
