GLOBAL.setfenv(1, GLOBAL)

local Builder = require("components/builder")

function Builder:MakeRecipeAtPoint(recipe, pt, rot, skin)
    if not self.inst.components.inventory:IsOpenedBy(self.inst) then
        return -- NOTES(JBK): The inventory was hidden by gameplay do not allow crafting.
    end

    if recipe.placer
        and (self:KnowsRecipe(recipe) or self:CanLearn(recipe.name) and CanPrototypeRecipe(recipe.level, self.accessible_tech_trees))
        and self:IsBuildBuffered(recipe.name)
        and TheWorld.Map:CanDeployRecipeAtPoint(pt, recipe, rot, self.inst) then

        self:MakeRecipe(recipe, pt, rot, skin)
    end
end

local function get_oinc_cost(recipe)
    for _, v in ipairs(recipe.ingredients) do
        if v.type == "oinc" then
            return v.amount
        end
    end
end

local has_ingredients = Builder.HasIngredients
function Builder:HasIngredients(recipe, ...)
    local target_recipe = type(recipe) == "string" and GetValidRecipe(recipe) or recipe

    if not (target_recipe and get_oinc_cost(target_recipe)) then
        return has_ingredients(self, recipe, ...)
    end

    if self.freebuildmode then
        return true
    end
    for i, v in ipairs(target_recipe.ingredients) do
        local amount = math.max(1, RoundBiasedUp(v.amount * self.ingredientmod))
        if v.type == "oinc" then
            if self.inst.components.shopper:GetMoney() < amount then
                return false
            end
        else
            if not self.inst.components.inventory:Has(v.type, amount, true) then
                return false
            end
        end
    end
    for i, v in ipairs(target_recipe.character_ingredients) do
        if not self:HasCharacterIngredient(v) then
            return false
        end
    end
    for i, v in ipairs(target_recipe.tech_ingredients) do
        if not self:HasTechIngredient(v) then
            return false
        end
    end
    return true
end

local remove_ingredients = Builder.RemoveIngredients
function Builder:RemoveIngredients(ingredients, recname, discounted, ...)
    if not self.freebuildmode then
        local recipe = AllRecipes[recname]
        if recipe then
            local cost = get_oinc_cost(recipe)
            if cost then
                self.inst.components.shopper:PayMoney(math.max(1, RoundBiasedUp(cost * self.ingredientmod)))
                ingredients["oinc"] = nil
            end
        end
    end
    return remove_ingredients(self, ingredients, recname, discounted, ...)
end
