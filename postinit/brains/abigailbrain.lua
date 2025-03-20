GLOBAL.setfenv(1, GLOBAL)

require("behaviours/follow")
require("behaviours/wander")

local AbigailBrain = require("brains/abigailbrain")

local MIN_FOLLOW = 4
local MAX_FOLLOW = 11
local MED_FOLLOW = 6
local MAX_CHASE_TIME = 6

local function ShouldWatchMinigame(inst)
    if inst.components.follower.leader ~= nil and inst.components.follower.leader.components.minigame_participator ~= nil then
        if inst.components.combat.target == nil or inst.components.combat.target.components.minigame_participator ~= nil then
            return true
        end
    end
    return false
end

local function WatchingMinigame(inst)
    return (inst.components.follower.leader ~= nil and inst.components.follower.leader.components.minigame_participator ~= nil) and inst.components.follower.leader.components.minigame_participator:GetMinigame() or nil
end

function AbigailBrain:OnStart()
    local watch_game = WhileNode( function() return ShouldWatchMinigame(self.inst) end, "Watching Game",
        PriorityNode({
            Follow(self.inst, WatchingMinigame, TUNING.MINIGAME_CROWD_DIST_MIN, TUNING.MINIGAME_CROWD_DIST_TARGET, TUNING.MINIGAME_CROWD_DIST_MAX),
            RunAway(self.inst, "minigame_participator", 5, 7),
            FaceEntity(self.inst, WatchingMinigame, WatchingMinigame),
        }, 0.25))

    local root = PriorityNode(
    {
        watch_game,
        -- ziwbi: should we add Abigail dancing here?
        ChaseAndAttack(self.inst, MAX_CHASE_TIME),
        Follow(self.inst, function() return self.inst.components.follower.leader end, MIN_FOLLOW, MED_FOLLOW, MAX_FOLLOW, true),
        Wander(self.inst),
    }, .5)

    self.bt = BT(self.inst, root)
end
