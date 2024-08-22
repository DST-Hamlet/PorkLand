GLOBAL.setfenv(1, GLOBAL)

local Builder = require("components/builder_replica")

function Builder:CanBuildAtPoint(pt, recipe, rot)
    return TheWorld.Map:CanDeployRecipeAtPoint(pt, recipe, rot, self.inst)
end

local function get_oinc_cost(recipe)
    for _, v in ipairs(recipe.ingredients) do
        if v.type == "oinc" then
            return v.amount
        end
    end
end

local function get_money(inst)
    local inventory = inst.replica.inventory
    local _, oincamount = inventory:Has("oinc", 0, true)
    local _, oinc10amount = inventory:Has("oinc10", 0, true)
    local _, oinc100amount = inventory:Has("oinc100", 0, true)
    return oincamount + (oinc10amount * 10) + (oinc100amount * 100)
end

local has_ingredients = Builder.HasIngredients
function Builder:HasIngredients(recipe, ...)
    if self.inst.components.builder then
        return has_ingredients(self, recipe, ...)
    end
    if not self.classified then
        return has_ingredients(self, recipe, ...)
    end

    local target_recipe = type(recipe) == "string" and GetValidRecipe(recipe) or recipe
    if not (target_recipe and get_oinc_cost(target_recipe)) then
        return has_ingredients(self, recipe, ...)
    end

    if self.classified.isfreebuildmode:value() then
        return true
    end
    for i, v in ipairs(target_recipe.ingredients) do
        local amount = math.max(1, RoundBiasedUp(v.amount * self:IngredientMod()))
        if v.type == "oinc" then
            if get_money(self.inst) < amount then
                return false
            end
        else
            if not self.inst.replica.inventory:Has(v.type, amount, true) then
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
