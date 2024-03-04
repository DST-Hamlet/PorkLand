require("behaviours/standstill")
require("behaviours/runaway")
require("behaviours/doaction")
require("behaviours/panic")
require("behaviours/chaseandram")
require("behaviours/attackwall")
require("behaviours/chaseandattack")

local BrainCommon = require("brains/braincommon")

local START_FACE_DIST = 4
local KEEP_FACE_DIST = 6
local WANDER_DIST_DAY = 20
local WANDER_DIST_NIGHT = 5
local GO_HOME_DIST = 40
local MAX_JUMP_ATTACK_RANGE = 9
local MAX_CHASE_TIME = 6
local CHASE_GIVEUP_DIST = 10

local function GetWanderDistance(inst)
    return TheWorld.state.isday and WANDER_DIST_DAY or WANDER_DIST_NIGHT
end

local function GoHomeAction(inst)
    local home_position = inst.components.knownlocations:GetLocation("home")
    if home_position and not inst.components.combat.target then
        return BufferedAction(inst, nil, ACTIONS.WALKTO, nil, home_position, nil, 0.2)
    end
end

local function GetFaceTargetFn(inst)
    local home_position = inst.components.knownlocations:GetLocation("home")
    local x, y, z = inst.Transform:GetWorldPosition()

    if (home_position and VecUtil_DistSq(home_position.x, home_position.z, x, z) > GO_HOME_DIST * GO_HOME_DIST) then
        return
    end

    local target = GetClosestInstWithTag("player", inst, START_FACE_DIST)
    if target and not target:HasTag("notarget") and not target:HasTag("playerghost") then
        return target
    end
end

local function KeepFaceTargetFn(inst, target)
    local home_position = inst.components.knownlocations:GetLocation("home")
    local x, y, z = inst.Transform:GetWorldPosition()

    if (home_position and VecUtil_DistSq(home_position.x, home_position.z, x, z) > GO_HOME_DIST * GO_HOME_DIST) then
        return
    end

    return inst:GetDistanceSqToInst(target) <= KEEP_FACE_DIST * KEEP_FACE_DIST and not target:HasTag("notarget")
end

local function ShouldGoHome(inst)
    local home_position = inst.components.knownlocations:GetLocation("home")
    local x, y, z = inst.Transform:GetWorldPosition()
    local distsq_from_home = home_position and VecUtil_DistSq(home_position.x, home_position.z, x, z)
    if not distsq_from_home then
        return
    end

    return (distsq_from_home > GO_HOME_DIST * GO_HOME_DIST) or (distsq_from_home > CHASE_GIVEUP_DIST * CHASE_GIVEUP_DIST and inst.components.combat.target == nil)
end

local function ShouldJumpAttack(inst)
    if inst.sg:HasStateTag("leapattack") then
        return true
    end

    local target = inst.components.combat.target
    if target and target:IsValid() then
        local combatrange = inst.components.combat:CalcAttackRangeSq(target)
        local distsq = inst:GetDistanceSqToInst(target)
        if distsq > combatrange and distsq < MAX_JUMP_ATTACK_RANGE * MAX_JUMP_ATTACK_RANGE then
            return true
        end
    end

    return false
end

local function DoJumpAttack(inst)
    if inst.components.combat.target and not inst.sg:HasStateTag("leapattack") then
        local target = inst.components.combat.target
        inst:PushEvent("doleapattack", {target=target})

        inst:FacePoint(target.Transform:GetWorldPosition())
    end
end

local HippopotamooseBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

function HippopotamooseBrain:OnStart()
    local root = PriorityNode(
    {
        BrainCommon.PanicTrigger(self.inst),

        WhileNode(function() return ShouldJumpAttack(self.inst) end, "jumpattack", DoAction(self.inst, function() return DoJumpAttack(self.inst) end, "jump", true)),

        IfNode(function() return self.inst.components.combat.target ~= nil end, "hastarget", AttackWall(self.inst)),

        ChaseAndAttack(self.inst, MAX_CHASE_TIME),

        WhileNode(function() return ShouldGoHome(self.inst) end, "ShouldGoHome", DoAction(self.inst, GoHomeAction, "Go Home", false)),

        FaceEntity(self.inst, GetFaceTargetFn, KeepFaceTargetFn),

        Wander(self.inst, function() return self.inst.components.knownlocations:GetLocation("home") end, GetWanderDistance),

        StandStill(self.inst)

    }, 0.25)

    self.bt = BT(self.inst, root)
end

function HippopotamooseBrain:OnInitializationComplete()
    self.inst.components.knownlocations:RememberLocation("home", self.inst:GetPosition(), true)
end

return HippopotamooseBrain
