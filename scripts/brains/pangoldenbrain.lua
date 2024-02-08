require "behaviours/wander"
require "behaviours/faceentity"
require "behaviours/panic"
require "behaviours/follow"

local BrainCommon = require("brains/braincommon")

local WANDER_DIST = 20
local SEE_FOOD_DIST = 10
local AVOID_PLAYER_DIST = 7
local AVOID_PLAYER_STOP = 9
local SEE_PUDDLE_DIST = 15

local function get_puddle(inst)
    if inst.puddle and inst.puddle.stage >= 1 then
        return
    end

    local x, y, z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, SEE_PUDDLE_DIST, {"sedimentpuddle"})

    local stage = -1
    local puddles = {}

    for _, ent in ipairs(ents) do
        if ent.stage and ent.stage >= stage then
            if ent.stage > stage then
                puddles = {}
                stage = ent.stage
            end
            table.insert(puddles, ent)
        end
    end

    if #puddles > 0 then
        inst.puddle = puddles[math.random(1, #puddles)]
    end

    return inst.puddle -- a pointless return?
end

local function get_home(inst)
    get_puddle(inst)

    if inst.puddle then
        return Vector3(inst.puddle.Transform:GetWorldPosition())
    else
        return Vector3(inst.Transform:GetWorldPosition())
    end
end

local function DrinkAction(inst)
    get_puddle(inst)

    if inst.puddle and inst.puddle.stage > 0 then
        return BufferedAction(inst, inst.puddle, ACTIONS.SPECIAL_ACTION)
    end
end

local function PoopAction(inst)
    if inst.goldlevel >= 1 then
        inst.goldlevel = inst.goldlevel -1
        return BufferedAction(inst, inst.puddle, ACTIONS.SPECIAL_ACTION2)
    end
end

local function EatFoodAction(inst)
    local notags = {"FX", "NOCLICK", "DECOR","INLIMBO", "aquatic"}
    local target = FindEntity(inst, SEE_FOOD_DIST, function(item)
            return inst.components.eater:CanEat(item) and item:IsOnValidGround() and item:GetTimeAlive() > TUNING.SPIDER_EAT_DELAY
        end, nil, notags)

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

                Wander(self.inst, function() return get_home(self.inst) end, WANDER_DIST)
            }),
    }, 0.25)

    self.bt = BT(self.inst, root)
end

return Pangolden
