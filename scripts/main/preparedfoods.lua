local foods = {
    coffee =
    {
        test = function(cooker, names, tags) return names.coffeebeans_cooked and (names.coffeebeans_cooked == 4 or (names.coffeebeans_cooked == 3 and (tags.dairy or tags.sweetener)))	end,
        priority = 30,
        foodtype = FOODTYPE.VEGGIE,
        secondaryfoodtype = FOODTYPE.GOODIES,
        health = TUNING.HEALING_SMALL,
        hunger = TUNING.CALORIES_TINY,
        perishtime = TUNING.PERISH_MED,
        sanity = -TUNING.SANITY_TINY,
        cooktime = 0.5,
        oneatenfn = function(inst, eater) -- These buffs override each other
            eater:RemoveDebuff("buff_speed_coffee_beans")
            eater:RemoveDebuff("buff_speed_tea")
            eater:RemoveDebuff("buff_speed_icedtea")
            eater:AddDebuff("buff_speed_coffee", "buff_speed_coffee")
        end,
        is_shipwreck_food = true,
    },

    tea =
    {
        test = function(cooker, names, tags) return names.piko_orange and names.piko_orange >= 2 and tags.sweetener and not tags.meat and not tags.veggie and not tags.inedible end,
        priority = 25,
        foodtype = FOODTYPE.VEGGIE,
        secondaryfoodtype = FOODTYPE.GOODIES,
        health = TUNING.HEALING_SMALL,
        hunger = TUNING.CALORIES_SMALL,
        perishtime = TUNING.PERISH_ONE_DAY,
        sanity = TUNING.SANITY_LARGE,
        temperature = TUNING.HOT_FOOD_BONUS_TEMP,
        temperatureduration = TUNING.FOOD_TEMP_LONG,
        cooktime = 0.5,
        spoiled_product = "icedtea",
        yotp = true,
        oneatenfn = function(inst, eater)
            eater:RemoveDebuff("buff_speed_coffee_beans")
            eater:RemoveDebuff("buff_speed_icedtea")
            eater:RemoveDebuff("buff_speed_coffee")
            eater:AddDebuff("buff_speed_tea", "buff_speed_tea")
        end,
    },

    icedtea =
    {
        test = function(cooker, names, tags) return names.piko_orange and names.piko_orange >= 2 and tags.sweetener and tags.frozen end,
        priority = 30,
        foodtype = FOODTYPE.VEGGIE,
        secondaryfoodtype = FOODTYPE.GOODIES,
        health = TUNING.HEALING_SMALL,
        hunger = TUNING.CALORIES_SMALL,
        perishtime = TUNING.PERISH_FAST,
        sanity = TUNING.SANITY_LARGE,
        temperature = TUNING.COLD_FOOD_BONUS_TEMP,
        temperatureduration = TUNING.FOOD_TEMP_BRIEF * 1.5,
        cooktime = 0.5,
        yotp = true,
        oneatenfn = function(inst, eater)
            eater:RemoveDebuff("buff_speed_coffee_beans")
            eater:RemoveDebuff("buff_speed_tea")
            eater:RemoveDebuff("buff_speed_coffee")
            eater:AddDebuff("buff_speed_icedtea", "buff_speed_icedtea")
        end,
    },
}

for k, v in pairs(foods) do
    v.name = k
    v.weight = v.weight or 1
    v.priority = v.priority or 0

    v.cookbook_category = "cookpot"
    v.overridebuild = "pl_cook_pot_food"
end

return foods
