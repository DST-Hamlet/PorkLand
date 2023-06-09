require "behaviours/wander"
require "behaviours/faceentity"
require "behaviours/chaseandattack"
require "behaviours/panic"
require "behaviours/follow"
require "behaviours/attackwall"
--require "behaviours/runaway"
--require "behaviours/doaction"

local STOP_RUN_DIST = 10
local SEE_PLAYER_DIST = 5
local WANDER_DIST = 20
local START_FACE_DIST = 4
local KEEP_FACE_DIST = 6

local SEE_FOOD_DIST = 10

local AVOID_PLAYER_DIST = 7
local AVOID_PLAYER_STOP = 9

local MAX_CHASE_TIME = 6

local MIN_FOLLOW_DIST = 1
local TARGET_FOLLOW_DIST = 5
local MAX_FOLLOW_DIST = 5

local SEE_PUDDLE_DIST = 15

local function getPuddle(inst)
    if not inst.puddle or inst.puddle.stage < 1 then
        local pt = Vector3(inst.Transform:GetWorldPosition())
        local ents = TheSim:FindEntities(pt.x,pt.y,pt.z, SEE_PUDDLE_DIST, {"sedimentpuddle"})

        local stage = -1
        local puddles = {}

        for i, ent in ipairs(ents) do
            if ent.stage and ent.stage >= stage then
                if ent.stage > stage then
                    puddles = {}
                    stage = ent.stage
                end
                table.insert(puddles,ent)
            end
        end
        local puddle = nil
        if #puddles > 0 then
            puddle = puddles[math.random(1,#puddles)]
            inst.puddle = puddle
        end
    end
    return inst.puddle
end

local function gethome(inst)
    getPuddle(inst)
    if inst.puddle then
        return Vector3( inst.puddle.Transform:GetWorldPosition() )
    else
        return Vector3( inst.Transform:GetWorldPosition() )
    end
end

local function drink(inst)
    getPuddle(inst)

    if inst.puddle and inst.puddle.stage > 0 then
        return BufferedAction(inst, inst.puddle, ACTIONS.SPECIAL_ACTION)
    end
end

local function poop(inst)
    if inst.goldlevel >= 1 then
        inst.goldlevel = inst.goldlevel -1
        return BufferedAction(inst, inst.puddle, ACTIONS.SPECIAL_ACTION2)
    end
end

local function EatFoodAction(inst)
    local notags = {"FX", "NOCLICK", "DECOR","INLIMBO", "aquatic"}
    local target = FindEntity(inst, SEE_FOOD_DIST, function(item) return inst.components.eater:CanEat(item) and item:IsOnValidGround() and item:GetTimeAlive() > TUNING.SPIDER_EAT_DELAY end, nil, notags)
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
        WhileNode(function() return not self.inst.sg:HasStateTag("ball") end, "Balled up",
            PriorityNode{
                WhileNode( function() return self.inst.components.health.takingfiredamage end, "OnFire", Panic(self.inst)),
                WhileNode( function() return self.inst.components.combat.target == nil end, "RunAway",
                    RunAway(self.inst, "scarytoprey", AVOID_PLAYER_DIST, AVOID_PLAYER_STOP)),
        		IfNode( function() return self.inst.components.combat.target ~= nil end, "hastarget", AttackWall(self.inst)),
                ChaseAndAttack(self.inst, MAX_CHASE_TIME),

                DoAction(self.inst, function() return poop(self.inst) end, "poop"),

                DoAction(self.inst, function() return EatFoodAction(self.inst) end, "eat"),

                DoAction(self.inst, function() return drink(self.inst) end, "drink"),

                Follow(self.inst, function() return self.inst.components.follower and self.inst.components.follower.leader end, MIN_FOLLOW_DIST, TARGET_FOLLOW_DIST, MAX_FOLLOW_DIST, false),
                Wander(self.inst, function() return gethome(self.inst) end, WANDER_DIST)
            }),
    }, .25)

    self.bt = BT(self.inst, root)

end

return Pangolden
