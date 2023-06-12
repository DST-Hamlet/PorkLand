local env = env
GLOBAL.setfenv(1, GLOBAL)

----------------------------------------------------------------------------------------
local PlantRegrowth = require("components/plantregrowth")

local time_multipliers = {
    clawpalmtree = function()
        return TUNING.CLAWPALMTREE_REGROWTH_TIME_MULT or 1
    end,
    teatree = function()
        return TUNING.TEATREE_REGROWTH_TIME_MULT or 1
    end,
    rainforesttree = function() --TODO add this
        return TUNING.RAINFORESTTREE_REGROWTH_TIME_MULT or 1
    end,
}

for i,v in pairs(time_multipliers) do
    PlantRegrowth.TimeMultipliers[i] = v
end