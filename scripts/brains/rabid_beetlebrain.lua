require("behaviours/wander")
require("behaviours/chaseandattack")
require("behaviours/panic")
require("behaviours/attackwall")
require("behaviours/minperiod")
require("behaviours/leash")
require("behaviours/faceentity")
require("behaviours/doaction")
require("behaviours/standstill")

local BrainCommon = require("brains/braincommon")

local SEE_DIST = 30

local function EatFoodAction(inst)
    local target = FindEntity(inst, SEE_DIST, function(item)
        return inst.components.eater:CanEat(item) and item:IsOnPassablePoint()
    end)
    if target then
        return BufferedAction(inst, target, ACTIONS.EAT)
    end
end

local function GetWanderPoint(inst)
    local target = inst:GetNearestPlayer(true)
    return target and target:GetPosition() or nil
end

local Rabid_Beetle_Brain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

function Rabid_Beetle_Brain:OnStart()

    local root = PriorityNode(
    {
        WhileNode(
            function() return not self.inst.sg:HasStateTag("jumping") end, "AttackAndWander",
            PriorityNode(
            {
                BrainCommon.PanicTrigger(self.inst),
                AttackWall(self.inst),
                ChaseAndAttack(self.inst, 100),
                DoAction(self.inst, EatFoodAction, "eat food", true),
                Wander(self.inst, GetWanderPoint, 20),
            }, .25)
        )
    }, .25)

    self.bt = BT(self.inst, root)
end

return Rabid_Beetle_Brain
