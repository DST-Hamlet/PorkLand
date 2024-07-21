require("behaviours/attackwall")
require("behaviours/chaseandattack")
require("behaviours/leash")
require("behaviours/panic")

local BrainCommon = require("brains/braincommon")

local MAX_CHASE_TIME = 60
local MAX_CHASE_DIST = 40

local function GetWanderPos(inst)
    return inst.components.teamattacker.teamleader == nil and inst.components.knownlocations:GetLocation("home")
end

local VampireBatBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

function VampireBatBrain:OnStart()
    local root = PriorityNode(
    {
        WhileNode(
            function() return not self.inst.sg:HasStateTag("flight") end, "AttackAndWander",
            PriorityNode(
            {
                BrainCommon.PanicTrigger(self.inst),

                ChaseAndAttack(self.inst, MAX_CHASE_TIME, MAX_CHASE_DIST),

                Wander(self.inst, GetWanderPos, 8),
            }, 0.25)
        )
    })

    self.bt = BT(self.inst, root)
end

function VampireBatBrain:OnInitializationComplete()
    self.inst.components.knownlocations:RememberLocation("home", self.inst:GetPosition(), true)
end

return VampireBatBrain
