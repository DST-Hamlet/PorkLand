require "behaviours/wander"
require "behaviours/leash"
require "behaviours/doaction"
require "behaviours/chaseandattack"
require "behaviours/runaway"

local BrainCommon = require("brains/braincommon")

local wandertimes = {
    minwalktime = 2,
    randwalktime = 2,
    minwaittime = 0,
    randwaittime = 0
}

local MAX_WANDER_DIST = 40

local STOP_RUN_AWAY_DIST = 8
local RUN_AWAY_DIST = 5

local GlowflyBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

-- 开始茧化，推送事件"cocoon""
local function StartCocooning(inst)
    inst:PushEvent("cocoon")
end

function GlowflyBrain:OnStart()

    local root = PriorityNode(
    {
        BrainCommon.PanicTrigger(self.inst),

        PriorityNode{
        WhileNode(function() return self.inst.components.health.takingfiredamage end, "OnFire", Panic(self.inst)),

          WhileNode(function() return self.inst:HasTag("wantstococoon") and not self.inst.onwater end, "do cocoon",
            ActionNode(function() StartCocooning(self.inst) end)),

          WhileNode(function() return self.inst.components.combat.target and self.inst.components.combat:InCooldown() end, "Dodge",
          RunAway(self.inst, function() return self.inst.components.combat.target end, RUN_AWAY_DIST, STOP_RUN_AWAY_DIST) ),

          Wander(self.inst, nil, MAX_WANDER_DIST, wandertimes)
        }

    }, .25)

    self.bt = BT(self.inst, root)
end

function GlowflyBrain:OnInitializationComplete()
    self.inst.components.knownlocations:RememberLocation("home", Point(self.inst.Transform:GetWorldPosition()), true)
end

return GlowflyBrain
