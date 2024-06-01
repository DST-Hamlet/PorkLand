require("behaviours/standandattack")

local AdultFlytrapBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

function AdultFlytrapBrain:OnStart()
    local root = PriorityNode(
    {
        StandAndAttack(self.inst),
    }, 0.25)

    self.bt = BT(self.inst, root)
end

return AdultFlytrapBrain
