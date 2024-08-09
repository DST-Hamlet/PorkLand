require "behaviours/wander"
require "behaviours/chaseandattack"
require "behaviours/runaway"
require "behaviours/doaction"
require "behaviours/panic"
require "behaviours/chattynode"

local MAX_CHASE_TIME = 10
local MAX_CHASE_DIST = 30
local RUN_AWAY_DIST = 5
local STOP_RUN_AWAY_DIST = 8
local SEE_STOLEN_ITEM_DIST = 10
local MAX_WANDER_DIST = 20

local PICKUP_OINC_MUST_TAGS = {"_inventoryitem", "oinc"}
local PICKUP_OINC_NO_TAGS = {"INLIMBO", "outofreach", "trap"}

local function OincNearby(inst)
    return FindEntity(inst, SEE_STOLEN_ITEM_DIST, function(item)
        return item.components.inventoryitem.canbepickedup and item:IsOnValidGround()
    end, PICKUP_OINC_MUST_TAGS, PICKUP_OINC_NO_TAGS)
end

local function FindVanishPosition(inst)
    local pt = inst:GetPosition()

    local theta = math.random() * 2 * PI
    local radius = 70

    local offset = FindWalkableOffset(pt, theta, radius, 12, true)

    if offset then
        return pt + offset
    end
end

local function ShouldVanish(inst)
    return (inst.attacked or (inst.components.inventory:NumItems() > 1 and not OincNearby(inst))) and not inst.sg:HasStateTag("busy")
end

local function DoVanish(inst)
    local position = FindVanishPosition(inst)

    if position then
        return BufferedAction(inst, nil, ACTIONS.PIG_BANDIT_EXIT, nil, position)
    end
end

local function PickupAction(inst)
    local target = OincNearby(inst)

    if target then
        return BufferedAction(inst, target, ACTIONS.PICKUP)
    end
end

local function GetPlayerPos(inst)
    local player = FindClosestPlayerToInst(inst, 40, true)
    if player then
        return player:GetPosition()
    end
end

local PigBanditBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

function PigBanditBrain:OnStart()
    local root = PriorityNode(
    {
        WhileNode(function() return self.inst.components.hauntable and self.inst.components.hauntable.panic end, "PanicHaunted",
            ChattyNode(self.inst, "PIG_TALK_PANICHAUNT",
                Panic(self.inst))),

        WhileNode(function() return self.inst.components.health.takingfiredamage end, "OnFire",
            ChattyNode(self.inst, "PIG_TALK_PANICFIRE",
                Panic(self.inst))),

        WhileNode(function() return ShouldVanish(self.inst) end, "Run off with prize",
            DoAction(self.inst, DoVanish, "Vanish", true)),

        DoAction(self.inst, PickupAction, "Searching for prize", true),

        WhileNode(function() return self.inst.components.combat.target == nil or not self.inst.components.combat:InCooldown() end, "AttackMomentarily",
            ChattyNode(self.inst, "BANDIT_TALK_FIGHT",
                ChaseAndAttack(self.inst, MAX_CHASE_TIME, MAX_CHASE_DIST))),

        RunAway(self.inst, function(guy) return guy:HasTag("pig") and guy.components.combat and guy.components.combat.target == self.inst end, RUN_AWAY_DIST, STOP_RUN_AWAY_DIST),

        Wander(self.inst, GetPlayerPos, MAX_WANDER_DIST)
    }, 0.5)

    self.bt = BT(self.inst, root)
end

return PigBanditBrain
