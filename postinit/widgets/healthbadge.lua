local AddClassPostConstruct = AddClassPostConstruct
GLOBAL.setfenv(1, GLOBAL)

local UIAnim = require("widgets/uianim")

----------------------------------------------------------------------------------------
local HealthBadge = require("widgets/healthbadge")

local _OnUpdate = HealthBadge.OnUpdate
function HealthBadge:OnUpdate(...)
    _OnUpdate(self, ...)

    local poison = self.owner.ispoisoned or (self.owner.player_classified and self.owner.player_classified.ispoisoned:value())
    local in_gas = self.owner.isingas or (self.owner.player_classified and self.owner.player_classified.isingas:value())

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

    local anim = "neutral"

    if self.arrowdir ~= "arrow_loop_decrease_more" and self.arrowdir ~= "arrow_loop_decrease_most" then
        if self.poison then
            anim = "arrow_loop_decrease_more"
            self.sanityarrow:GetAnimState():PlayAnimation("neutral")
        end
    end

    if self.arrowdir ~= "arrow_loop_decrease_most" then
        if in_gas then
            anim = "arrow_loop_decrease_most"
            self.sanityarrow:GetAnimState():PlayAnimation("neutral")
        end
    end

    if self.arrowdir_pl ~= anim then
        self.arrowdir_pl = anim
        self.sanityarrow_pl:GetAnimState():PlayAnimation(anim, true)
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
    if widget.sanityarrow then
        widget.sanityarrow_pl = widget.underNumber:AddChild(UIAnim())
        widget.sanityarrow_pl:GetAnimState():SetBank("sanity_arrow")
        widget.sanityarrow_pl:GetAnimState():SetBuild("sanity_arrow")
        widget.sanityarrow_pl:GetAnimState():PlayAnimation("neutral")
        widget.sanityarrow_pl:SetClickable(false)
        widget.sanityarrow_pl:GetAnimState():AnimateWhilePaused(false)
    end
end

AddClassPostConstruct("widgets/healthbadge", widgethealth)
AddClassPostConstruct("widgets/wandaagebadge", widgethealth)
