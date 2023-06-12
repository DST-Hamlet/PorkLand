local PLENV = env
GLOBAL.setfenv(1, GLOBAL)

----------------------------------------------------------------------------------------
--Try to initialise all functions locally outside of the post-init so they exist in RAM only once
----------------------------------------------------------------------------------------

local Pickable = require("components/pickable")

local _CanBePicked = Pickable.CanBePicked
function Pickable:CanBePicked(...)
    if self.inst:HasTag("nettle_plant") then
        if self.inst.wet and self.inst:HasTag("pickable") then
            return true
        else
            return false
        end
    end

    return _CanBePicked(self, ...)
end

local function picked(inst, data)
    if data and data.loot and data.loot.components and data.loot.components.visualvariant then
        data.loot.components.visualvariant:CopyOf(data.plant or inst)
    end
end

PLENV.AddComponentPostInit("pickable", function(cmp)
    cmp.inst:ListenForEvent("picked", picked)
end)
