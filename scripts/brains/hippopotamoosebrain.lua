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
local MAX_WANDER_DIST = 48
local FIND_WATER_DIST = 32
local FIND_WATER_EXTRA_OFFSET = 4
local WANDER_TIMES = {
    minwalktime = 3,
    randwalktime = 1,
    minwaittime = 5,
    randwaittime = 1,
}

local function not_land(position)
    local px, py, pz = position:Get()
    return TheWorld.Map:IsOceanAtPoint(px, py, pz, false)
end

local function FindWaterPosition(inst)
    if inst.components.knownlocations:GetLocation("water_nearby") == nil then
        local ip = inst:GetPosition()
        local offset = FindWalkableOffset(ip, math.random() * 2 * PI, FIND_WATER_DIST, nil, true, false, not_land, true, false)
        if offset then
            -- A second offset so the final position is furthur away from land
            local second_offset = FindWalkableOffset(ip + offset, math.random() * 2 * PI, FIND_WATER_EXTRA_OFFSET, nil, true, false, not_land, true, false) or Vector3(0, 0, 0)
            inst.components.knownlocations:RememberLocation("water_nearby", ip + offset + second_offset)
        end
    end

    return false
end

local function GetWaterNearby(inst)
    local water_nearby = inst.components.knownlocations and inst.components.knownlocations:GetLocation("water_nearby")
    local my_position =  inst:GetPosition()
    if water_nearby and distsq(water_nearby, my_position) > FIND_WATER_DIST * FIND_WATER_DIST then
        inst.components.knownlocations:ForgetLocation("water_nearby")
        return my_position
    end

    return water_nearby or my_position
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
        inst:PushEvent("doleapattack", {target = target})

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
            WhileNode(function() return ShouldLookForWater(self.inst) end, "Looking For Landing Point",
                NotDecorator(ActionNode(function() FindWaterPosition(self.inst) end))),
            WhileNode(function() return ShouldLookForWater(self.inst) end, "Looking For Water",
                Leash(self.inst, GetWaterNearby, 0.5, 0.5)),
            FaceEntity(self.inst, GetFaceTargetFn, KeepFaceTargetFn),
            Wander(self.inst, GetWanderPosition, GetWanderDistance, WANDER_TIMES),
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
