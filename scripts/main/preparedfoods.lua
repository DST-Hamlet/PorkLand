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
        foodtype = FOODTYPE.MEAT,
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

    gummy_cake =
    {
        test = function(cooker, names, tags) return (names.slugbug or names.slugbug_cooked) and tags.sweetener end,

        priority = 1,
        foodtype = FOODTYPE.MEAT,
        health = -TUNING.HEALING_SMALL,
        hunger = TUNING.CALORIES_SUPERHUGE,
        perishtime = TUNING.PERISH_PRESERVED,
        sanity = -TUNING.SANITY_TINY,
        cooktime = 2,
        yotp = true,
    },

    feijoada =
    {
        test = function(cooker, names, tags) return tags.meat and ((names.jellybug or 0) + (names.jellybug_cooked or 0)) == 3 end,

        priority = 30,
        foodtype = FOODTYPE.MEAT,
        health = TUNING.HEALING_MED,
        hunger = TUNING.CALORIES_HUGE,
        perishtime = TUNING.PERISH_FASTISH,
        sanity = TUNING.SANITY_MED,
        cooktime = 3.5,
        yotp = true,
    },

    spicyvegstinger =
    {
        test = function(cooker, names, tags) return (names.asparagus or names.asparagus_cooked or names.radish or names.radish_cooked) and tags.veggie and tags.veggie > 2 and tags.frozen and not tags.meat end,
        priority = 15,
        foodtype = FOODTYPE.VEGGIE,
        health = TUNING.HEALING_SMALL,
        hunger = TUNING.CALORIES_MED,
        perishtime = TUNING.PERISH_SLOW,
        sanity = TUNING.SANITY_LARGE,
        cooktime = 0.5,
        yotp = true,
    },

    steamedhamsandwich =
    {
        test = function(cooker, names, tags) return (names.meat or names.meat_cooked) and (tags.veggie and tags.veggie >= 2) and names.foliage end,
        priority = 5,
        foodtype = FOODTYPE.MEAT,
        health = TUNING.HEALING_LARGE,
        hunger = TUNING.CALORIES_LARGE,
        perishtime = TUNING.PERISH_FAST,
        sanity = TUNING.SANITY_MED,
        cooktime = 2,
        yotp = true,
    },

    hardshell_tacos =
    {
        test = function(cooker, names, tags) return names.weevole_carapace == 2 and tags.veggie end,

        priority = 1,
        foodtype = FOODTYPE.VEGGIE,
        health = TUNING.HEALING_MED,
        hunger = TUNING.CALORIES_LARGE,
        perishtime = TUNING.PERISH_SLOW,
        sanity = TUNING.SANITY_TINY,
        cooktime = 1,
        yotp = true,
    },

    nettlelosange =
    {
        test = function(cooker, names, tags) return tags.antihistamine and tags.antihistamine >= 3 end,
        priority = 0,
        foodtype = FOODTYPE.VEGGIE,
        health = TUNING.HEALING_MED,
        hunger = TUNING.CALORIES_MED,
        perishtime = TUNING.PERISH_FAST,
        sanity = TUNING.SANITY_TINY,
        antihistamine = 720,
        cooktime = .5,
        yotp = true,
        oneat_desc = STRINGS.UI.COOKBOOK.FOOD_EFFECTS_ANTIHISTAMINE,
    },

    meated_nettle =
    {
        test = function(cooker, names, tags) return (tags.antihistamine and tags.antihistamine >= 2) and (tags.meat and tags.meat >= 1) and (not tags.monster or tags.monster <= 1) and not tags.inedible end,
        priority = 1,
        foodtype = FOODTYPE.MEAT,
        health = TUNING.HEALING_MED,
        hunger = TUNING.CALORIES_LARGE,
        perishtime = TUNING.PERISH_FASTISH,
        sanity = TUNING.SANITY_TINY,
        antihistamine = 600,
        cooktime = 1,
        yotp = true,
        oneat_desc = STRINGS.UI.COOKBOOK.FOOD_EFFECTS_ANTIHISTAMINE,
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
