require("behaviours/wander")
require("behaviours/panic")
require("behaviours/chaseandattack")

local BrainCommon = require("brains/braincommon")

local MAX_WANDER_DIST = 15

local MAX_CHASE_TIME = 8
local MAX_CHASE_DIST = 15

local SpiderMonkeyBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

local function MakeHomeAction(inst)
    if inst.target_tree and inst.target_tree:IsValid()
        and not inst.target_tree:HasTag("has_spider")
        and not inst.target_tree:HasTag("burnt")
        and not inst.target_tree:HasTag("stump")
        and not inst.target_tree:HasTag("rotten") then
            return BufferedAction(inst, inst.target_tree, ACTIONS.MAKEHOME)
    end
end

function SpiderMonkeyBrain:OnStart()
    local root = PriorityNode(
    {
        BrainCommon.PanicTrigger(self.inst),

        ChaseAndAttack(self.inst, MAX_CHASE_TIME, MAX_CHASE_DIST),

        DoAction(self.inst, function() return MakeHomeAction(self.inst) end),

        Wander(self.inst, function() return self.inst.tree and self.inst.tree:GetPosition() end, MAX_WANDER_DIST),
    }, 0.25)

    self.bt = BT(self.inst, root)
end

function SpiderMonkeyBrain:OnInitializationComplete()
end

return SpiderMonkeyBrain
