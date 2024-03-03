require("behaviours/wander")
require("behaviours/panic")
require("behaviours/chaseandattack")

local BrainCommon = require("brains/braincommon")

local MAX_WANDER_DIST = 20
local MAX_CHASE_TIME = 10
local SEE_FOOD_DIST = 50
local SEE_PLAYER_DIST = 5

local function IsBillFood(item)
    return item:HasTag("billfood")
end

local function EatFoodAction(inst)
    local target = FindEntity(inst, SEE_FOOD_DIST, function(item) return IsBillFood(item) end)

    if target then
        return BufferedAction(inst, target, ACTIONS.EAT)
    end
end

local PICK_LOTUS_MUST_TAGS = {"lotus"}
local function PickLotusAction(inst)
    local target = FindEntity(inst, SEE_FOOD_DIST, function(item)
        return item.components.pickable and item.components.pickable:CanBePicked()
    end, PICK_LOTUS_MUST_TAGS)

    -- check for scary things near the lotus
    if target then
        local predator = GetClosestInstWithTag("scarytoprey", target, SEE_PLAYER_DIST)
        if predator then return end
    end

    if target then
        return BufferedAction(inst, target, ACTIONS.PICK)
    end
end

local BillBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

function BillBrain:OnStart()
    local root = PriorityNode(
    {
        BrainCommon.PanicTrigger(self.inst),

        ChaseAndAttack(self.inst, MAX_CHASE_TIME),

        DoAction(self.inst, function() return EatFoodAction(self.inst) end),

        DoAction(self.inst, PickLotusAction, "Pick Lotus", true),

        Wander(self.inst, function() return self.inst.components.knownlocations:GetLocation("home") end, MAX_WANDER_DIST)

    }, 0.25)

    self.bt = BT(self.inst, root)
end

return BillBrain
