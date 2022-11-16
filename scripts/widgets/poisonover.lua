local Widget = require("widgets/widget")
local Image = require("widgets/image")
local easing = require("easing")

local PoisonOver =  Class(Widget, function(self, owner)
    Widget._ctor(self, "PoisonOver")

    self.owner = owner

    self:SetClickable(false)

    self.bg = self:AddChild(Image("images/overlays/fx3.xml", "poison_over.tex"))
    self.bg:SetVRegPoint(ANCHOR_MIDDLE)
    self.bg:SetHRegPoint(ANCHOR_MIDDLE)
    self.bg:SetVAnchor(ANCHOR_MIDDLE)
    self.bg:SetHAnchor(ANCHOR_MIDDLE)
    self.bg:SetScaleMode(SCALEMODE_FILLSCREEN)

    self.dir = 0
    self.base_level = 0
    self.level = 0
    self.target_level = 0
    self.fade_in_duration = .4
    self.fade_out_duration = .6
    self.flash_time = 0
    self.k = 1
    self.time_since_pulse = 0
    self.pulse_period = 1

    self.inst:ListenForEvent("poisondamage", function(inst, data)
        return self:Flash() end,
    owner)

    self.inst:DoTaskInTime(0, function()
        self.base_level = 0
        self.k = 5
        self:OnUpdate(0)
    end)

    self:Hide()
end)

function PoisonOver:TurnOn()
    -- TheInputProxy:AddVibration(VIBRATION_BLOOD_FLASH, .2, .7, true)
    self:StartUpdating()
    self.base_level = .5
    self.k = 5
    self.time_since_pulse = 0
end

function PoisonOver:TurnOff()
    self.base_level = 0
    self.k = 5
    self:OnUpdate(0)
    self.flashing = false
end

function PoisonOver:OnUpdate(dt)
    -- ignore abnormally large intervals as they will destabilize the math in here
    if dt > 0.1 then
        return
    end

    local delta = self.target_level - self.base_level

    if math.abs(delta) < .025 then
        self.level = self.base_level
    else
        if self.dir > 0 then
            self.level = easing.inQuad(GetTime()-self.flash_time, 0, 1, self.fade_in_duration)
        else
            self.level = easing.inQuad(GetTime()-self.flash_time, 1, -1, self.fade_out_duration)
            -- self.level = self.level + delta*dt*self.k --old math
        end
    end

    if self.level > 1 then
        self.level = 1
    end

    if self.level < 0 then
        self.level = 0
    end

    if self.flashing and self.level >= 1 and self.dir > 0 then
        self.dir = -self.dir
        self.flash_time = GetTime()
    end

    if self.base_level > 0 and not IsPaused() then
        self.time_since_pulse = self.time_since_pulse + dt
        if self.time_since_pulse > self.pulse_period then
            self.time_since_pulse = 0

            -- if not self.owner.components.health:IsDead() then
            --     TheInputProxy:AddVibration(VIBRATION_BLOOD_OVER, .2, .3, false)
            -- end
        end
    end

    if GetTime() - self.flash_time > self.fade_out_duration and self.dir < 0 then
        self:StopUpdating()
        self:Hide()
        self.flashing = false
    else
        self:Show()
        self.bg:SetTint(1,1,1,self.level)
    end
end

function PoisonOver:Flash()
    -- TheInputProxy:AddVibration(VIBRATION_BLOOD_FLASH, .2, .7, false)

    self:StartUpdating()
    self.flashing = true
    self.base_level = 0
    self.level = 0
    self.target_level = 1
    self.k = .5
    self.dir = 1
    self.flash_time = GetTime()
end

return PoisonOver
