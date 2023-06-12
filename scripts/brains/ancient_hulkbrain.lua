require "behaviours/chaseandattack"
require "behaviours/runaway"
require "behaviours/wander"
require "behaviours/doaction"
require "behaviours/attackwall"
require "behaviours/panic"
require "behaviours/minperiod"
require "behaviours/chaseandram"

local TIME_BETWEEN_EATING = 3.5

local MAX_CHASE_TIME = 10
local GIVE_UP_DIST = 20
local MAX_CHARGE_DIST = 60
local SEE_FOOD_DIST = 15
local SEE_STRUCTURE_DIST = 30

local BASE_TAGS = {"structure"}
local FOOD_TAGS = {"edible"}
local STEAL_TAGS = {"structure"}
local NO_TAGS = {"FX", "NOCLICK", "DECOR","INLIMBO", "burnt"}


local Ancient_hulkBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

function Ancient_hulkBrain:OnStart()
    local root =
        PriorityNode(
        {
            ChaseAndAttack(self.inst, 60, 120, nil, nil, true),
            Wander(self.inst, function() return self.inst:GetPosition() end, 20),
        }, .25)
    
    self.bt = BT(self.inst, root)
         
end

function Ancient_hulkBrain:OnInitializationComplete()
    --self.inst.components.knownlocations:RememberLocation("spawnpoint", Point(self.inst.Transform:GetWorldPosition()))
end

return Ancient_hulkBrain