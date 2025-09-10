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

function Drownable:IsOverWater() -- 覆盖法
    if self:IsSafeFromFalling() then
        return false
    end

    local x, y, z = self.inst.Transform:GetWorldPosition()
    return TheWorld.Map:ReverseIsVisualWaterAtPoint(x, y, z)
end

local function _never_invincible()
    return false
end

local function _always_over_water()
    return true
end

function Drownable:CanDrownOverWater(allow_invincible)
    local _IsInvincible = allow_invincible and self.inst.components.health ~= nil and self.inst.components.health.IsInvincible or nil
    if _IsInvincible ~= nil then self.inst.components.health.IsInvincible = _never_invincible end
    local _enabled = self.enabled
    self.enabled = self.enabled ~= false
    local _IsOverWater = self.IsOverWater
    self.IsOverWater = _always_over_water
    local ret = self:ShouldDrown()
    self.IsOverWater = _IsOverWater
    self.enabled = _enabled
    if _IsInvincible ~= nil then self.inst.components.health.IsInvincible = _IsInvincible end
    return ret and not self.inst:HasTag("playerghost") -- HACK: Playerghosts dont drown because they lack the onsink sg event
end

local _GetFallingReason = Drownable.GetFallingReason
function Drownable:GetFallingReason()
    local reason = _GetFallingReason(self)
    if (reason == FALLINGREASON.VOID) and TheWorld.has_pl_ocean then
        return -- 视为不跌落
    end
    return reason
end

Drownable._WashAshore = Drownable.WashAshore
function Drownable:WashAshore()
    if TheWorld.has_pl_ocean and self:ShouldDrownToDeath() then
        return self:DrownToDeath()
    end

    return self:_WashAshore()
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
