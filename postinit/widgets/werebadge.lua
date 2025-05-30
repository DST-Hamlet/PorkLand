local AddClassPostConstruct = AddClassPostConstruct
GLOBAL.setfenv(1, GLOBAL)

local WereBadge = require("widgets/werebadge")

local _UpdateArrow = WereBadge.UpdateArrow
function WereBadge:UpdateArrow(...)
    local anim = "neutral"
    if self.val > 0 and self.owner.GetWerenessDrainRate ~= nil then
        local rate = self.owner:GetWerenessDrainRate()
        if rate < 0 then
            return _UpdateArrow(self, ...)
        end
        if rate > 5 then
            anim = "arrow_loop_increase_most"
        elseif rate > -.5 then
            anim = "arrow_loop_increase_more"
        elseif rate > 0 then
            anim = "arrow_loop_increase"
        end
    end
    if self.arrowdir ~= anim then
        self.arrowdir = anim
        self.sanityarrow:GetAnimState():PlayAnimation(anim, true)
    end
end

local _SetPercent = WereBadge.SetPercent
function WereBadge:SetPercent(val, ...)
    return _SetPercent(self, math.min(val, 1), ...)
end
