GLOBAL.setfenv(1, GLOBAL)

local Drownable = require("components/drownable")

function Drownable:DrownToDeath()
    self.inst.components.health:DoDelta(-self.inst.components.health.currenthealth, nil, "drowning", true, nil, true)
end

function Drownable:ShouldDrownToDeath()
    return self.inst:HasTag("player")
        and self.inst.components.health ~= nil
        and GetGhostEnabled()
end

local _ShouldDrown = Drownable.ShouldDrown
function Drownable:ShouldDrown(...)
    return (self.inst.components.sailor == nil or not self.inst.components.sailor:IsSailing()) and _ShouldDrown(self, ...)
end


local _WashAshore = Drownable.WashAshore
function Drownable:WashAshore(...)
    if TheWorld.has_pl_ocean and self:ShouldDrownToDeath() then
        return self:DrownToDeath()
    end

    return _WashAshore(self, ...)
end
