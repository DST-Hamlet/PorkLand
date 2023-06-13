require "behaviours/wander"
require "behaviours/panic"
require "behaviours/chaseandattack"

local MAX_WANDER_DIST = 20
local MAX_CHASE_TIME  = 10
local SEE_FOOD_DIST   = 50
local SEE_PLAYER_DIST = 5

local BillBrain = Class(Brain, function(self, inst)
	Brain._ctor(self, inst)
end)

function IsBillFood(item)
	return item:HasTag("billfood")
end

local function EatFoodAction(inst)
    local target = FindEntity(inst, SEE_FOOD_DIST, function(item) return IsBillFood(item) end)

    if target then
        return BufferedAction(inst, target, ACTIONS.EAT)
    end
end

local function PickLotusAction(inst)
    local target = FindEntity(inst, SEE_FOOD_DIST, function(item)
        return item.components.pickable
               and item.components.pickable:CanBePicked()
               and item.components.pickable.product == "lotus_flower"
    end)
    if target then
        --check for scary things near the lotus
        local predator = GetClosestInstWithTag("scarytoprey", target, SEE_PLAYER_DIST)
        if predator then target = nil end
    end
    if target then
        return BufferedAction(inst, target, ACTIONS.PICK)
    end
end

function BillBrain:OnStart()
	local root = PriorityNode(
	{
		WhileNode(function() return self.inst.components.health.takingfiredamage end, "OnFire", Panic(self.inst)),
		ChaseAndAttack(self.inst, MAX_CHASE_TIME),
		DoAction(self.inst, function() return EatFoodAction(self.inst) end),
		DoAction(self.inst, PickLotusAction, "Pick Lotus", true),
		Wander(self.inst, function() return self.inst.components.knownlocations:GetLocation("home") end, MAX_WANDER_DIST)
	}, 0.25)
	self.bt = BT(self.inst, root)
end

return BillBrain
