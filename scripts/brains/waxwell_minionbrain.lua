require("behaviours/chaseandattack")
require("behaviours/runaway")
require("behaviours/wander")
require("behaviours/doaction")

local BrainCommon = require "brains/braincommon"

local MIN_FOLLOW_DIST = 0
local TARGET_FOLLOW_DIST = 6
local MAX_FOLLOW_DIST = 8

local START_FACE_DIST = 4
local KEEP_FACE_DIST = 8

local KEEP_WORKING_DIST = 14
local SEE_WORK_DIST = 10

local KEEP_DANCING_DIST = 2

local KITING_DIST = 3
local STOP_KITING_DIST = 5

local AVOID_EXPLOSIVE_DIST = 5

local TASK_TYPES = {
    COMBAT = 1,
    MINE = 2,
    CHOP = 3,
    DIG = 4,
    PICK = 5,
}

local function GetLeader(inst)
    return inst.components.follower.leader
end

local function DanceParty(inst)
    inst:PushEvent("dance")
end

local function ShouldDanceParty(inst)
    local leader = GetLeader(inst)
    return leader and leader.sg:HasStateTag("dancing")
end

local function GetLeaderPos(inst)
    return inst.components.follower.leader:GetPosition()
end

local function GetFaceTargetFn(inst)
    local target = FindClosestPlayerToInst(inst, START_FACE_DIST, true)
    return target ~= nil and not target:HasTag("notarget") and target or nil
end

local function KeepFaceTargetFn(inst, target)
    return not target:HasTag("notarget") and inst:IsNear(target, KEEP_FACE_DIST)
end

local function IsNearLeader(inst, dist)
    local leader = GetLeader(inst)
    return leader ~= nil and inst:IsNear(leader, dist)
end

local function IsNearPillar(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, KEEP_WORKING_DIST, {"waxwell_pillar"})
    return next(ents) ~= nil
end

local function ShouldAvoidExplosive(target)
    return target.components.explosive == nil
        or target.components.burnable == nil
        or target.components.burnable:IsBurning()
end

local function GetTask(inst)
    return inst._current_task or inst._queued_task or nil
end

local function ShouldKite(target, inst)
    return inst.components.combat:TargetIs(target)
        and target.components.health ~= nil
        and not target.components.health:IsDead()
end

local function DoWork(inst)
    -- chop
    -- mine
    -- dig
    -- give item
end

local WaxwellMinionBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

function WaxwellMinionBrain:OnStart()
    local root = PriorityNode({
        -- #1 priority is dancing beside your leader. Obviously.
        WhileNode(function() return ShouldDanceParty(self.inst) end, "Dance Party", PriorityNode({
            Leash(self.inst, GetLeaderPos, KEEP_DANCING_DIST, KEEP_DANCING_DIST),
            ActionNode(function() DanceParty(self.inst) end),
        }, 0.25)),

        WhileNode(function() return IsNearLeader(self.inst, KEEP_WORKING_DIST) or IsNearPillar(self.inst) end, "Leader or Pillar In Range", PriorityNode({
            -- avoid explosives
            RunAway(self.inst, {
                fn = ShouldAvoidExplosive,
                tags = {"explosive"},
                notags = {"INLIMBO"}
            }, AVOID_EXPLOSIVE_DIST, AVOID_EXPLOSIVE_DIST),

            WhileNode(function() return GetTask(self.inst) ~= nil end, "Do Task",
                DoAction(self.inst, function()
                    return nil
                end, "Do Work")),

            -- try to fight
            WhileNode(function() return self.inst.components.combat:GetCooldown() > .5 and ShouldKite(self.inst.components.combat.target, self.inst) end, "Dodge",
                RunAway(self.inst, { fn = ShouldKite, tags = { "_combat", "_health" }, notags = { "INLIMBO" } }, KITING_DIST, STOP_KITING_DIST)),
            ChaseAndAttack(self.inst),

            -- try to work
            -- WhileNode(function() return not self.inst.sg:HasStateTag("phasing") end, "Keep Working",
            --     DoAction(self.inst, function() return DoWork(self.inst) end)),
        }, 0.25)),

        Follow(self.inst, GetLeader, MIN_FOLLOW_DIST, TARGET_FOLLOW_DIST, MAX_FOLLOW_DIST),

        WhileNode(function() return GetLeader(self.inst) ~= nil end, "Face Player",
            FaceEntity(self.inst, GetFaceTargetFn, KeepFaceTargetFn)),
    }, 0.25)


    self.bt = BT(self.inst, root)
end

return WaxwellMinionBrain
