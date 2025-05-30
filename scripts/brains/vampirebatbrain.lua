require("behaviours/attackwall")
require("behaviours/chaseandattack")
require("behaviours/leash")
require("behaviours/panic")
require("behaviours/followpoint")

local BrainCommon = require("brains/braincommon")

local MAX_CHASE_TIME = 60
local MAX_CHASE_DIST = 40

local function GetWanderPos(inst)
    return inst.components.knownlocations:GetLocation("home")
end

local function GetStandOffPoint(inst)
    local pos = inst.components.teamcombat:GetStandOffPoint()
    if pos then
        return pos
    end
end

local VampireBatBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

function VampireBatBrain:OnStart()
    local root = PriorityNode(
    {
        WhileNode(
            function() return not self.inst.sg:HasStateTag("flight") end, "not Flight",
            PriorityNode(
            {
                BrainCommon.PanicTrigger(self.inst),

                WhileNode(function() return self.inst.components.teamcombat:CanAttack() end, "Attack",
                    ChaseAndAttack(self.inst, MAX_CHASE_TIME, MAX_CHASE_DIST)),

                FollowPoint(self.inst, GetStandOffPoint, nil, nil, true),

                Wander(self.inst, GetWanderPos, 8),
            }, 0.1)
        )
    })

    self.bt = BT(self.inst, root)
end

function VampireBatBrain:OnInitializationComplete()
    self.inst.components.knownlocations:RememberLocation("home", self.inst:GetPosition(), true)
end

return VampireBatBrain
