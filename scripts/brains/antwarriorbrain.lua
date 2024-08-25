require "behaviours/wander"
require "behaviours/follow"
require "behaviours/faceentity"
require "behaviours/chaseandattack"
require "behaviours/runaway"
require "behaviours/doaction"
require "behaviours/findlight"
require "behaviours/panic"
require "behaviours/chattynode"
require "behaviours/leash"

local MAX_CHASE_TIME = 40

local function HasValidHome(inst)
    return inst.components.homeseeker and
       inst.components.homeseeker.home and
       not inst.components.homeseeker.home:HasTag("fire") and
       not inst.components.homeseeker.home:HasTag("burnt") and
       inst.components.homeseeker.home:IsValid()
end

local function GetHomePos(inst)
    return HasValidHome(inst) and inst.components.homeseeker:GetHomePos()
end

local function GetWanderPoint(inst)
    local player = GetClosestInstWithTag("player", inst, 40)
    return GetHomePos(inst) or (player and player:GetPosition())
end

local AntWarriorBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

function AntWarriorBrain:OnStart()
    local root = PriorityNode(
    {
        WhileNode(function() return self.inst.components.health.takingfiredamage end, "OnFire", Panic(self.inst)),

        ChaseAndAttack(self.inst, MAX_CHASE_TIME),

        Wander(self.inst, GetWanderPoint, 20),
    }, 0.1)

    self.bt = BT(self.inst, root)
end

return AntWarriorBrain
