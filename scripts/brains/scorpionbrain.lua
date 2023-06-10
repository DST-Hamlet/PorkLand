require "behaviours/chaseandattack"
require "behaviours/runaway"
require "behaviours/wander"
require "behaviours/doaction"
require "behaviours/avoidlight"
require "behaviours/panic"
require "behaviours/attackwall"
require "behaviours/useshield"

local RUN_AWAY_DIST = 10
local SEE_FOOD_DIST = 10
local SEE_TARGET_DIST = 6

local MIN_FOLLOW_DIST = 2
local TARGET_FOLLOW_DIST = 3
local MAX_FOLLOW_DIST = 8

local TRADE_DIST = 20

local MAX_CHASE_DIST = 7
local MAX_CHASE_TIME = 8
local MAX_WANDER_DIST = 32

local START_RUN_DIST = 8
local STOP_RUN_DIST = 12

local DAMAGE_UNTIL_SHIELD = 50
local SHIELD_TIME = 3
local AVOID_PROJECTILE_ATTACKS = false

local ScorpionBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

local function GetTraderFn(inst)
    if inst.components.trader then
        return FindEntity(inst, TRADE_DIST, function(target) return inst.components.trader:IsTryingToTradeWithMe(target) end, {"player"})
    end
end

local function KeepTraderFn(inst, target)
    if inst.components.trader then
        return inst.components.trader:IsTryingToTradeWithMe(target)
    end
end

local function EatFoodAction(inst)
    local notags = {"FX", "NOCLICK", "DECOR","INLIMBO", "aquatic"}
    local target = FindEntity(inst, SEE_FOOD_DIST, function(item) return inst.components.eater:CanEat(item) and item:IsOnValidGround() and item:GetTimeAlive() > TUNING.SPIDER_EAT_DELAY end, nil, notags)
    if target then
        return BufferedAction(inst, target, ACTIONS.EAT)
    end
end

local function GoHomeAction(inst)
    if inst.components.homeseeker and
       inst.components.homeseeker.home and
       inst.components.homeseeker.home:IsValid() and
       inst.components.homeseeker.home.components.childspawner and
       not inst.components.homeseeker.home.components.health:IsDead() then
        return BufferedAction(inst, inst.components.homeseeker.home, ACTIONS.GOHOME)
    end
end

local function InvestigateAction(inst)
    local investigatePos = inst.components.knownlocations and inst.components.knownlocations:GetLocation("investigate")
    if investigatePos then
        return BufferedAction(inst, nil, ACTIONS.INVESTIGATE, nil, investigatePos, nil, 1)
    end
end

local function GetFaceTargetFn(inst)
    return inst.components.follower.leader
end

local function KeepFaceTargetFn(inst, target)
    return inst.components.follower.leader == target
end

function ScorpionBrain:OnStart()
    local root =
        PriorityNode(
        {
            WhileNode( function() return self.inst.components.health.takingfiredamage end, "OnFire", Panic(self.inst)),
            IfNode(function() return self.inst:HasTag("spider_hider") end, "IsHider",
                UseShield(self.inst, DAMAGE_UNTIL_SHIELD, SHIELD_TIME, AVOID_PROJECTILE_ATTACKS)),

            WhileNode( function() return not self.inst.sg:HasStateTag("evade") end, "test",
                PriorityNode(
                {
                    AttackWall(self.inst),

                    IfNode(function() return (TheWorld.state.isspring or TheWorld.state.isgreen) end, "IsSpring",
                        ChaseAndAttack(self.inst, MAX_CHASE_TIME*TUNING.SPRING_COMBAT_MOD)),
                    IfNode(function() return not (TheWorld.state.isspring or TheWorld.state.isgreen) end, "IsNotSpring",
                        ChaseAndAttack(self.inst, MAX_CHASE_TIME)),
                    DoAction(self.inst, function() return EatFoodAction(self.inst) end ),
                    Follow(self.inst, function() return self.inst.components.follower.leader end, MIN_FOLLOW_DIST, TARGET_FOLLOW_DIST, MAX_FOLLOW_DIST),
                    IfNode(function() return self.inst.components.follower.leader ~= nil end, "HasLeader",
        				FaceEntity(self.inst, GetFaceTargetFn, KeepFaceTargetFn )),
                    DoAction(self.inst, function() return InvestigateAction(self.inst) end ),
                    WhileNode(function() return TheWorld.state.isday end, "IsDay",
                            DoAction(self.inst, function() return GoHomeAction(self.inst) end ) ),
                    FaceEntity(self.inst, GetTraderFn, KeepTraderFn),
                    Wander(self.inst, function() return self.inst.components.knownlocations:GetLocation("home") end, MAX_WANDER_DIST)
                },1)
            )
        },1)


    self.bt = BT(self.inst, root)


end

function ScorpionBrain:OnInitializationComplete()
    self.inst.components.knownlocations:RememberLocation("home", Point(self.inst.Transform:GetWorldPosition()), true)

end

return ScorpionBrain
