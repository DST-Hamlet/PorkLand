GLOBAL.setfenv(1, GLOBAL)

local Builder = require("components/builder")

function Builder:MakeRecipeAtPoint(recipe, pt, rot, skin)
    if not self.inst.components.inventory:IsOpenedBy(self.inst) then
        return -- NOTES(JBK): The inventory was hidden by gameplay do not allow crafting.
    end

    if recipe.placer ~= nil and
        self:KnowsRecipe(recipe) and
        self:IsBuildBuffered(recipe.name) and
        TheWorld.Map:CanDeployRecipeAtPoint(pt, recipe, rot, self.inst) then
        self:MakeRecipe(recipe, pt, rot, skin)
    end
end
