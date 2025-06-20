require "behaviours/doaction"
require "behaviours/follow"
require "behaviours/wander"

local AbigailBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

local WANDER_TIMING = {minwaittime = 6, randwaittime = 6}
local MAX_BABYSIT_WANDER = 6

local function GetLeader(inst)
    return inst.components.follower.leader
end

local function GetLeaderPos(inst)
    return inst.components.follower.leader and inst.components.follower.leader:GetPosition() or nil
end

local function DanceParty(inst)
    inst:PushEvent("dance")
end

local function HauntAction(inst)
    if inst._next_haunt_target ~= nil then
        inst:_SetNewHauntTarget()
    end
    if inst._haunt_target == nil then
        return
    end
    local haunt_action = BufferedAction(inst, inst._haunt_target, ACTIONS.HAUNT)
    haunt_action:AddSuccessAction(inst._OnHauntTargetRemoved)
    haunt_action:AddFailAction(inst._SetNewHauntTarget)
    haunt_action.validfn = function()
        -- InLimbo covers stuff like items getting picked up
        return inst._haunt_target ~= nil and not inst._haunt_target:IsInLimbo() and inst._next_haunt_target == nil
    end
    return haunt_action
end

-------------------------------------------------------------------------------
--  Play With Other Ghosts
local PLAYFUL_OFFSET = 2

local PLAYMATE_NO_TAGS = {"busy"}
local PLAYMATE_ONEOF_TAGS = {"ghostkid", "graveghost"}
local function PlayWithPlaymate(self)
    self.inst:PushEvent("start_playwithghost", {target=self.playfultarget})
    self.playfultarget = nil
    local timer = self.inst.components.timer
    if timer:TimerExists("played_recently") then
        timer:SetTimeLeft("played_recently", TUNING.SEG_TIME)
    else
        timer:StartTimer("played_recently", TUNING.SEG_TIME)
    end

end

local function FindPlaymate(self)
    local leader = GetLeader(self.inst)
    local max_dist_from_leader = (self.inst.is_defensive and TUNING.ABIGAIL_DEFENSIVE_MAX_FOLLOW)
        or TUNING.ABIGAIL_AGGRESSIVE_MAX_FOLLOW

    local can_play = (leader ~= nil and self.inst:IsNear(leader, max_dist_from_leader))
        or true

    -- Try to keep the current playmate
    if self.playfultarget ~= nil and self.playfultarget:IsValid() and can_play
            and (leader == nil or self.playfultarget:IsNear(leader, max_dist_from_leader)) then
        return true
    end

    if self.inst.components.timer:TimerExists("played_recently") then
        return false
    end

    local find_dist = 6

    -- Find a new playmate
    local lx, ly, lz = (leader or self.inst).Transform:GetWorldPosition()
    self.playfultarget = can_play and
        FindEntity(self.inst, find_dist,
            function(v)
                local dsq_to_leader = v:GetDistanceSqToPoint(lx, ly, lz)
                return dsq_to_leader < (max_dist_from_leader * max_dist_from_leader)
            end, nil, PLAYMATE_NO_TAGS, PLAYMATE_ONEOF_TAGS)
        or nil

    return self.playfultarget ~= nil
end

-------------------------------------------------------------------------------
local function ShouldDanceParty(inst)
    local leader = GetLeader(inst)
    return leader ~= nil and leader.sg:HasStateTag("dancing")
end

local function GetTraderFn(inst)
	local leader = inst.components.follower ~= nil and inst.components.follower.leader
	if leader ~= nil then
		return inst.components.trader:IsTryingToTradeWithMe(leader) and leader or nil
	end
end

local function KeepTraderFn(inst, target)
    return inst.components.trader:IsTryingToTradeWithMe(target)
end

local function ShouldWatchMinigame(inst)
    return inst.components.follower.leader ~= nil
        and inst.components.follower.leader.components.minigame_participator ~= nil
        and (inst.components.combat.target == nil or inst.components.combat.target.components.minigame_participator ~= nil)
end

local function WatchingMinigame(inst)
    local leader = inst.components.follower.leader
	return (leader ~= nil
        and leader.components.minigame_participator ~= nil
        and leader.components.minigame_participator:GetMinigame())
        or nil
end

--
local function DefensiveCanFight(inst)

    local target = inst.components.combat.target
    if target ~= nil and not inst.auratest(inst, target) then
        inst.components.combat:GiveUp()
        return false
    end

    if inst:IsWithinDefensiveRange() then
        return true
    elseif inst._playerlink ~= nil and target ~= nil then
        inst.components.combat:GiveUp()
    end

    return false
end

local MAX_AGGRESSIVE_FIGHT_DSQ = math.pow(TUNING.ABIGAIL_COMBAT_TARGET_DISTANCE + 2, 2)
local function AggressiveCanFight(inst)

    local target = inst.components.combat.target
    if target ~= nil and not inst.auratest(inst, target) then
        inst.components.combat:GiveUp()
        return false
    end

    if inst._playerlink then
        if inst:GetDistanceSqToInst(inst._playerlink) < MAX_AGGRESSIVE_FIGHT_DSQ then
            return true
        elseif target ~= nil then
            inst.components.combat:GiveUp()
        end
    end

    return false
end

local function GoToAction(inst)
    local pos = inst._goto_position
    if pos and inst:GetDistanceSqToPoint(pos) > 0.1 * 0.1 then
        return BufferedAction(inst, nil, ACTIONS.WALKTO, nil, home_pos, nil, 0.2)
    end
end

local PRIORITY_NODE_RATE = 0.01
function AbigailBrain:OnStart()

    --#1 priority is dancing beside your leader. Obviously.
    local dance = WhileNode(function() return ShouldDanceParty(self.inst) end, "Dance Party",
        PriorityNode({
            Leash(self.inst, GetLeaderPos, TUNING.ABIGAIL_DEFENSIVE_MED_FOLLOW, TUNING.ABIGAIL_DEFENSIVE_MED_FOLLOW),
            ActionNode(function() DanceParty(self.inst) end),
    }, PRIORITY_NODE_RATE))

    local haunt_behaviour = WhileNode(function() return self.inst._haunt_target ~= nil or self.inst._next_haunt_target ~= nil end, "Haunt Something",
        DoAction(self.inst, HauntAction, nil, true, 60)
    )

    local goto_behaviour = WhileNode(function() return self.inst._goto_position ~= nil end, "Go To Point",
        PriorityNode({
            Leash(self.inst, function(inst) return inst._goto_position end, 0.5, 0.5, true),
            ActionNode(function() self.inst._goto_position = nil end),
        }, PRIORITY_NODE_RATE)
    )

    local play_with_ghosts = WhileNode(function() return not self.inst:IsInLimbo() and FindPlaymate(self) end, "Playful",
        SequenceNode{
            WaitNode(6),
            PriorityNode{
                Leash(self.inst, function() return self.inst:GetPositionAdjacentTo(self.playfultarget, 1) end, PLAYFUL_OFFSET, PLAYFUL_OFFSET),
                ActionNode(function() PlayWithPlaymate(self) end),
                StandStill(self.inst),
            },
        }
    )

    --
    local defensive_mode = WhileNode(function() return self.inst.is_defensive and not self.inst:HasTag("movements_frozen") end, "DefensiveMove",
        PriorityNode({
            WhileNode(function() return DefensiveCanFight(self.inst) end, "CanFight",
                ChaseAndAttack(self.inst, TUNING.ABIGAIL_DEFENSIVE_MAX_CHASE_TIME)),
			FaceEntity(self.inst, GetTraderFn, KeepTraderFn),

            play_with_ghosts,

            Follow(self.inst, function() return self.inst.components.follower.leader end,
                    TUNING.ABIGAIL_DEFENSIVE_MIN_FOLLOW, TUNING.ABIGAIL_DEFENSIVE_MED_FOLLOW, TUNING.ABIGAIL_DEFENSIVE_MAX_FOLLOW, true),
            Wander(self.inst, nil, nil, WANDER_TIMING),
        }, PRIORITY_NODE_RATE)
    )

    --
    local aggressive_mode = WhileNode(function() return not self.inst.is_defensive and not self.inst:HasTag("movements_frozen") end, "AggressiveMove",
        PriorityNode({
            WhileNode(function() return AggressiveCanFight(self.inst) end, "CanFight",
                ChaseAndAttack(self.inst, TUNING.ABIGAIL_AGGRESSIVE_MAX_CHASE_TIME)),

            FaceEntity(self.inst, GetTraderFn, KeepTraderFn),

            play_with_ghosts,

            Follow(self.inst, function() return self.inst.components.follower.leader end,
                    TUNING.ABIGAIL_AGGRESSIVE_MIN_FOLLOW, TUNING.ABIGAIL_AGGRESSIVE_MED_FOLLOW, TUNING.ABIGAIL_AGGRESSIVE_MAX_FOLLOW, true),
            Wander(self.inst),
        }, PRIORITY_NODE_RATE)
    )

    --
    local root = PriorityNode({
        WhileNode(
            function()
                return not self.inst.sg:HasStateTag("swoop")
            end,
            "<swoop state guard>",
            PriorityNode({

                dance,
                haunt_behaviour,
                goto_behaviour,

                defensive_mode,
                aggressive_mode,

                StandStill(self.inst),

            }, PRIORITY_NODE_RATE)
        )
    }, PRIORITY_NODE_RATE)

    self.bt = BT(self.inst, root)
end

return AbigailBrain
