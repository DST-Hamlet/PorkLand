local AddCookerRecipe = AddCookerRecipe
GLOBAL.setfenv(1, GLOBAL)

AddCookerRecipe("smelter", {
    name = "alloy",
    weight = 1,
    cooktime = 0.2,
    test = function(cooker, name, tags)
        return true  -- alway true
    end,
    no_cookbook = true
})
