require "behaviours/standstill"
require "behaviours/runaway"
require "behaviours/doaction"
require "behaviours/panic"
require "behaviours/wander"
require "behaviours/chaseandattack"

local MAX_CHASE_TIME = 60
local MAX_CHASE_DIST = 40

local VampireBatBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

function VampireBatBrain:OnStart()
    local root = PriorityNode(
    {
        WhileNode( function() return self.inst.components.health.takingfiredamage end, "OnFire", Panic(self.inst)),
        AttackWall(self.inst),
        ChaseAndAttack(self.inst, MAX_CHASE_TIME, MAX_CHASE_DIST),
        Leash(self.inst, function() return self.inst.components.teamattacker.teamleader == nil and self.inst.components.knownlocations:GetLocation("home") end, 8, 4),

    }, .25)

    self.bt = BT(self.inst, root)
end

return VampireBatBrain
