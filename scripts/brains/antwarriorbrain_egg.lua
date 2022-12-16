require "behaviours/doaction"
local BrainCommon = require "brains/braincommon"
local AntWarriorBrain_Egg = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

function AntWarriorBrain_Egg:OnStart()
    local root = PriorityNode(
    {
        BrainCommon.PanicTrigger(self.inst),
    }, .25)

    self.bt = BT(self.inst, root)
end

return AntWarriorBrain_Egg
