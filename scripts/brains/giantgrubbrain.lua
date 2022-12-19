require "behaviours/wander"
require "behaviours/panic"
require "behaviours/chaseandattack"

local BrainCommon = require "brains/braincommon"
local MAX_WANDER_DIST = 20
local MAX_CHASE_TIME = 30
local SEE_FOOD_DIST = 50
local SEE_VICTIM_DIST = 10

local GiantGrubBrain = Class(Brain, function(self, inst)
	Brain._ctor(self, inst)
end)

function GiantGrubBrain:OnStart()
	local root = PriorityNode(
	{
        BrainCommon.PanicTrigger(self.inst),
		WhileNode(function() return self.inst.components.health.takingfiredamage end, "OnFire", Panic(self.inst)),
		ChaseAndAttack(self.inst, MAX_CHASE_TIME),
		Wander(self.inst, function() return self.inst.components.knownlocations:GetLocation("home") end, MAX_WANDER_DIST)
	}, 0.25)
	self.bt = BT(self.inst, root)
end

return GiantGrubBrain
