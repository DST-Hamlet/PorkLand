local Image = require("widgets/image")
local Widget = require("widgets/widget")

local BoatOver = Class(Widget, function(self, owner)
    Widget._ctor(self, "BoatOver")
    self.owner = owner

    self:SetClickable(false)
    self:Hide()

    self.bg = self:AddChild(Image("images/overlays/fx3.xml", "boat_over.tex"))
    self.bg:SetVRegPoint(ANCHOR_MIDDLE)
    self.bg:SetHRegPoint(ANCHOR_MIDDLE)
    self.bg:SetVAnchor(ANCHOR_MIDDLE)
    self.bg:SetHAnchor(ANCHOR_MIDDLE)
    self.bg:SetScaleMode(SCALEMODE_FILLSCREEN)

    self.base_level = 0
    self.level = 0
    self.k = 1
    self:UpdateState()
    self.time_since_pulse = 0
    self.pulse_period = 1
end)

function BoatOver:UpdateState()
    self:TurnOff()
end

function BoatOver:TurnOn()
    self:StartUpdating()
    self.base_level = 0.5
    self.k = 5
    self.time_since_pulse = 0
end

function BoatOver:TurnOff()
    self.base_level = 0
    self.k = 5
    self:OnUpdate(0)
end

function BoatOver:OnUpdate(dt)
    -- ignore abnormally large intervals as they will destabilize the math in here
    if dt > 0.1 then return end
    local delta = self.base_level - self.level

    if math.abs(delta) < .025 then
        self.level = self.base_level
    else
        self.level = self.level + delta*dt*self.k
    end

    if self.base_level > 0 and not IsPaused() then
        self.time_since_pulse = self.time_since_pulse + dt
        if self.time_since_pulse > self.pulse_period then
            self.time_since_pulse = 0

            if not self.owner.components.health:IsDead() then
                TheInputProxy:AddVibration(VIBRATION_BLOOD_OVER, 0.2, 0.3, false)
            end
        end
    end

    if self.level > 0 then
        self:Show()
        self.bg:SetTint(1, 1, 1, self.level)
    else
        self:StopUpdating()
        self:Hide()
    end
end

function BoatOver:Flash()
    TheInputProxy:AddVibration(VIBRATION_BLOOD_FLASH, 0.2, 0.7, false)

    self:StartUpdating()
    self.level = 1
    self.k = 5 --larger # = quicker fade.
end

return BoatOver
