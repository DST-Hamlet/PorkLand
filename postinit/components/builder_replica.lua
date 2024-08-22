GLOBAL.setfenv(1, GLOBAL)

local Builder = require("components/builder_replica")

function Builder:CanBuildAtPoint(pt, recipe, rot)
    return TheWorld.Map:CanDeployRecipeAtPoint(pt, recipe, rot, self.inst)
end

local has_ingredients = Builder.HasIngredients
function Builder:HasIngredients(recipe, ...)
    -- See postinit/components/inventory_replica.lua
    -- Cache check_all_oincs and restore it since others might set it too
    local check_all_oincs = self.inst.replica.inventory.check_all_oincs
    self.inst.replica.inventory.check_all_oincs = true
    local ret = { has_ingredients(self, recipe, ...) }
    self.inst.replica.inventory.check_all_oincs = check_all_oincs
    return unpack(ret)
end
