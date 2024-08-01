local Widget = require("widgets/widget")

local STATES = {
    IN = 1,
    OUT = 2
}

local TRANSITION_TIME_IN = 0.2
local TRANSITION_TIME_OUT = 5

local BatSonar = Class(Widget, function(self, owner)
    self.owner = owner
    Widget._ctor(self, "BatSonar")
    self:SetClickable(false)

    self.bg2 = self:AddChild(Image("images/fx5.xml", "fog_over.tex"))
    self.bg2:SetVRegPoint(ANCHOR_MIDDLE)
    self.bg2:SetHRegPoint(ANCHOR_MIDDLE)
    self.bg2:SetVAnchor(ANCHOR_MIDDLE)
    self.bg2:SetHAnchor(ANCHOR_MIDDLE)
    self.bg2:SetScaleMode(SCALEMODE_FILLSCREEN)

    self.alpha = 0
    self.alphagoal = 0

    self.transitiontime = 2.0
    self.time = TRANSITION_TIME_IN
    self.currentstate = STATES.OUT

    self:Hide()
end)

function BatSonar:StartSonar()
    if not self.active then
        self.time = TRANSITION_TIME_IN
        self.alphagoal = 1
        self.active = true
        self:StartUpdating()
        self:Show()
    end
end

function BatSonar:SetSonar(off)
    if off and self.active then
        self.time = 0
        self.alphagoal = 0
        self.active = false
        self.alpha = 0
        self:StopUpdating()
        self:Hide()
    else
        if not self.active then
            self.time = 0
            self.alphagoal = 1
            self.active = true
            self.alpha = 1
            self:StartUpdating()
            self:Show()
        end
    end
end

function BatSonar:StopSonar()
    if self.active then
        self.time = self.transitiontime
        self.alphagoal = 0
        self.active = false
        self:StopUpdating()
        self:Hide()
    end
end

function BatSonar:UpdateAlpha(dt)
    if self.time > 0 then
        self.time = math.max(0, self.time - dt)
    else
        if self.currentstate == STATES.OUT then
            TheFocalPoint.SoundEmitter:PlaySound("dontstarve_DLC003/common/crafted/batmask/sonar")
            local ring = SpawnPrefab("batsonar_fx")
            ring.Transform:SetPosition(self.owner.Transform:GetWorldPosition())

            self.owner:DoTaskInTime(0.1, function()
                if self.active then
                    local ring2 = SpawnPrefab("batsonar_fx")
                    ring2.Transform:SetPosition(self.owner.Transform:GetWorldPosition())
                end
            end)

            self.currentstate = STATES.IN
            self.alphagoal = 0
            self.time = TRANSITION_TIME_IN
        elseif self.currentstate == STATES.IN then
            self.currentstate = STATES.OUT
            self.alphagoal = 1
            self.time = TRANSITION_TIME_OUT
        end
    end

    local mapping = 0
    if self.currentstate == STATES.OUT then
        mapping = Remap(self.time, TRANSITION_TIME_OUT, 0, 0, 1)
    elseif self.currentstate == STATES.IN then
        mapping = Remap(self.time, TRANSITION_TIME_IN, 0, 1, 0)
    end
    self.alpha = mapping
end

function BatSonar:OnUpdate(dt)
    if not IsPaused() then
        local wearing_bathat = self.owner.replica.inventory:EquipHasTag("bat_hat")

        if wearing_bathat then
            self:UpdateAlpha(dt)
        end

        self.bg2:SetTint(0, 0, 0, self.alpha)
    end
end

return BatSonar
