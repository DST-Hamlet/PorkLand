GLOBAL.setfenv(1, GLOBAL)

local CraftingMenuIngredients = require("widgets/redux/craftingmenu_ingredients")

local set_recipe = CraftingMenuIngredients.SetRecipe
function CraftingMenuIngredients:SetRecipe(...)
    -- See postinit/components/inventory_replica.lua
    self.owner.replica.inventory.check_all_oincs = true
    local ret = { set_recipe(self, ...) }
    self.owner.replica.inventory.check_all_oincs = nil
    return unpack(ret)
end
