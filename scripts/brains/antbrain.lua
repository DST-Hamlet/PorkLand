require "behaviours/wander"
require "behaviours/follow"
require "behaviours/faceentity"
require "behaviours/chaseandattack"
require "behaviours/runaway"
require "behaviours/doaction"
require "behaviours/findlight"
require "behaviours/panic"
require "behaviours/chattynode"
require "behaviours/leash"

local BrainCommon = require "brains/braincommon"

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
local START_RUN_DIST = 3
local STOP_RUN_DIST = 5
local MAX_CHASE_TIME = 10
local MAX_CHASE_DIST = 30
local SEE_LIGHT_DIST = 20
local TRADE_DIST = 20
local SEE_TREE_DIST = 15
local SEE_TARGET_DIST = 20
local SEE_FOOD_DIST = 10

local KEEP_CHOPPING_DIST = 10

local RUN_AWAY_DIST = 5
local STOP_RUN_AWAY_DIST = 8


local function GetFaceTargetFn(inst)
    local target = GetClosestInstWithTag("player", inst, START_FACE_DIST_FRIENDLY)
    if target and not target:HasTag("notarget") then
        return target
    end
end

local function KeepFaceTargetFn(inst, target)
    return inst:IsNear(target, KEEP_FACE_DIST_FRIENDLY) and not target:HasTag("notarget")
end

local function GetFaceTargetKeepAwayFn(inst)
    local target = GetClosestInstWithTag("player", inst, START_FACE_DIST)
    if target and not target:HasTag("notarget") and not inst.is_complete_disguise(target)  then
        return target
    end
end

local function KeepFaceTargetKeepAwayFn(inst, target)
    return inst:IsNear(target, KEEP_FACE_DIST) and not target:HasTag("notarget") and not inst.is_complete_disguise(target)
end

local function ShouldRunAway(inst, target)
    return not inst.components.trader:IsTryingToTradeWithMe(target)
end

local function GetTraderFn(inst)
    return FindEntity(inst, TRADE_DIST, function(target) return inst.components.trader:IsTryingToTradeWithMe(target) end, {"player"})
end

local function KeepTraderFn(inst, target)
    return inst.components.trader:IsTryingToTradeWithMe(target)
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
				if item:GetTimeAlive() < 8 then return false end
				if item.prefab == "mandrake" then return false end
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

    if not target and (not time_since_eat or time_since_eat > TUNING.PIG_MIN_POOP_PERIOD*2) then
        target = FindEntity(inst, SEE_FOOD_DIST, function(item)
                if not item.components.shelf then return false end
                if not item.components.shelf.itemonshelf or not item.components.shelf.cantakeitem then return false end
                if noveggie and item.components.shelf.itemonshelf.components.edible and item.components.shelf.itemonshelf.components.edible.foodtype ~= "MEAT" then
                    return false
                end
                if not item:IsOnValidGround() then
                    return false
                end
                return inst.components.eater:CanEat(item.components.shelf.itemonshelf)
            end)
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

local function GoHomeAction(inst)
    if not inst.components.follower.leader and
        HasValidHome(inst) and
        not inst.components.combat.target then
            return BufferedAction(inst, inst.components.homeseeker.home, ACTIONS.GOHOME)
    end
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
    return inst.components.follower.leader
end

local function KeepFaceTargetLeaderFn(inst, target)
    return inst.components.follower.leader == target
end

local AntBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

local function translationfn(inst)
    local player = GetClosestInstWithTag("player", inst, START_FACE_DIST)
    if player:HasTag("antlingual") then
        return true
    else
        return false
    end
end

local function getFoodStrings(inst)
    if inst.eattype == 1 then
        return STRINGS.ANT_TALK_WANT_VEGGIE
    elseif inst.eattype == 2 then
        return STRINGS.ANT_TALK_WANT_SEEDS
    elseif inst.eattype == 3 then
        return STRINGS.ANT_TALK_WANT_WOOD
    elseif inst.eattype == 4 then
        return STRINGS.ANT_TALK_WANT_MEAT
    end
end

local function makechatpackage(speech)
return {
        chatlines = speech,
        untranslated = STRINGS.ANT_TALK_UNTRANSLATED,
        translationfn = translationfn
    }
end

local function shouldPanic(inst)
    if inst.components.combat.target then
        local threat = inst.components.combat.target
        if threat then
            if threat.components.inventory then
                local equipped = threat.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
                return equipped and equipped.prefab == "magnifying_glass"
            end
        end
    end

    return false
end

local function RescueLeaderAction(inst)
    return BufferedAction(inst, GetLeader(inst), ACTIONS.UNPIN)
end

function AntBrain:OnStart()
    local root =
        PriorityNode(
        {
            BrainCommon.PanicTrigger(self.inst),

            WhileNode(function() return self.inst.components.health.takingfiredamage end, "OnFire",
				ChattyNode(self.inst, makechatpackage(STRINGS.ANT_TALK_PANICFIRE),
					Panic(self.inst))),

            ChattyNode(self.inst, makechatpackage(STRINGS.ANT_TALK_PANIC),
                WhileNode(function() return shouldPanic(self.inst)  end, "Threat Panic",
                    Panic(self.inst) )),

            ChattyNode(self.inst, makechatpackage(STRINGS.ANT_TALK_FIGHT),
                WhileNode( function() return self.inst.components.combat.target == nil or not self.inst.components.combat:InCooldown() end, "AttackMomentarily",
                    ChaseAndAttack(self.inst, MAX_CHASE_TIME, MAX_CHASE_DIST) )),

            ChattyNode(self.inst, makechatpackage(STRINGS.ANT_TALK_RESCUE),
                WhileNode( function() return GetLeader(self.inst) and GetLeader(self.inst).components.pinnable and GetLeader(self.inst).components.pinnable:IsStuck() end, "Leader Phlegmed",
                    DoAction(self.inst, RescueLeaderAction, "Rescue Leader", true) )),

            ChattyNode(self.inst, makechatpackage(STRINGS.ANT_TALK_FIGHT),
                WhileNode( function() return self.inst.components.combat.target and self.inst.components.combat:InCooldown() end, "Dodge",
                    RunAway(self.inst, function() return self.inst.components.combat.target end, RUN_AWAY_DIST, STOP_RUN_AWAY_DIST) )),

            RunAway(self.inst, function(guy) return guy:HasTag("ant") and guy.components.combat and guy.components.combat.target == self.inst end, RUN_AWAY_DIST, STOP_RUN_AWAY_DIST ),

            --ChattyNode(self.inst, STRINGS.PIG_TALK_ATTEMPT_TRADE,
            --    FaceEntity(self.inst, GetTraderFn, KeepTraderFn)),

            ChattyNode(self.inst, makechatpackage(STRINGS.ANT_TALK_FIND_MEAT),
                DoAction(self.inst, FindFoodAction )),

            IfNode(function() return StartChoppingCondition(self.inst) end, "chop",
                WhileNode(function() return KeepChoppingAction(self.inst) end, "keep chopping",
                    LoopNode{
                        ChattyNode(self.inst, makechatpackage(STRINGS.ANT_TALK_HELP_CHOP_WOOD),
                            DoAction(self.inst, FindTreeToChopAction ))})),

            ChattyNode(self.inst, makechatpackage(STRINGS.ANT_TALK_FOLLOWWILSON),
                Follow(self.inst, GetLeader, MIN_FOLLOW_DIST, TARGET_FOLLOW_DIST, MAX_FOLLOW_DIST)),

            IfNode(function() return GetLeader(self.inst) end, "has leader",
                ChattyNode(self.inst, makechatpackage(STRINGS.ANT_TALK_FOLLOWWILSON),
                    FaceEntity(self.inst, GetFaceTargetLeaderFn, KeepFaceTargetFn ))),

            Leash(self.inst, GetNoLeaderHomePos, LEASH_MAX_DIST, LEASH_RETURN_DIST),

            ChattyNode(self.inst, makechatpackage(STRINGS.ANT_TALK_KEEP_AWAY),
                FaceEntity(self.inst, GetFaceTargetKeepAwayFn, KeepFaceTargetKeepAwayFn)),

            ChattyNode(self.inst, makechatpackage(getFoodStrings(self.inst)),
                FaceEntity(self.inst, GetFaceTargetFn, KeepFaceTargetFn)),

            Wander(self.inst, GetNoLeaderHomePos, MAX_WANDER_DIST)

        }, .5)

    self.bt = BT(self.inst, root)

end

return AntBrain
