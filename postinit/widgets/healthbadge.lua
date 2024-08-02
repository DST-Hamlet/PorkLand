local AddClassPostConstruct = AddClassPostConstruct
GLOBAL.setfenv(1, GLOBAL)

local UIAnim = require("widgets/uianim")

----------------------------------------------------------------------------------------
local HealthBadge = require("widgets/healthbadge")

local _OnUpdate = HealthBadge.OnUpdate
function HealthBadge:OnUpdate(...)
    _OnUpdate(self, ...)

    local poison = self.owner.ispoisoned or (self.owner.player_classified and self.owner.player_classified.ispoisoned:value())

    if self.poison ~= poison then
        self.poison = poison
        if poison then
            self.poisonanim:GetAnimState():PlayAnimation("activate")
            self.poisonanim:GetAnimState():PushAnimation("idle", true)
            self.poisonanim:Show()
        else
            TheFocalPoint.SoundEmitter:PlaySound("dontstarve_DLC002/common/HUD_antivenom_use")
            self.poisonanim:GetAnimState():PlayAnimation("deactivate")
        end
    end
end

local WandaHealthBadge = require("widgets/wandaagebadge")

local _OnUpdate = WandaHealthBadge.OnUpdate
function WandaHealthBadge:OnUpdate(...)
    _OnUpdate(self, ...)

    local poison = self.owner.ispoisoned or (self.owner.player_classified and self.owner.player_classified.ispoisoned:value())

    if self.poison ~= poison then
        self.poison = poison
        if poison then
            self.poisonanim:GetAnimState():PlayAnimation("activate")
            self.poisonanim:GetAnimState():PushAnimation("idle", true)
            self.poisonanim:Show()
        else
            TheFocalPoint.SoundEmitter:PlaySound("dontstarve_DLC002/common/HUD_antivenom_use")
            self.poisonanim:GetAnimState():PlayAnimation("deactivate")
        end
    end
end

----------------------------------------------------------------------------------------
--Try to initialise all functions locally outside of the post-init so they exist in RAM only once
----------------------------------------------------------------------------------------
local function widgethealth(widget)
        widget.poisonanim = widget.underNumber:AddChild(UIAnim())
    widget.poisonanim:GetAnimState():SetBank("poison")
    widget.poisonanim:GetAnimState():SetBuild("poison_meter_overlay")
    widget.poisonanim:GetAnimState():PlayAnimation("deactivate")
    widget.poisonanim:GetAnimState():AnimateWhilePaused(false)
    widget.poisonanim:Hide()
    widget.poisonanim:SetClickable(false)
    widget.poison = false -- So it doesn't trigger on load
end

AddClassPostConstruct("widgets/healthbadge", widgethealth)
AddClassPostConstruct("widgets/wandaagebadge", widgethealth)
