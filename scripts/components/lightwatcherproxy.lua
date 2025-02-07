local DEFAULT_DARK_THRESHOLD = 0.05
local DEFAULT_LIGHT_THRESHOLD = 0.1

local LightWatcherProxy = Class(function(self, inst)
    self.inst = inst
    self.darkthresh = DEFAULT_DARK_THRESHOLD
    self.lightthresh = DEFAULT_LIGHT_THRESHOLD
    self.inlight = true
    self.using_high_precision = false
end)

function LightWatcherProxy:UseHighPrecision()
    self.using_high_precision = true
    self.inst:StartUpdatingComponent(self)
end

function LightWatcherProxy:IsInLight()
    if self.using_high_precision then
        return self.inlight
    else
        local x, y, z = self.inst.Transform:GetWorldPosition()
        local light_value = TheSim:GetLightAtPoint(x, y, z)
        return light_value >= self.darkthresh
    end
end

function LightWatcherProxy:OnUpdate(dt)
    local x, y, z = self.inst.Transform:GetWorldPosition()
    local light_value = TheSim:GetLightAtPoint(x, y, z)
    if self.inlight then
        if light_value < self.darkthresh then
            self.inlight = false
        end
    else
        if light_value > self.lightthresh then
            self.inlight = true
        end
    end
end

return LightWatcherProxy
