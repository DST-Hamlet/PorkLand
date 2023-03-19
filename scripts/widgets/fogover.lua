local Widget = require("widgets/widget")
local Image = require("widgets/image")

local FogOver = Class(Widget, function(self, owner)
    Widget._ctor(self, "FogOver")

    self.owner = owner

    self:SetClickable(false)

    self.bg2 = self:AddChild(Image("images/overlays/fx5.xml", "fog_over.tex"))
    self.bg2:SetVRegPoint(ANCHOR_MIDDLE)
    self.bg2:SetHRegPoint(ANCHOR_MIDDLE)
    self.bg2:SetVAnchor(ANCHOR_MIDDLE)
    self.bg2:SetHAnchor(ANCHOR_MIDDLE)
    self.bg2:SetScaleMode(SCALEMODE_FILLSCREEN)

    self.alpha = 0
    self.alphagoal = 0
    self.transitiontime = 2.0
    self.time = self.transitiontime

    self:Hide()
end)

function FogOver:StartFog()
    if not self.foggy then
        self.foggy = true

        self.time = self.transitiontime
        self.alphagoal = 1

        self:StartUpdating()
        self:Show()
    end
end

function FogOver:SetFog(off)
    if off and self.foggy then
        self.time = 0
        self.alphagoal = 0
        self.foggy = false
        self.alpha = 0
        self:StopUpdating()
        self:Hide()
    elseif not self.foggy then
        self.time = 0
        self.alphagoal = 1
        self.foggy = true
        self.alpha = 1
        self:StartUpdating()
        self:Show()
    end
end

function FogOver:StopFog()
    if self.foggy then
        self.time = self.transitiontime
        self.alphagoal = 0
        self.foggy = false
    end
end

function FogOver:UpdateAlpha(dt)
    if self.alphagoal ~= self.alpha then
        if self.time > 0 then
            self.time = math.max(0, self.time - dt)
            if self.alphagoal < self.alpha then
                self.alpha = Remap(self.time, self.transitiontime, 0, 1, 0)
            else
                self.alpha = Remap(self.time, self.transitiontime, 0, 0, 1)
            end
        end
    end
end

function FogOver:OnUpdate(dt)
    self:UpdateAlpha(dt)

    if self.owner.replica.inventory:EquipHasTag("clearfog") then -- or TheCamera.interior
        self:Hide()
    else
        self:Show()
    end

    local x, y, z = 0, 0, 0
    if TheWorld.components.ambientlighting then
        x, y, z = TheWorld.components.ambientlighting:GetRealColour()
    end

    x = math.min(x * 1.5, 1)
    y = math.min(y * 1.5, 1)
    z = math.min(z * 1.5, 1)

    self.bg2:SetTint(x, y, z, self.alpha)

    if self.alpha == 0 and self.alphagoal == 0 then
        self:Hide()
        self:StopUpdating()
    end
end

return FogOver
