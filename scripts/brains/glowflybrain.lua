require("behaviours/wander")
require("behaviours/runaway")

local BrainCommon = require("brains/braincommon")

local MAX_LEASH_DIST = 40
local MAX_WANDER_DIST = 40
local STOP_RUN_AWAY_DIST = 8
local RUN_AWAY_DIST = 5

local MAX_CHASE_DIST = 8
local MAX_CHASE_TIME = 10

local SEE_FLOWER_DIST = 30

local WANDER_TIMES = {
    minwalktime = 2,
    randwalktime = 2,
    minwaittime = 0,
    randwaittime = 0
}

local GlowflyBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

local function CanStartCocooning(inst)
    return inst.wantstococoon and IsSurroundedByLand(inst, nil, nil, 3)
end

local function StartCocooning(inst)
    inst:PushEvent("cocoon")
end

function GlowflyBrain:OnStart()
    local root = PriorityNode(
    {
        BrainCommon.PanicTrigger(self.inst),
        WhileNode(
            function() return CanStartCocooning(self.inst) end,
            "do cocoon",
            ActionNode(function() StartCocooning(self.inst) end)
        ),

        WhileNode(
            function() return self.inst.components.combat.target and self.inst.components.combat:InCooldown() end,
            "Dodge",
            RunAway(self.inst, function() return self.inst.components.combat.target end, RUN_AWAY_DIST, STOP_RUN_AWAY_DIST)
        ),

        Wander(self.inst, nil, MAX_WANDER_DIST, WANDER_TIMES)
    }, .25)

    self.bt = BT(self.inst, root)
end

function GlowflyBrain:OnInitializationComplete()
    self.inst.components.knownlocations:RememberLocation("home", self.inst:GetPosition(), true)
end

return GlowflyBrain
