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
    elseif target ~= nil and target:HasTag("sunkencontainer") then
        self.target = target
        self.fisherman = fisherman
        self.inst:StartUpdatingComponent(self)
    end
end

function FishingRod:Retrieve()
    self.target = nil
    self:StopFishing()
end
