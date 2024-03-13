require("behaviours/wander")
require("behaviours/chaseandattack")
require("behaviours/panic")
require("behaviours/attackwall")
require("behaviours/minperiod")
require("behaviours/faceentity")
require("behaviours/doaction")
require("behaviours/standstill")

local BrainCommon = require("brains/braincommon")

local SEE_FOOD_DIST = 30
local EAT_FOOD_NO_TAGS = {"INLIMBO", "irreplaceable", "outofreach", "smolder", "FX", "NOCLICK", "DECOR", "aquatic"}

local function EatFoodAction(inst)
    if inst.sg:HasStateTag("busy") then
        return
    end

    local target = FindEntity(inst, SEE_FOOD_DIST, function(item)
        return inst.components.eater:CanEat(item)
            and item:IsOnValidGround()
            and item:GetTimeAlive() > TUNING.SPIDER_EAT_DELAY
    end, nil, EAT_FOOD_NO_TAGS)

    if target then
        return BufferedAction(inst, target, ACTIONS.EAT)
    end
end

local FlytrapBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

function FlytrapBrain:OnStart()
    local root = PriorityNode(
    {
        BrainCommon.PanicTrigger(self.inst),

        DoAction(self.inst, function() return EatFoodAction(self.inst) end ),

        ChaseAndAttack(self.inst, 10),

        StandStill(self.inst),
    }, 0.25)

    self.bt = BT(self.inst, root)
end

return FlytrapBrain
