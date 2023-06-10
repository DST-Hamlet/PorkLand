require "behaviours/wander"
require "behaviours/runaway"
require "behaviours/doaction"
require "behaviours/panic"
require "behaviours/chaseandattack"
require "behaviours/leash"

local MIN_FOLLOW_DIST = 5
local TARGET_FOLLOW_DIST = 7
local MAX_FOLLOW_DIST = 10

local START_FACE_DIST = 6
local KEEP_FACE_DIST = 8

local RUN_AWAY_DIST = 7
local STOP_RUN_AWAY_DIST = 15

local SEE_FOOD_DIST = 10

local MAX_WANDER_DIST = 15

local MAX_CHASE_TIME = 8
local MAX_CHASE_DIST = 15

local TIME_BETWEEN_EATING = 30

local LEASH_RETURN_DIST = 15
local LEASH_MAX_DIST = 20

local SpiderMonkeyBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)


local function GoHome(inst)
    if inst.components.homeseeker and inst.components.homeseeker.home and inst.components.homeseeker.home:IsValid() then
        return BufferedAction(inst, inst.components.homeseeker.home, ACTIONS.GOHOME)
    end
end

local function GoHomeAction(inst)
    if inst.components.homeseeker and 
       inst.components.homeseeker:HasHome() then 
        return BufferedAction(inst, inst.components.homeseeker.home, ACTIONS.GOHOME, nil, nil, nil, 0.2)
    end
end

local function DefendHomeAction(inst)
    if inst.components.homeseeker and 
       inst.components.homeseeker:HasHome() then 
        return BufferedAction(inst, inst.components.homeseeker.home, ACTIONS.WALKTO, nil, nil, nil, 0.2)
    end
end

local function GetNearbyThreatFn(inst)
    return FindEntity(inst, START_FACE_DIST, nil, nil, {'spidermonkey', 'notarget'}, {'character', 'animal'})
end

local function KeepFaceTargetFn(inst, target)
    return target.components.health and
        not target.components.health:IsDead() and
        inst:GetDistanceSqToInst(target) <= KEEP_FACE_DIST*KEEP_FACE_DIST
end

function SpiderMonkeyBrain:OnStart()
    local root = PriorityNode(
    {
        WhileNode( function() return self.inst.components.health.takingfiredamage end, "OnFire", Panic(self.inst)),

        ChaseAndAttack(self.inst, MAX_CHASE_TIME, MAX_CHASE_DIST),
        
        Wander(self.inst, function() return self.inst.components.knownlocations:GetLocation("home") end, MAX_WANDER_DIST),
    }, .25)
    self.bt = BT(self.inst, root)
end

function SpiderMonkeyBrain:OnInitializationComplete()
end

return SpiderMonkeyBrain
