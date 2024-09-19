GLOBAL.setfenv(1, GLOBAL)

local Pickable = require("components/pickable")

local _CanBePicked = Pickable.CanBePicked
function Pickable:CanBePicked(...)
    return _CanBePicked(self, ...) and not self.inst:HasTag("unsuited")
end

function Pickable:MakeUnsuited(unsuited)
    if unsuited then
        if not self.inst:HasTag("unsuited") then
            self.inst:AddTag("unsuited")
        end
    else
        if self.inst:HasTag("unsuited") then
            self.inst:RemoveTag("unsuited")
        end
    end
end
