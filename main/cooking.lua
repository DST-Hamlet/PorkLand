local AddCookerRecipe = AddCookerRecipe
local AddIngredientValues = AddIngredientValues
GLOBAL.setfenv(1, GLOBAL)

local foods = require("main/preparedfoods")
for _, recipe in pairs(foods) do
    AddCookerRecipe("cookpot", recipe)
    AddCookerRecipe("portablecookpot", recipe)
    AddCookerRecipe("archive_cookpot", recipe)
end

local smelter_recipes =
{
    alloy =
    {
        name = "alloy",
        weight = 1,
        priority = 1,
        cooktime = 0.2,
        test = function(cooker, name, tags)
            if cooker == "smelter" then
                return true  -- alway true
            else
                return false
            end
        end,
        no_cookbook = true
    },
}

for _, recipe in pairs(smelter_recipes) do
    AddCookerRecipe("smelter", recipe)

    AddCookerRecipe("cookpot", recipe) -- 与初版智能锅mod SmartCrockpot进行兼容(workshop-365119238)
    AddCookerRecipe("portablecookpot", recipe)
    AddCookerRecipe("archive_cookpot", recipe)
end

AddIngredientValues({"coffeebeans"}, {fruit = 0.5})
AddIngredientValues({"coffeebeans_cooked"}, {fruit = 1})
AddIngredientValues({"piko_orange"}, {})
AddIngredientValues({"snake_bone"}, {bone=1})

AddIngredientValues({"jellybug"}, {bug=1}, true)
AddIngredientValues({"slugbug"}, {bug=1}, true)
AddIngredientValues({"weevole_carapace"}, {inedible=1})

AddIngredientValues({"radish", "aloe"}, {veggie=1}, true)

AddIngredientValues({"coi", "coi_cooked"}, {meat=.5,fish=.5}, true)

AddIngredientValues({"foliage"}, {veggie=1})

AddIngredientValues({"cutnettle"}, {antihistamine=1})

local cooking = require("cooking")

local get_recipe = cooking.GetRecipe
function cooking.GetRecipe(cooker, product, ...)
    local recipe = get_recipe(cooker, product, ...)
    if recipe and recipe.yotp and TheWorld and TheWorld.state.isfiesta then
        recipe = shallowcopy(recipe)
        recipe.overridebuild = "cook_pot_food_yotp"
    end
    return recipe
end
