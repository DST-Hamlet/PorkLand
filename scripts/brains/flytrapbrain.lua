require "behaviours/wander"
require "behaviours/chaseandattack"
require "behaviours/panic"
require "behaviours/attackwall"
require "behaviours/minperiod"
require "behaviours/faceentity"
require "behaviours/doaction"
require "behaviours/standstill"

local FlytrapBrain = Class(Brain, function(self, inst)
	Brain._ctor(self, inst)
end)

local BrainCommon = require("brains/braincommon")

local SEE_DIST = 30

local function EatFoodAction(inst)
	if not inst.sg:HasStateTag("busy") then
	    local CANT_TAGS = {"FX", "NOCLICK", "DECOR","INLIMBO", "aquatic"}
	    local target = FindEntity(inst, SEE_DIST, function(item) return inst.components.eater:CanEat(item) and item:IsOnValidGround() and item:GetTimeAlive() > TUNING.SPIDER_EAT_DELAY end
        , nil, CANT_TAGS)
	    if target ~= nil then
	        return BufferedAction(inst, target, ACTIONS.EAT)
	    end
	end
end

function FlytrapBrain:OnStart()
	local root = PriorityNode({
        BrainCommon.PanicTrigger(self.inst),
		DoAction(self.inst, function() return EatFoodAction(self.inst) end ),
		ChaseAndAttack(self.inst, 10),
        StandStill(self.inst),
	}, .25)
	self.bt = BT(self.inst, root)
end

return FlytrapBrain
