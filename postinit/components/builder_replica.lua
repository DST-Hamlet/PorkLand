GLOBAL.setfenv(1, GLOBAL)

local Builder = require("components/builder_replica")

function Builder:CanBuildAtPoint(pt, recipe, rot)
    return TheWorld.Map:CanDeployRecipeAtPoint(pt, recipe, rot, self.inst)
end
