require("behaviours/chaseandattack")
require("behaviours/runaway")
require("behaviours/wander")
require("behaviours/doaction")
require("behaviours/avoidlight")
require("behaviours/panic")
require("behaviours/attackwall")
require("behaviours/useshield")

local BrainCommon = require "brains/braincommon"

-- local RETURN_HOME_DELAY_MIN = 15
-- local RETURN_HOME_DELAY_MAX = 25

local MAX_WANDER_DIST = 50
local MAX_CHASE_DIST = 20
local MAX_CHASE_TIME = 8

local RUN_AWAY_DIST = 3
local STOP_RUN_AWAY_DIST = 5


local DAMAGE_UNTIL_SHIELD = 100
local SHIELD_TIME = 3
local AVOID_PROJECTILE_ATTACKS = false

local SEE_FOOD_DIST = 10

local function GetHome(inst)
    return inst.components.homeseeker and inst.components.homeseeker.home
end

local function GetHomePos(inst)
    local home = GetHome(inst)
    return home and home:GetPosition()
end

local function GetWanderPoint(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    local target = GetHome(inst) or FindClosestPlayerInRange(x, y, z, 64, true)

    if target then
        return target:GetPosition()
    end
end

local function GoHomeAction(inst)
    if inst.components.homeseeker and inst.components.homeseeker.home and inst.components.homeseeker.home:IsValid() then
        return BufferedAction(inst, inst.components.homeseeker.home, ACTIONS.GOHOME)
    end
end

local function EatFoodAction(inst)
    local target = FindEntity(inst, SEE_FOOD_DIST, function(item)
        return inst.components.eater:CanEat(item) and item:IsOnPassablePoint()
    end)
    if target then
        return BufferedAction(inst, target, ACTIONS.EAT)
    end
end

local WeevoleBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

function WeevoleBrain:OnStart()
    local root = PriorityNode(
    {
        BrainCommon.PanicTrigger(self.inst),
        WhileNode(
            function() return not self.inst.sg:HasStateTag("jumping") end, "AttackAndWander",
            PriorityNode(
            {
                UseShield(self.inst, DAMAGE_UNTIL_SHIELD, SHIELD_TIME, AVOID_PROJECTILE_ATTACKS),
                WhileNode(function() return self.inst.components.combat.target == nil or not self.inst.components.combat:InCooldown() end, "AttackMomentarily", ChaseAndAttack(self.inst, MAX_CHASE_TIME, MAX_CHASE_DIST)),
                WhileNode(function() return self.inst.components.combat.target and self.inst.components.combat:InCooldown() end, "Dodge", RunAway(self.inst, function() return self.inst.components.combat.target end, RUN_AWAY_DIST, STOP_RUN_AWAY_DIST)),
                DoAction(self.inst, function() return EatFoodAction(self.inst) end),
                EventNode(self.inst, "gohome", DoAction(self.inst, GoHomeAction, "go home", true)),
                WhileNode(function() return TheWorld.state.isday end, "IsDay", DoAction(self.inst, GoHomeAction, "go home", true)),
                WhileNode(function() return GetHome(self.inst) end, "HasHome", Wander(self.inst, GetHomePos, 8)),
                -- Wander(self.inst, GetWanderPoint, 20),
                Wander(self.inst, GetWanderPoint, MAX_WANDER_DIST, {minwalktime = .5, randwalktime = math.random() < 0.5 and .5 or 1, minwaittime = math.random() < 0.5 and 0 or 1, randwaittime = .2,}),
            }, .25)
        )
    }, .25)

    self.bt = BT(self.inst, root)
end

function WeevoleBrain:OnInitializationComplete()
    if not self.inst.components.knownlocations:GetLocation("home") then
        self.inst.components.knownlocations:RememberLocation("home", self.inst:GetPosition(), true)
    end
end

return WeevoleBrain
