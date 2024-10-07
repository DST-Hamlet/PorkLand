local AddCookerRecipe = AddCookerRecipe
local AddIngredientValues = AddIngredientValues
GLOBAL.setfenv(1, GLOBAL)

local foods = require("main/preparedfoods")
for _, recipe in pairs(foods) do
    AddCookerRecipe("cookpot", recipe)
    AddCookerRecipe("portablecookpot", recipe)
    AddCookerRecipe("archive_cookpot", recipe)
end

AddCookerRecipe("smelter", {
    name = "alloy",
    weight = 1,
    priority = 1,
    cooktime = 0.2,
    test = function(cooker, name, tags)
        return true  -- alway true
    end,
    no_cookbook = true
})

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
