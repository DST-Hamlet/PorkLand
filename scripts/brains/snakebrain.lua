require("behaviours/attackwall")
require("behaviours/chaseandattack")
require("behaviours/doaction")
require("behaviours/faceentity")
require("behaviours/panic")
require("behaviours/standstill")
require("behaviours/wander")

local BrainCommon = require("brains/braincommon")

local SEE_DIST = 30

local function EatFoodAction(inst)
    local target = FindEntity(inst, SEE_DIST, function(item) return inst.components.eater:CanEat(item) and item:IsOnPassablePoint(true) end)
    return target ~= nil and BufferedAction(inst, target, ACTIONS.EAT) or nil
end

local function GetWanderPoint(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    local target = FindClosestPlayerInRange(x, y, z, 64, true)

    if target then
        return target:GetPosition()
    end
end

local SnakeBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

function SnakeBrain:OnStart()

    local root = PriorityNode(
    {
        BrainCommon.PanicTrigger(self.inst),

        ChaseAndAttack(self.inst, 8),

        DoAction(self.inst, EatFoodAction, "eat food", true ),

        Wander(self.inst, GetWanderPoint, 20),

    }, 0.25)

    self.bt = BT(self.inst, root)
end

return SnakeBrain
