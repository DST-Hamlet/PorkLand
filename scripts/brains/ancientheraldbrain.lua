require("behaviours/chaseandattack")
require("behaviours/runaway")
require("behaviours/wander")
require("behaviours/doaction")
require("behaviours/attackwall")
require("behaviours/panic")
require("behaviours/minperiod")

local CHASE_DIST = 32
local MAX_WANDER_DIST = CHASE_DIST
local CHASE_TIME = 20

local TAUNT_COOLDOWN = 100
local TAUNT_CHANCE = 0.10

local MAX_SUMMON_COUNT = 12
local COUNT_SUMMON_RADIUS = 20
local HERALD_SUMMON_TAGS = {"aporkalypse_cleanup"}

local function ShoudSummonEntities(inst)
    local x, y, z = inst.Transform:GetWorldPosition() -- in ds is GetPlayer...
    local ents = TheSim:FindEntities(x, y, z, COUNT_SUMMON_RADIUS, HERALD_SUMMON_TAGS)

    return #ents < MAX_SUMMON_COUNT
end

local function CanSummon(inst)
    if not ShoudSummonEntities(inst) then
        return false
    end

    if inst.sg:HasStateTag("busy") then
        return false
    end

    if not inst.components.health or inst.components.health:IsDead() then
        return false
    end

    if not inst.components.combat.target or not inst.components.combat.target:HasTag("player") then
        return false
    end

    return not inst.components.timer:TimerExists("summon_cd")
end

local function DoSummon(inst)
    inst.sg:GoToState("summon")
    inst.components.timer:StartTimer("summon_cd", TUNING.ANCIENT_HERALD_SUMMON_COOLDOWN)
end

local function CanTaunt(inst)
    if inst.sg:HasStateTag("busy") then
        return false
    end

    if not inst.components.health or inst.components.health:IsDead() then
        return false
    end

    if not inst.components.combat.target or not inst.components.combat.target:HasTag("player") then
        return false
    end

    if inst.components.timer:TimerExists("taunt_cd") then
        return false
    end

    return math.random() < TAUNT_CHANCE
end

local function DoTaunt(inst)
    inst.sg:GoToState("taunt")
    inst.components.timer:StartTimer("taunt_cd", TAUNT_COOLDOWN)
end

local AncientHeraldBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

function AncientHeraldBrain:OnStart()
    local root = PriorityNode(
    {
        IfNode(function() return CanTaunt(self.inst) end, "CanTaunt",
            DoAction(self.inst, function() DoTaunt(self.inst) end)),

        IfNode(function() return CanSummon(self.inst) end, "CanSummon",
            DoAction(self.inst, function() DoSummon(self.inst) end)),

        WhileNode(function() return self.inst.components.combat.target == nil or not self.inst.components.combat:InCooldown() end, "AttackMomentarily",
            ChaseAndAttack(self.inst, CHASE_TIME, CHASE_DIST)),

        Wander(self.inst, nil, MAX_WANDER_DIST),
    }, 0.25)

    self.bt = BT(self.inst, root)
end

function AncientHeraldBrain:OnInitializationComplete()
    self.inst.components.knownlocations:RememberLocation("home", self.inst:GetPosition(), true)
end

return AncientHeraldBrain
