require "behaviours/standstill"
require "behaviours/runaway"
require "behaviours/doaction"
require "behaviours/panic"
require "behaviours/chaseandram"
require "behaviours/follow"
require "behaviours/attackwall"
require "behaviours/chaseandattack"

local START_FACE_DIST = 14
local KEEP_FACE_DIST = 16
local GO_HOME_DIST = 40
local MAX_CHASE_TIME = 6
local MAX_CHARGE_DIST = 25
local CHASE_GIVEUP_DIST = 10
local RUN_AWAY_DIST = 5
local STOP_RUN_AWAY_DIST = 8
local WANDER_DIST = 20
local MAX_JUMP_ATTACK_RANGE = 9

local HippopotamooseBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

local function GoHomeAction(inst)
    local homePos = inst.components.knownlocations:GetLocation("home")
    if homePos and 
       not inst.components.combat.target then
        return BufferedAction(inst, nil, ACTIONS.WALKTO, nil, homePos, nil, 0.2)
    end
end

local function GetFaceTargetFn(inst)

    local homePos = inst.components.knownlocations:GetLocation("home")
    local myPos = Vector3(inst.Transform:GetWorldPosition() )
    if (homePos and distsq(homePos, myPos) > 40*40) then
        return
    end

    local target = GetClosestInstWithTag("player", inst, START_FACE_DIST)
    if target and not target:HasTag("notarget") then
        return target
    end
end

local function KeepFaceTargetFn(inst, target)
    
    local homePos = inst.components.knownlocations:GetLocation("home")
    local myPos = Vector3(inst.Transform:GetWorldPosition() )
    if (homePos and distsq(homePos, myPos) > 40*40) then
        return false
    end

    return inst:GetDistanceSqToInst(target) <= KEEP_FACE_DIST*KEEP_FACE_DIST and not target:HasTag("notarget")
end

local function ShouldGoHome(inst)

    if (inst.components.follower and inst.components.follower.leader) then
        return false
    end

    local homePos = inst.components.knownlocations:GetLocation("home")
    local myPos = Vector3(inst.Transform:GetWorldPosition() )
    local dist = homePos and distsq(homePos, myPos)
    if not dist then
        return
    end
    return (dist > GO_HOME_DIST*GO_HOME_DIST) or (dist > 10*10 and inst.components.combat.target == nil)
end

local function shouldjumpattack(inst)
    if  inst.sg:HasStateTag("leapattack") then
        return true
    end

    if inst.components.combat.target then
        local target = inst.components.combat.target
        if target then
            if target:IsValid() then
                local combatrange = inst.components.combat:CalcAttackRangeSq(target)
                local distsq = inst:GetDistanceSqToInst(target)
                if distsq > combatrange and distsq < MAX_JUMP_ATTACK_RANGE * MAX_JUMP_ATTACK_RANGE then
                    return true
                end
            else
                print("JUMP TARGET WASN'T THERE ANYMORE?",target.prefab)
                inst.components.combat.target = nil
            end
        end
    end
    return false
end

local function dojumpAttack(inst)
    if inst.components.combat.target and not inst.sg:HasStateTag("leapattack") then
        local target = inst.components.combat.target
        inst:PushEvent("doleapattack", {target=target})

        inst:FacePoint(target.Transform:GetWorldPosition())
    end
end

function HippopotamooseBrain:OnStart()
    local root = PriorityNode(
    {

        WhileNode( function() return shouldjumpattack(self.inst) end, "jumpattack",  
            DoAction(self.inst, function() return dojumpAttack(self.inst) end, "jump", true)
            ), 
        IfNode( function() return self.inst.components.combat.target ~= nil end, "hastarget", AttackWall(self.inst)),
        ChaseAndAttack(self.inst, MAX_CHASE_TIME),

        WhileNode( function() return self.inst.components.health.takingfiredamage end, "OnFire", Panic(self.inst)),
        WhileNode(function() return ShouldGoHome(self.inst) end, "ShouldGoHome",
            DoAction(self.inst, GoHomeAction, "Go Home", false )),

        Follow(self.inst, function() return self.inst.components.follower and self.inst.components.follower.leader end, 
            5, 7, 12, false),
        IfNode(function() return self.inst:HasTag("hippopotamoose") and math.random() < 0.008 end, "wander",
                Wander(self.inst, function() return self.inst.components.knownlocations:GetLocation("home") end, WANDER_DIST)),
        IfNode(function() return not self.inst:HasTag("hippopotamoose") end, "face",
                FaceEntity(self.inst, GetFaceTargetFn, KeepFaceTargetFn)),
        StandStill(self.inst)


    }, .25)
    
    self.bt = BT(self.inst, root)
end

return HippopotamooseBrain
