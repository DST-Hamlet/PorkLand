require("behaviours/chaseandattack")
require("behaviours/standstill")

local PugaliskUtil = require("prefabs/pugalisk_util")

local function customLocomotionTest(inst)
    if inst.sg:HasStateTag("underground") then
       return false
    end

    if not inst.movecommited then
        PugaliskUtil.DetermineAction(inst)
    end
    if inst.movecommited then
        return false
    end
    return true
end

local PugaliskHeadBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

function PugaliskHeadBrain:OnStart()
    local root =
        PriorityNode(
        {
            WhileNode(function() return customLocomotionTest(self.inst) end, "Be a head",
                PriorityNode{
                    ChaseAndAttack(self.inst),
                    StandStill(self.inst)
                }),
        }, 1)

    self.bt = BT(self.inst, root)
end

return PugaliskHeadBrain
