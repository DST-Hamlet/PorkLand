require("behaviours/chaseandattack")
require("behaviours/wander")
require("behaviours/doaction")

local BARRIER_MAX_DIST = 6
local SPIN_MAX_DIST = 6
local LOB_MAX_DIST = 25
local LOB_MIN_DIST = 10
local TELEPORT_MAX_DIST = 6
local FIND_MINE_DIST = 20
local MINE_DENSITY = 2 -- At least 2 in a 20 radius circle

local function ShouldBarrier(inst)
    if inst.components.health:GetPercent() >= 0.3 then
        return false
    end

    local target = inst.components.combat.target

    if not target or not target:IsValid() then
        return false
    end

    local distsq = inst:GetDistanceSqToInst(target)
    return distsq < BARRIER_MAX_DIST * BARRIER_MAX_DIST and not inst.components.timer:TimerExists("barrier_cd") and not inst.sg:HasStateTag("busy")
end

local function DoBarrier(inst)
    if inst.components.combat.target then
        inst.sg:GoToState("barrier")
    end
end

local function ShouldSpin(inst)
    if inst.components.health:GetPercent() >= 0.5 then
        return false
    end

    local target = inst.components.combat.target

    if not target or not target:IsValid() then
        return false
    end

    local distsq = inst:GetDistanceSqToInst(target)
    return distsq < SPIN_MAX_DIST * SPIN_MAX_DIST and not inst.components.timer:TimerExists("spin_cd") and not inst.sg:HasStateTag("busy")
end

local function DoSpin(inst)
    if inst.components.combat.target then
        inst.sg:GoToState("spin")
    end
end

local function ShuoldLob(inst)
    if inst.orbs <= 0 then
        return false
    end

    local target = inst.components.combat.target

    if not target or not target:IsValid() then
        return false
    end

    local distsq = inst:GetDistanceSqToInst(target)
    return distsq < LOB_MAX_DIST * LOB_MAX_DIST and distsq > LOB_MIN_DIST * LOB_MIN_DIST and not inst.sg:HasStateTag("busy")
end

local function DoLob(inst)
    if inst.components.combat.target then
        inst.sg:GoToState("lob")
    end
end

local function ShouldTeleport(inst)
    local target = inst.components.combat.target

    if not target or not target:IsValid() then
        return false
    end

    local distsq = inst:GetDistanceSqToInst(target)
    return distsq < TELEPORT_MAX_DIST * TELEPORT_MAX_DIST and not inst.components.timer:TimerExists("teleport_cd") and not inst.sg:HasStateTag("busy")
end

local function DoTeleport(inst)
    if inst.components.combat.target then
        inst.sg:GoToState("telportout_pre")
    end
end

local function ShouldSpawnMine(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, FIND_MINE_DIST, {"ancient_hulk_mine"})
    return #ents < MINE_DENSITY and not inst.sg:HasStateTag("busy")
end

local function DoSpawnMine(inst)
    if inst.components.combat.target then
        inst.sg:GoToState("bomb_pre")
    end
end

local AncientHulkBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

function AncientHulkBrain:OnStart()
    local root =
        PriorityNode(
        {
            WhileNode(function() return ShouldBarrier(self.inst) end, "Should barrier",
                DoAction(self.inst, function() return DoBarrier(self.inst) end, "Barrier", true)),

            WhileNode(function() return ShouldSpin(self.inst) end, "Should spin",
                DoAction(self.inst, function() return DoSpin(self.inst) end, "Spin", true)),

            WhileNode(function() return ShuoldLob(self.inst) end, "Should lob",
                DoAction(self.inst, function() return DoLob(self.inst) end, "Lob", true)),

            WhileNode(function() return ShouldTeleport(self.inst) end, "Should teleport",
                DoAction(self.inst, function() return DoTeleport(self.inst) end, "Teleport", true)),

            WhileNode(function() return ShouldSpawnMine(self.inst) end, "Should spawn mine",
                DoAction(self.inst, function() return DoSpawnMine(self.inst) end, "Spawm mine", true)),

            ChaseAndAttack(self.inst, 60, 120, nil, nil, true),

            Wander(self.inst, function() return self.inst:GetPosition() end, 20),
        }, 0.25)

    self.bt = BT(self.inst, root)
end

return AncientHulkBrain
