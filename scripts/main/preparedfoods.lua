local foods = {
    tea =
    {
        test = function(cooker, names, tags) return tags.filter and tags.filter >= 2 and tags.sweetener and not tags.meat and not tags.veggie and not tags.inedible end,
        priority = 25,
        foodtype = "VEGGIE",
        health = TUNING.HEALING_SMALL,
        hunger = TUNING.CALORIES_SMALL,
        perishtime = TUNING.PERISH_ONE_DAY,
        sanity = TUNING.SANITY_LARGE,
        caffeinedelta = TUNING.CAFFEINE_FOOD_BONUS_SPEED/2,
        caffeineduration = TUNING.FOOD_SPEED_LONG/2,
        temperaturebump = 15,
        cooktime = 0.5,
        spoiled_product = "icedtea",
        yotp = true,
    },

    icedtea =
    {
        test = function(cooker, names, tags) return tags.filter and tags.filter >= 2 and tags.sweetener and tags.frozen end,
        priority = 30,
        foodtype = "VEGGIE",
        health = TUNING.HEALING_SMALL,
        hunger = TUNING.CALORIES_SMALL,
        perishtime = TUNING.PERISH_FAST,
        sanity = TUNING.SANITY_LARGE,
        caffeinedelta = TUNING.CAFFEINE_FOOD_BONUS_SPEED/3,
        caffeineduration = TUNING.FOOD_SPEED_LONG/3,
        temperaturebump = -10,
        cooktime = 0.5,
        yotp = true,
    },
}

for k, v in pairs(foods) do
    v.name = k
    v.weight = v.weight or 1
    v.priority = v.priority or 0

    v.cookbook_category = "cookpot"
end

return foods
