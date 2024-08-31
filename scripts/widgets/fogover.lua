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

    self:StartUpdating()
end)

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
if TheWorld.state.fogstate == FOG_STATE.FOGGY then
        if self.alphagoal ~= 1 then
            self.alphagoal = 1
            self.time = 2
        end
    else
        if self.alphagoal ~= 0 then
            self.alphagoal = 0
            self.time = 2
        end
    end

    self:UpdateAlpha(dt)

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
    else
        self:Show()
    end

    if self.owner.replica.inventory:EquipHasTag("clearfog") or self.owner:HasTag("inside_interior") then
        self:Hide()
    else
        self:Show()
    end
end

return FogOver
