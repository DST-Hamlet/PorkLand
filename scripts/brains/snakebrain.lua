require "behaviours/wander"
require "behaviours/chaseandattack"
require "behaviours/panic"
require "behaviours/attackwall"
require "behaviours/minperiod"
require "behaviours/faceentity"
require "behaviours/doaction"
require "behaviours/standstill"

local SnakeBrain = Class(Brain, function(self, inst)
	Brain._ctor(self, inst)
end)

local SEE_DIST = 30

local function EatFoodAction(inst)
	local notags = {"FX", "NOCLICK", "DECOR","INLIMBO"}
	local target = FindEntity(inst, SEE_DIST, function(item) return inst.components.eater:CanEat(item) and item:IsOnValidGround() end, nil, notags)
	if target then
		return BufferedAction(inst, target, ACTIONS.EAT)
	end
end

local function GetHome(inst)
	return inst.components.homeseeker and inst.components.homeseeker.home
end

local function GetHomePos(inst)
	local home = GetHome(inst)
	return home and home:GetPosition()
end

local function GetWanderPoint(inst)
	local target = GetHome(inst) or ThePlayer

	if target then
		return target:GetPosition()
	end 
end

local function ShouldSpitFn(inst)
	if inst:HasTag("lavaspitter") then
		if inst.sg:HasStateTag("sleeping") or inst.num_targets_vomited >= TUNING.DRAGONFLY_VOMIT_TARGETS_FOR_SATISFIED or inst.hassleepdestination then return false end
		if not inst.recently_frozen and not inst.flame_on then
			if not inst.last_spit_time then 
				if inst:GetTimeAlive() > 5 then
					return true
				end
			else
				return (GetTime() - inst.last_spit_time) >= inst.spit_interval
			end
		end
	end
	return false
end

local function LavaSpitAction(inst)
	--print("LavaSpitAction", inst.target, inst.target ~= inst, not inst.target:HasTag("fire"))
	if not inst.target or (inst.target ~= inst and not inst.target:HasTag("fire")) then
		inst.last_spit_time = GetTime()
		inst.spit_interval = math.random(20,30)
		if not inst.target then
			inst.target = inst
		end
		-- print("LavaSpitAction", inst, inst.target)
		return BufferedAction(inst, inst.target, ACTIONS.LAVASPIT)
	end
end

local function FindLavaSpitTargetAction(inst) 
	if inst.sg:HasStateTag("sleeping") or inst.num_targets_vomited >= TUNING.DRAGONFLY_VOMIT_TARGETS_FOR_SATISFIED or inst.hassleepdestination then return false end
	if inst.last_spit_time and ((GetTime() - inst.last_spit_time) < 5) then return false end

	local target = nil
	local action = nil

	if inst.sg:HasStateTag("busy") or inst.recently_frozen or inst.flame_on then
		return
	end

	local tagpriority = {"dragonflybait_highprio", "dragonflybait_medprio", "dragonflybait_lowprio"}
	local prio = 1
	local currtag = nil
	
	local pt = inst:GetPosition()
	local ents = nil

	while not target and prio <= #tagpriority do
		currtag = {tagpriority[prio]}
		ents = TheSim:FindEntities(pt.x, pt.y, pt.z, SEE_BAIT_DIST, currtag, {"fire"})
	
		for k,v in pairs(ents) do
			if v and v.components.burnable and (not v.components.inventoryitem or not v.components.inventoryitem:IsHeld()) then
				if not target or (distsq(pt, Vector3(v.Transform:GetWorldPosition())) < distsq(pt, Vector3(target.Transform:GetWorldPosition()))) then
					if inst.last_target ~= v then
						target = v
					end
				end
			end
		end

		prio = prio + 1
	end

	if target and not target:HasTag("fire") then
		inst.target = target
		return BufferedAction(inst, inst.target, ACTIONS.LAVASPIT)
	end
end

local function GoHomeAction(inst)
    if inst.components.homeseeker and 
       inst.components.homeseeker.home and 
       inst.components.homeseeker.home:IsValid() then
        return BufferedAction(inst, inst.components.homeseeker.home, ACTIONS.GOHOME)
    end
end

function SnakeBrain:OnStart()
	
	local root = PriorityNode(
	{
		WhileNode(function() return self.inst.components.health.takingfiredamage end, "OnFire", Panic(self.inst) ),
		
		ChaseAndAttack(self.inst, 8),

		EventNode(self.inst, "gohome", 
            DoAction(self.inst, GoHomeAction, "go home", true )),
        -- WhileNode(function() return GetClock() and GetClock():IsDay() end, "IsDay",
        WhileNode(function() return TheWorld.state.isday end, "IsDay",
            DoAction(self.inst, GoHomeAction, "go home", true )),

		DoAction(self.inst, EatFoodAction, "eat food", true ),
		WhileNode(function() return ShouldSpitFn(self.inst) end, "Spit",
            DoAction(self.inst, LavaSpitAction)),

		WhileNode(function() return GetHome(self.inst) end, "HasHome", Wander(self.inst, GetHomePos, 8) ),
		Wander(self.inst, GetWanderPoint, 20),

	}, .25)
	
	self.bt = BT(self.inst, root)
	
end

return SnakeBrain
