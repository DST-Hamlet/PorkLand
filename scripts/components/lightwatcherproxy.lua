local DEFAULT_DARK_THRESHOLD = 0.05
local DEFAULT_LIGHT_THRESHOLD = 0.1

local LightWatcherProxy = Class(function(self, inst)
    self.inst = inst
    self.darkthresh = DEFAULT_DARK_THRESHOLD
    self.lightthresh = DEFAULT_LIGHT_THRESHOLD
    self.changetime = 0
    self.inlight = true
    self.using_high_precision = false
end)

function LightWatcherProxy:UseHighPrecision(lowprecision)
    self.using_high_precision = true

    self.inst:SetEventOverride("enterlight", "")
    self.inst:SetEventOverride("enterdark", "")

    self.inst:SetEventOverride("real_enterlight", "enterlight")
    self.inst:SetEventOverride("real_enterdark", "enterdark")


    if lowprecision then
        self.inst:DoPeriodicTask(10 * FRAMES, function() self:OnUpdate(10 * FRAMES) end, math.random(1,10) * FRAMES)
    else
        self.inst:StartUpdatingComponent(self)
    end
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

function LightWatcherProxy:GetTimeInLight()
    if self.inlight then
        return GetTime() - self.changetime
    else
        return 0
    end
end

function LightWatcherProxy:GetTimeInDark()
    if not self.inlight then
        return GetTime() - self.changetime
    else
        return 0
    end
end

function LightWatcherProxy:OnUpdate(dt)
    local x, y, z = self.inst.Transform:GetWorldPosition()
    local light_value = TheSim:GetLightAtPoint(x, y, z)
    if self.inlight then
        if light_value < self.darkthresh then
            self.changetime = GetTime()
            self.inlight = false
            self.inst:PushEvent("real_enterdark")
        end
    else
        if light_value > self.lightthresh then
            self.changetime = GetTime()
            self.inlight = true
            self.inst:PushEvent("real_enterlight")
        end
    end
end

return LightWatcherProxy
