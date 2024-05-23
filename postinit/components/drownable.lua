GLOBAL.setfenv(1, GLOBAL)

local Drownable = require("components/drownable")

function Drownable:DrownToDeath()
    self.inst.components.health:DoDelta(-self.inst.components.health.currenthealth, nil, "drowning", true, nil, true)
end

function Drownable:ShouldDrownToDeath()
    return TheWorld.has_pl_ocean
        and self.inst:HasTag("player")
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

local _OnFallInOcean = Drownable.OnFallInOcean
function Drownable:OnFallInOcean(shore_x, shore_y, shore_z, ...)
    local rets = {_OnFallInOcean(self, shore_x, shore_y, shore_z, ...)}

    if self.inst.components.burnable then
        self.inst.components.burnable:Extinguish()
    end

    if self.inst:HasTag("player") and self.inst.sg and self.inst.sg:HasStateTag("drowning") then
        if self.inst.Transform then
            self.inst:DoTaskInTime(0, function(_inst)
                -- Prevents misjudges (like respawning over water)
                if self.inst.sg and self.inst.sg:HasStateTag("drowning") and not self.inst.sg:HasStateTag("jumping") then
                    SpawnAt("boat_death", self.inst)
                end
            end)
        end
    end


    return unpack(rets)
end
