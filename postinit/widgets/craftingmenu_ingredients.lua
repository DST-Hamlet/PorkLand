GLOBAL.setfenv(1, GLOBAL)

local CraftingMenuIngredients = require("widgets/redux/craftingmenu_ingredients")
local RECIPE_OVERRIDE = require("main/porkland_recipe_override")

local set_recipe = CraftingMenuIngredients.SetRecipe
---@param recipe table
function CraftingMenuIngredients:SetRecipe(recipe, ...)
    -- See postinit/components/inventory_replica.lua
    self.owner.replica.inventory.check_all_oincs = true

    -- is this more elegant than adding new recipes for porkland only and hiding dst recipes?
    if TheWorld:HasTag("porkland") and RECIPE_OVERRIDE[recipe.name] then
        recipe.ingredients = RECIPE_OVERRIDE[recipe.name]
    end
    local ret = { set_recipe(self, recipe, ...) }

    self.owner.replica.inventory.check_all_oincs = nil
    return unpack(ret)
end
