local foods = {
    coffee =
    {
        test = function(cooker, names, tags) return names.coffeebeans_cooked and (names.coffeebeans_cooked == 4 or (names.coffeebeans_cooked == 3 and (tags.dairy or tags.sweetener))) end,
        priority = 30,
        foodtype = FOODTYPE.GOODIES,
        secondaryfoodtype = FOODTYPE.VEGGIE,
        health = TUNING.HEALING_SMALL,
        hunger = TUNING.CALORIES_TINY,
        perishtime = TUNING.PERISH_MED,
        sanity = -TUNING.SANITY_TINY,
        cooktime = 0.5,
        oneat_desc = STRINGS.UI.COOKBOOK.FOOD_EFFECTS_SPEED_BOOST,
        oneatenfn = function(inst, eater)
            -- These buffs override each other, but RemoveExternalSpeedMultiplier needs the source in order to remove a buff
            eater:RemoveDebuff("buff_speed_coffee_beans")
            eater:RemoveDebuff("buff_speed_tea")
            eater:RemoveDebuff("buff_speed_icedtea")
            eater:AddDebuff("buff_speed_coffee", "buff_speed_coffee")
        end,
        is_shipwreck_food = true,
        card_def = {ingredients = {{"coffeebeans_cooked", 3}, {"honey", 1}}},
    },

	snakebonesoup = 
	{
        -- modified test functon because DST has bone tag already
		test = function(cooker, names, tags) return names.snake_bone and names.snake_bone >= 2 and tags.meat and tags.meat >= 2 end,
		priority = 20,
		foodtype = "MEAT",
		health = TUNING.HEALING_LARGE,
		hunger = TUNING.CALORIES_MED,
		perishtime = TUNING.PERISH_MED,
		sanity = TUNING.SANITY_SMALL,
		cooktime = 1,
		yotp = true,
        card_def = {ingredients = {{"snake_bone", 2}, {"monstermeat", 2}}},
	},

    tea =
    {
        test = function(cooker, names, tags) return names.piko_orange and names.piko_orange >= 2 and tags.sweetener and not tags.meat and not tags.veggie and not tags.inedible end,
        priority = 25,
        foodtype = FOODTYPE.VEGGIE, -- still veggie, otherwise what's the point of Wigfird?
        health = TUNING.HEALING_SMALL,
        hunger = TUNING.CALORIES_SMALL,
        perishtime = TUNING.PERISH_ONE_DAY,
        sanity = TUNING.SANITY_LARGE,
        temperature = TUNING.HOT_FOOD_BONUS_TEMP,
        temperatureduration = TUNING.FOOD_TEMP_LONG,
        cooktime = 0.5,
        oneat_desc = STRINGS.UI.COOKBOOK.FOOD_EFFECTS_SPEED_BOOST,
        spoiled_product = "icedtea",
        yotp = true,
        card_def = {ingredients = {{"piko_orange", 2}, {"honey", 2}}},
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
        foodtype = FOODTYPE.VEGGIE, -- still veggie, otherwise what's the point of Wigfird?
        health = TUNING.HEALING_SMALL,
        hunger = TUNING.CALORIES_SMALL,
        perishtime = TUNING.PERISH_FAST,
        sanity = TUNING.SANITY_LARGE,
        temperature = TUNING.COLD_FOOD_BONUS_TEMP,
        temperatureduration = TUNING.FOOD_TEMP_BRIEF * 1.5,
        cooktime = 0.5,
        oneat_desc = STRINGS.UI.COOKBOOK.FOOD_EFFECTS_SPEED_BOOST,
        yotp = true,
        card_def = {ingredients = {{"piko_orange", 2}, {"honey", 1}, {"ice", 1}}},
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
