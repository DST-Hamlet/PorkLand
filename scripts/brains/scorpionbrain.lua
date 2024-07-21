require("behaviours/chaseandattack")
require("behaviours/runaway")
require("behaviours/wander")
require("behaviours/doaction")
require("behaviours/panic")
require("behaviours/attackwall")

local BrainCommon = require("brains/braincommon")

local SEE_FOOD_DIST = 10

local MAX_CHASE_TIME = 8
local MAX_WANDER_DIST = 32

local EAT_FOOD_NO_TAGS = {"FX", "NOCLICK", "DECOR", "INLIMBO", "aquatic"}

local function EatFoodAction(inst)
    local target = FindEntity(inst, SEE_FOOD_DIST, function(item)
        return inst.components.eater:CanEat(item)
            and item:IsOnValidGround()
            and item:GetTimeAlive() > TUNING.SPIDER_EAT_DELAY
        end, nil, EAT_FOOD_NO_TAGS)

    if target then
        return BufferedAction(inst, target, ACTIONS.EAT)
    end
end

local ScorpionBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

function ScorpionBrain:OnStart()
    local root = PriorityNode(
    {
        BrainCommon.PanicTrigger(self.inst),

        WhileNode(function() return not self.inst.sg:HasStateTag("evade") end, "Not Evading",
            PriorityNode({
                AttackWall(self.inst),

                ChaseAndAttack(self.inst, MAX_CHASE_TIME),

                DoAction(self.inst, EatFoodAction, "Eat Food"),

                Wander(self.inst, function() return self.inst.components.knownlocations:GetLocation("home") end, MAX_WANDER_DIST)
            }, 1)
        )
    }, 1)

    self.bt = BT(self.inst, root)
end

function ScorpionBrain:OnInitializationComplete()
    self.inst.components.knownlocations:RememberLocation("home", self.inst:GetPosition(), true)
end

return ScorpionBrain
