GLOBAL.setfenv(1, GLOBAL)

local CraftingMenuIngredients = require("widgets/redux/craftingmenu_ingredients")
local change_recipes = require("main/change_recipes")

local set_recipe = CraftingMenuIngredients.SetRecipe
---@param recipe table
function CraftingMenuIngredients:SetRecipe(recipe, ...)
    -- See postinit/components/inventory_replica.lua
    self.owner.replica.inventory.check_all_oincs = true

    -- is this more elegant than adding new recipes for porkland only and hiding dst recipes?
    if TheWorld:HasTag("porkland") and change_recipes.OVERRIDE_RECIPES[recipe.name] then
        recipe.ingredients = change_recipes.OVERRIDE_RECIPES[recipe.name]
    end
    local ret = { set_recipe(self, recipe, ...) }

    self.owner.replica.inventory.check_all_oincs = nil
    return unpack(ret)
end
