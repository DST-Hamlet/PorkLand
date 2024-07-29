GLOBAL.setfenv(1, GLOBAL)

local FishingRod = require("components/fishingrod")

local _StartFishing = FishingRod.StartFishing
function FishingRod:StartFishing(target, fisherman)
    _StartFishing(self, target, fisherman)
    if target ~= nil and (target.components.inventoryitem
      and target.components.inventoryitem.canbefishedup) then
        self.target = target
        self.fisherman = fisherman
        self.inst:StartUpdatingComponent(self)
    end
end

function FishingRod:Retrieve()
    if self.target and self.target.components.inventoryitem and self.target.components.inventoryitem.canbepickedup then
        self.inst:PushEvent("fishingcollect")
        self.target:PushEvent("fishingcollect", self.fisherman)
    end
    self.target = nil
    self:StopFishing()
end
