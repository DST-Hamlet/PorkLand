require("behaviours/standstill")
require("behaviours/runaway")
require("behaviours/doaction")
require("behaviours/panic")
require("behaviours/attackwall")
require("behaviours/chaseandattack")

local BrainCommon = require("brains/braincommon")

local START_FACE_DIST = 10
local KEEP_FACE_DIST = 12
local WANDER_DIST_DAY = 32
local WANDER_DIST_DUSK = 16
local MAX_JUMP_ATTACK_RANGE = 9
local MAX_CHASE_TIME = 6
local MAX_WANDER_DIST = 32
local WANDER_TIMES = {
    minwalktime = 3,
    randwalktime = 1,
    minwaittime = 0,
    randwaittime = 0.1,
}

local function not_land(position)
    local px, py, pz = position:Get()
    return TheWorld.Map:IsOceanAtPoint(px, py, pz, false)
end

local function find_ocean_position(inst)
    if inst.components.knownlocations:GetLocation("landing_point") == nil then
        local ip = inst:GetPosition()
        local offset, c_angle, deflected = FindWalkableOffset(ip, math.random() * 2 * PI, MAX_WANDER_DIST, nil, true, false, not_land, true, false)
        if offset then
            inst.components.knownlocations:RememberLocation("landing_point", ip + offset)
        end
    end

    return false
end

local function GetWanderDistance(inst)
    return TheWorld.state.isdusk and WANDER_DIST_DUSK or WANDER_DIST_DAY
end

local function GetFaceTargetFn(inst)
    local target = GetClosestInstWithTag("character", inst, START_FACE_DIST)
    if target and not target:HasTag("notarget") and not target:HasTag("playerghost") then
        return target
    end
end

local function KeepFaceTargetFn(inst, target)
    return inst:GetDistanceSqToInst(target) <= KEEP_FACE_DIST * KEEP_FACE_DIST and not target:HasTag("notarget") and not target:HasTag("playerghost")
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

local function GetWanderPosition(inst)
    local landing_point = inst.components.knownlocations and inst.components.knownlocations:GetLocation("landing_point")
    local my_position =  inst:GetPosition()
    if landing_point and distsq(landing_point, my_position) > MAX_WANDER_DIST * MAX_WANDER_DIST then
        inst.components.knownlocations:ForgetLocation("landing_point")
        return my_position
    end

    return landing_point or my_position
end

local function ShouldLookForWater(inst)
    return not inst.components.amphibiouscreature.in_water
end

local HippopotamooseBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

function HippopotamooseBrain:OnStart()
    local day = WhileNode(function() return TheWorld.state.isday end, "IsDay",
        PriorityNode{
            NotDecorator(ActionNode(function() find_ocean_position(self.inst) end)),
            WhileNode(function() return ShouldLookForWater(self.inst) end, "Looking For Water",
                Leash(self.inst, GetWanderPosition, 0.5, 0.5)),
            FaceEntity(self.inst, GetFaceTargetFn, KeepFaceTargetFn),
            Wander(self.inst, nil, WANDER_DIST_DAY, WANDER_TIMES),
            StandStill(self.inst)
        }, 0.5)

    local dusk = WhileNode(function() return TheWorld.state.isdusk end, "IsDusk",
        PriorityNode{
            Wander(self.inst, GetWanderPosition, GetWanderDistance),
            StandStill(self.inst)
        }, 0.25)

    local night = WhileNode(function() return TheWorld.state.isdusk end, "IsDusk",
    PriorityNode{
        StandStill(self.inst)
    }, 0.25)

    local root = PriorityNode(
    {
        BrainCommon.PanicTrigger(self.inst),

        WhileNode(function() return ShouldJumpAttack(self.inst) end, "jumpattack", DoAction(self.inst, function() return DoJumpAttack(self.inst) end, "jump", true)),

        IfNode(function() return self.inst.components.combat.target ~= nil end, "hastarget", AttackWall(self.inst)),

        ChaseAndAttack(self.inst, MAX_CHASE_TIME),

        day,
        dusk,
        night,
    }, 0.25)

    self.bt = BT(self.inst, root)
end

return HippopotamooseBrain
