local PLENV = env
GLOBAL.setfenv(1, GLOBAL)

local FishingRod = require("components/fishingrod")

local _StartFishing = FishingRod.StartFishing
function FishingRod:StartFishing(target, fisherman)
    _StartFishing(self, target, fisherman)
    if target ~= nil and (target.components.workable
      and target.components.workable:GetWorkAction() == ACTIONS.FISH
      and target.components.workable:CanBeWorked()) then
        self.target = target
        self.fisherman = fisherman
    end
end

function FishingRod:Retrieve()
    local numworks = 1
    if self.fisherman and self.fisherman.components.worker then
        numworks = self.fisherman.components.worker:GetEffectiveness(ACTIONS.FISH)
    end
    if self.target and self.target.components.workable then
        self.target.components.workable:WorkedBy(self.fisherman, numworks)
        self.inst:PushEvent("fishingcollect")
        self.target:PushEvent("fishingcollect")
        self:StopFishing()
    end
end
