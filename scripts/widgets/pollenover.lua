local Widget = require("widgets/widget")
local Image = require("widgets/image")

local PollenOver = Class(Widget, function(self, owner)
    Widget._ctor(self, "PollenOver")

    self.owner = owner

    self:SetClickable(false)

    self.bg = self:AddChild(Image("images/overlays/fx4.xml", "pollen_over.tex"))

    self.bg:SetVRegPoint(ANCHOR_MIDDLE)
    self.bg:SetHRegPoint(ANCHOR_MIDDLE)
    self.bg:SetVAnchor(ANCHOR_MIDDLE)
    self.bg:SetHAnchor(ANCHOR_MIDDLE)
    self.bg:SetScaleMode(SCALEMODE_FILLSCREEN)

    self.bg2 = self:AddChild(Image("images/overlays/fx4.xml", "pollen_over2.tex"))
    self.bg2:SetVRegPoint(ANCHOR_MIDDLE)
    self.bg2:SetHRegPoint(ANCHOR_MIDDLE)
    self.bg2:SetVAnchor(ANCHOR_MIDDLE)
    self.bg2:SetHAnchor(ANCHOR_MIDDLE)
    self.bg2:SetScaleMode(SCALEMODE_FILLSCREEN)

    self.level = 0

    self.sneezethreshhold = 2

    self.mainline = 1
    self.startline = 60

    self.lastsneezetime = 9999

    self.sneezecountdown = 1

    self.level2 = 0

    self:Hide()
end)

function PollenOver:UpdateState(sneezetime)
    self.lastsneezetime = sneezetime
    if self.lastsneezetime and self.lastsneezetime < 120 then
        self:StartUpdating()
    end
end

function PollenOver:OnUpdate(dt)
    local leveltarget = self.level

    -- PLAYER IS CLOSE TO SNEEZING
    if self.lastsneezetime and self.lastsneezetime <= self.sneezethreshhold then

        if not self.sneezecountdown then  -- self.lastsneezetime == self.sneezethreshhold then
           self.sneezecountdown = self.sneezethreshhold
        end

        self.level2 = (1 - 0.025) * (1 - self.lastsneezetime / self.sneezethreshhold)

    -- PLAYER's HUD IS GETTING ITCHY
    elseif self.lastsneezetime and self.lastsneezetime < self.startline then
        self.level2 = 0
        self.sneezecountdown = nil
        -- FADE FROM 0 to FULL for half the time then sit at full.
        if self.lastsneezetime > self.startline / 2 then
            leveltarget = 1 - ( (self.lastsneezetime - self.startline / 2) / (self.startline/2) ) - 0.025
        else
            leveltarget = 1 - 0.025
        end
    else
        self.level2 = 0
        leveltarget = 0
    end

    if leveltarget < self.level then
        self.level = math.max(leveltarget, self.level - 0.01)
    else
        self.level = leveltarget
    end

    -- if TheCamera.interior then
    --     self.level = self.level * 0.3
    -- end

    -- add some noise
    if self.level > 0 then
        self.level = math.min(1, math.max(0.001, self.level + math.random() * .05 - 0.025))
    end

    if self.level2 > 0 then
        self.level2 = math.min(1, math.max(0.001, self.level2 + math.random() * .05 - 0.025))
    end

    if self.level > 0 or self.level2 > 0 then
        self:Show()
        self.bg:SetTint(1, 1, 1, self.level)
        self.bg2:SetTint(1, 1, 1, self.level2)
    else
        self:Hide()
        self:StopUpdating()
    end
end

return PollenOver
