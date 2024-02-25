require("behaviours/wander")
require("behaviours/faceentity")
require("behaviours/panic")
require("behaviours/follow")

local BrainCommon = require("brains/braincommon")

local WANDER_DIST = 20
local SEE_FOOD_DIST = 10
local AVOID_PLAYER_DIST = 7
local AVOID_PLAYER_STOP = 9
local SEE_PUDDLE_DIST = 15

local MUST_TAGS = {"sedimentpuddle"}
local function GetPuddle(inst, test_fn)
    return FindEntity(inst, SEE_FOOD_DIST, test_fn, MUST_TAGS)
end

local function GetHome(inst)
    local puddle = GetPuddle(inst)
    return puddle and puddle:GetPosition()
end

local function DrinkAction(inst)
    local puddle = GetPuddle(inst, function(item)
        return item.components.workable:CanBeWorked()
    end)

    if puddle then
        return BufferedAction(inst, puddle, ACTIONS.PANGOLDEN_DRINK)
    end
end

local function PoopAction(inst)
    if inst.gold_level >= 1 then
        inst.gold_level = inst.gold_level - 1
        return BufferedAction(inst, inst, ACTIONS.PANGOLDEN_POOP)
    end
end

local CANT_TAGS = {"FX", "NOCLICK", "DECOR", "INLIMBO"}
local function EatFoodAction(inst)
    local target = FindEntity(inst, SEE_FOOD_DIST, function(item)
        return inst.components.eater:CanEat(item) and item:IsOnValidGround() and item:GetTimeAlive() > TUNING.SPIDER_EAT_DELAY
    end, nil, CANT_TAGS)

    if target then
        return BufferedAction(inst, target, ACTIONS.EAT)
    end
end

local Pangolden = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

function Pangolden:OnStart()
    local root = PriorityNode(
    {
        WhileNode(function() return not self.inst.sg:HasStateTag("ball") end, "BalledUp",
            PriorityNode{
                BrainCommon.PanicTrigger(self.inst),
                RunAway(self.inst, "scarytoprey", AVOID_PLAYER_DIST, AVOID_PLAYER_STOP),
                DoAction(self.inst, function() return PoopAction(self.inst) end, "Poop"),
                DoAction(self.inst, function() return EatFoodAction(self.inst) end, "Eat"),
                DoAction(self.inst, function() return DrinkAction(self.inst) end, "Drink"),
                Wander(self.inst, function() return GetHome(self.inst) end, WANDER_DIST)
            }),
    }, 0.25)

    self.bt = BT(self.inst, root)
end

return Pangolden
