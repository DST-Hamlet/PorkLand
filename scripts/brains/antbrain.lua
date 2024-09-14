require("behaviours/wander")
require("behaviours/follow")
require("behaviours/faceentity")
require("behaviours/chaseandattack")
require("behaviours/runaway")
require("behaviours/doaction")
require("behaviours/findlight")
require("behaviours/panic")
require("behaviours/chattynode")
require("behaviours/leash")

local MIN_FOLLOW_DIST = 2
local TARGET_FOLLOW_DIST = 5
local MAX_FOLLOW_DIST = 9
local MAX_WANDER_DIST = 20

local LEASH_RETURN_DIST = 10
local LEASH_MAX_DIST = 30

local START_FACE_DIST_FRIENDLY = 4
local KEEP_FACE_DIST_FRIENDLY = 5

local START_FACE_DIST = 10
local KEEP_FACE_DIST = 10.5
local MAX_CHASE_TIME = 10
local MAX_CHASE_DIST = 30
local SEE_TREE_DIST = 15
local SEE_FOOD_DIST = 10

local KEEP_CHOPPING_DIST = 10

local RUN_AWAY_DIST = 5
local STOP_RUN_AWAY_DIST = 8

local function GetFaceTargetFn(inst)
    local target = GetClosestInstWithTag("player", inst, START_FACE_DIST_FRIENDLY)
    if target and not target:HasTag("notarget") and not target:HasTag("playerghost") then
        inst.facing_target = target -- for stategraph
        return target
    else
        inst.facing_target = nil
    end
end

local function KeepFaceTargetFn(inst, target)
    return inst:IsNear(target, KEEP_FACE_DIST_FRIENDLY) and not target:HasTag("notarget")
end

local function GetFaceTargetKeepAwayFn(inst)
    local target = GetClosestInstWithTag("player", inst, START_FACE_DIST)
    if target and not target:HasTag("notarget") and not target:HasTag("playerghost") and not IsPlayerInAntDisguise(target) then
        inst.facing_target = target -- for stategraph
        return target
    else
        inst.facing_target = nil
    end
end

local function KeepFaceTargetKeepAwayFn(inst, target)
    return inst:IsNear(target, KEEP_FACE_DIST) and not target:HasTag("notarget") and not IsPlayerInAntDisguise(target)
end

local function FindFoodAction(inst)
    local target = nil

    if inst.sg:HasStateTag("busy") then
        return
    end

    if inst.components.inventory and inst.components.eater then
        target = inst.components.inventory:FindItem(function(item) return inst.components.eater:CanEat(item) end)
    end

    local time_since_eat = inst.components.eater:TimeSinceLastEating()
    local noveggie = time_since_eat and time_since_eat < TUNING.PIG_MIN_POOP_PERIOD*4

    if not target and (not time_since_eat or time_since_eat > TUNING.PIG_MIN_POOP_PERIOD*2) then
        target = FindEntity(inst, SEE_FOOD_DIST, function(item)
            if item:GetTimeAlive() < 8 then
                return false
            end
            if item.prefab == "mandrake" then
                return false
            end
            if noveggie and item.components.edible and item.components.edible.foodtype ~= "MEAT" then
                return false
            end
            if not item:IsOnValidGround() then
                return false
            end
            return inst.components.eater:CanEat(item)
        end)
    end
    if target then
        return BufferedAction(inst, target, ACTIONS.EAT)
    end

    -- eat from shelves
    if not target and (not time_since_eat or time_since_eat > TUNING.PIG_MIN_POOP_PERIOD * 2) then
        local visual_slot = FindEntity(inst, SEE_FOOD_DIST, function(visual_slot)
            if not visual_slot.components.visualslot then
                return false
            end

            local shelf = visual_slot.components.visualslot:GetShelf()

            if shelf.components.lock and shelf.components.lock:IsLocked() then
                return false
            end

            local item = visual_slot.components.visualslot:GetItem()
            if not item then
                return false
            end

            if noveggie and item.components.edible and item.components.edible.foodtype ~= "MEAT" then
                return false
            end
            if not item:IsOnValidGround() then
                return false
            end
            return inst.components.eater:CanEat(item)
        end)

        if visual_slot then
            target = visual_slot.components.visualslot:GetItem()
        end
    end

    if target then
        return BufferedAction(inst, target, ACTIONS.TAKEITEM)
    end
end

local function KeepChoppingAction(inst)
    local keep_chop = inst.components.follower.leader and inst.components.follower.leader:GetDistanceSqToInst(inst) <= KEEP_CHOPPING_DIST*KEEP_CHOPPING_DIST
    local target = FindEntity(inst, SEE_TREE_DIST/3, function(item)
        return item.prefab == "deciduoustree" and item.monster and item.components.workable and item.components.workable.action == ACTIONS.CHOP
    end)
    if inst.tree_target ~= nil then target = inst.tree_target end

    return (keep_chop or target ~= nil)
end

local function StartChoppingCondition(inst)
    local start_chop = inst.components.follower.leader and inst.components.follower.leader.sg and inst.components.follower.leader.sg:HasStateTag("chopping")
    local target = FindEntity(inst, SEE_TREE_DIST/3, function(item)
        return item.prefab == "deciduoustree" and item.monster and item.components.workable and item.components.workable.action == ACTIONS.CHOP
    end)
    if inst.tree_target ~= nil then target = inst.tree_target end

    return (start_chop or target ~= nil)
end

local function FindTreeToChopAction(inst)
    local target = FindEntity(inst, SEE_TREE_DIST, function(item) return item.components.workable and item.components.workable.action == ACTIONS.CHOP end)
    if target then
        local decid_monst_target = FindEntity(inst, SEE_TREE_DIST/3, function(item)
            return item.prefab == "deciduoustree" and item.monster and item.components.workable and item.components.workable.action == ACTIONS.CHOP
        end)
        if decid_monst_target ~= nil then
            target = decid_monst_target
        end
        if inst.tree_target then
            target = inst.tree_target
            inst.tree_target = nil
        end
        return BufferedAction(inst, target, ACTIONS.CHOP)
    end
end

local function HasValidHome(inst)
    return inst.components.homeseeker and
       inst.components.homeseeker.home and
       not inst.components.homeseeker.home:HasTag("fire") and
       not inst.components.homeseeker.home:HasTag("burnt") and
       inst.components.homeseeker.home:IsValid()
end

local function GetLeader(inst)
    return inst.components.follower.leader
end

local function GetHomePos(inst)
    return HasValidHome(inst) and inst.components.homeseeker:GetHomePos()
end

local function GetNoLeaderHomePos(inst)
    if GetLeader(inst) then
        return nil
    end
    return GetHomePos(inst)
end

local function GetFaceTargetLeaderFn(inst)
    inst.facing_target = inst.components.follower.leader -- for stategraph
    return inst.facing_target
end

local function GetFoodStrings(inst)
    if inst.eattype == 1 then
        return "ANT_TALK_WANT_VEGGIE"
    elseif inst.eattype == 2 then
        return "ANT_TALK_WANT_SEEDS"
    elseif inst.eattype == 3 then
        return "ANT_TALK_WANT_WOOD"
    elseif inst.eattype == 4 then
        return "ANT_TALK_WANT_MEAT"
    end
end

local function ShouldPanic(inst)
    local threat = inst.components.combat.target
    if threat then
        if threat.components.inventory then
            local equipped = threat.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
            return equipped and equipped.prefab == "magnifying_glass"
        end
    end

    return false
end

local function RescueLeaderAction(inst)
    return BufferedAction(inst, GetLeader(inst), ACTIONS.UNPIN)
end

local AntBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

function AntBrain:OnStart()
    local root = PriorityNode({
        WhileNode(function() return self.inst.components.health.takingfiredamage end, "OnFire",
            ChattyNode(self.inst, "ANT_TALK_PANICFIRE",
                Panic(self.inst))),

        -- TODO ghost panic string

        WhileNode(function() return ShouldPanic(self.inst) end, "Threat Panic",
            ChattyNode(self.inst, "ANT_TALK_PANIC",
                Panic(self.inst))),

        ChattyNode(self.inst, "ANT_TALK_FIGHT",
            WhileNode(function() return self.inst.components.combat.target == nil or not self.inst.components.combat:InCooldown() end, "AttackMomentarily",
                ChaseAndAttack(self.inst, MAX_CHASE_TIME, MAX_CHASE_DIST))),

        ChattyNode(self.inst, "ANT_TALK_RESCUE",
            WhileNode(function() return GetLeader(self.inst) and GetLeader(self.inst).components.pinnable and GetLeader(self.inst).components.pinnable:IsStuck() end, "Leader Phlegmed",
                DoAction(self.inst, RescueLeaderAction, "Rescue Leader", true))),

        ChattyNode(self.inst, "ANT_TALK_FIGHT",
            WhileNode(function() return self.inst.components.combat.target and self.inst.components.combat:InCooldown() end, "Dodge",
                RunAway(self.inst, function() return self.inst.components.combat.target end, RUN_AWAY_DIST, STOP_RUN_AWAY_DIST))),

        RunAway(self.inst, function(ent) return ent:HasTag("ant") and ent.components.combat and ent.components.combat.target == self.inst end, RUN_AWAY_DIST, STOP_RUN_AWAY_DIST),

        ChattyNode(self.inst, "ANT_TALK_FIND_MEAT",
            DoAction(self.inst, FindFoodAction)),

        IfThenDoWhileNode(function() return StartChoppingCondition(self.inst) end, function() return KeepChoppingAction(self.inst) end, "chop",
            LoopNode{
                ChattyNode(self.inst, "ANT_TALK_HELP_CHOP_WOOD",
                    DoAction(self.inst, FindTreeToChopAction ))}),

        ChattyNode(self.inst, "ANT_TALK_FOLLOWWILSON",
            Follow(self.inst, GetLeader, MIN_FOLLOW_DIST, TARGET_FOLLOW_DIST, MAX_FOLLOW_DIST)),

        IfNode(function() return GetLeader(self.inst) end, "has leader",
            ChattyNode(self.inst, "ANT_TALK_FOLLOWWILSON",
                FaceEntity(self.inst, GetFaceTargetLeaderFn, KeepFaceTargetFn))),

        Leash(self.inst, GetNoLeaderHomePos, LEASH_MAX_DIST, LEASH_RETURN_DIST),

        ChattyNode(self.inst, "ANT_TALK_KEEP_AWAY",
            FaceEntity(self.inst, GetFaceTargetKeepAwayFn, KeepFaceTargetKeepAwayFn)),

        ChattyNode(self.inst, GetFoodStrings(self.inst),
            FaceEntity(self.inst, GetFaceTargetFn, KeepFaceTargetFn)),

        Wander(self.inst, GetNoLeaderHomePos, MAX_WANDER_DIST)
    }, 0.5)

    self.bt = BT(self.inst, root)
end

return AntBrain
