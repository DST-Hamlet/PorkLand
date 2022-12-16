require "behaviours/wander"
require "behaviours/chaseandattack"
require "behaviours/panic"
require "behaviours/attackwall"
require "behaviours/minperiod"
require "behaviours/faceentity"
require "behaviours/doaction"
require "behaviours/standstill"

local BrainCommon = require "brains/braincommon"

local FlytrapBrain = Class(Brain, function(self, inst)
	Brain._ctor(self, inst)
end)

local SEE_DIST = 30

local function EatFoodAction(inst)
	if not inst.sg:HasStateTag("busy") then
	    local notags = {"FX", "NOCLICK", "DECOR","INLIMBO", "aquatic"}
	    local target = FindEntity(inst, SEE_DIST, function(item) return inst.components.eater:CanEat(item) and item:IsOnValidGround() and item:GetTimeAlive() > TUNING.SPIDER_EAT_DELAY end, nil, notags)
	    if target then
	        return BufferedAction(inst, target, ACTIONS.EAT)
	    end
	end
end

function FlytrapBrain:OnStart()

	local root = PriorityNode(
	{
        BrainCommon.PanicTrigger(self.inst),
        WhileNode(function() return self.inst:HasTag("fire") or self.inst.components.health.takingfiredamage end, "Panic", Panic(self.inst)),

		DoAction(self.inst, function() return EatFoodAction(self.inst) end ),

		ChaseAndAttack(self.inst, 10),
        StandStill(self.inst),
		--Wander(self.inst, function() return self.inst:GetPosition() end, 15),

	}, .25)

	self.bt = BT(self.inst, root)

end

return FlytrapBrain
