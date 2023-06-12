local AddIngredientValues = AddIngredientValues
local AddCookerRecipe = AddCookerRecipe
GLOBAL.setfenv(1, GLOBAL)

require("util")
local cooking = require("cooking")

AddIngredientValues({"jellybug","jellybug_cooked"}, {bug=1}, true)
AddIngredientValues({"foliage","radish", "aloe"}, {veggie=1}, true)

AddIngredientValues({"cutnettle"}, {antihistamine=1})
AddIngredientValues({"snake_bone"}, {bone=1})
AddIngredientValues({"piko_orange"}, {filter=1})
AddIngredientValues({"slugbug"}, {bug=1}, true)
AddIngredientValues({"weevole_carapace"}, {inedible=1})

--cooking.GetRecipe("cookpot", "bonesoup").test = function(cooker, names, tags) return (names.boneshard or names.snake_bone) and names.boneshard == 2 and (names.onion or names.onion_cooked) and (tags.inedible and tags.inedible < 3) end

local foods = {
	
	nettlelosange =
	{
		test = function(cooker, names, tags) return tags.antihistamine and tags.antihistamine >= 3  end,
		priority = 0,
		foodtype = FOODTYPE.VEGGIE,
		health = TUNING.HEALING_MED,
		hunger = TUNING.CALORIES_MED,
		perishtime = TUNING.PERISH_FAST,
		sanity = TUNING.SANITY_TINY,
		antihistamine = 720,
		cooktime = .5,
		yotp = true,
		card_def = {ingredients = {{"cutnettle", 3}, {"radish", 1}} },
	},

	snakebonesoup = 
	{
		test = function(cooker, names, tags) return tags.bone and tags.bone >= 2 and tags.meat and tags.meat >= 2 end,
		priority = 20,
		foodtype = FOODTYPE.MEAT,
		health = TUNING.HEALING_LARGE,
		hunger = TUNING.CALORIES_MED,
		perishtime = TUNING.PERISH_MED,
		sanity = TUNING.SANITY_SMALL,
		cooktime = 1,
		yotp = true,
		card_def = {ingredients = {{"snake_bone", 2}, {"meat", 2}} },
	},

	tea = 
	{
		test = function(cooker, names, tags) return tags.filter and tags.filter >= 2 and tags.sweetener and not tags.meat and not tags.veggie and not tags.inedible end,
		priority = 25,
		foodtype = FOODTYPE.VEGGIE,
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
		card_def = {ingredients = {{"piko_orange", 2}, {"honey", 2}} },
	},	

	icedtea = 
	{
		test = function(cooker, names, tags) return tags.filter and tags.filter >= 2 and tags.sweetener and tags.frozen end,
		priority = 30,
		foodtype = FOODTYPE.VEGGIE,
		health = TUNING.HEALING_SMALL,
		hunger = TUNING.CALORIES_SMALL,
		perishtime = TUNING.PERISH_FAST,
		sanity = TUNING.SANITY_LARGE,
		caffeinedelta = TUNING.CAFFEINE_FOOD_BONUS_SPEED/3,
		caffeineduration = TUNING.FOOD_SPEED_LONG/3,		
		temperaturebump = -10,
		cooktime = 0.5,
		yotp = true,
		card_def = {ingredients = {{"piko_orange", 2}, {"honey", 1}, {"ice", 1}} },
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
		test = function(cooker, names, tags) return (names.weevole_carapace == 2) and  tags.veggie end,

		priority = 1,
		foodtype = FOODTYPE.VEGGIE,
		health = TUNING.HEALING_MED,
		hunger = TUNING.CALORIES_LARGE,
		perishtime = TUNING.PERISH_SLOW,
		sanity = TUNING.SANITY_TINY,
		cooktime = 1,
		yotp = true,
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
	
	meated_nettle = 
	{
		test = function(cooker, names, tags) return (tags.antihistamine and tags.antihistamine >=2) and (tags.meat and tags.meat >= 1) and (not tags.monster or tags.monster <= 1) and not tags.inedible end,
		priority = 1,
		foodtype = FOODTYPE.MEAT,
		health = TUNING.HEALING_MED,
		hunger = TUNING.CALORIES_LARGE,
		perishtime = TUNING.PERISH_FASTISH,
		sanity = TUNING.SANITY_TINY,
		antihistamine = 600,
		cooktime = 1,
		yotp = true,
	},
}

local warlyfoods = {}

for name, recipe in pairs (foods) do
	recipe.name = name
	recipe.weight = recipe.weight or 1
	recipe.priority = recipe.priority or 0
	--recipe.cookbook_atlas = "images/ia_cookbook.xml"		--- NEED ADD
	AddCookerRecipe("cookpot", recipe)
	AddCookerRecipe("portablecookpot", recipe)
	AddCookerRecipe("archive_cookpot", recipe)

	if recipe.card_def then
		AddRecipeCard("cookpot", recipe)
	end
end

for name, recipe in pairs(warlyfoods) do
	recipe.name = name
	recipe.weight = recipe.weight or 1
	recipe.priority = recipe.priority or 0
	--recipe.cookbook_atlas = "images/ia_cookbook.xml"		--- NEED ADD
	AddCookerRecipe("portablecookpot", recipe)
end

-- spice it!
local spicedfoods = shallowcopy(require("spicedfoods"))
GenerateSpicedFoods(foods)
GenerateSpicedFoods(warlyfoods)
local ia_spiced = {}
local new_spicedfoods = require("spicedfoods")
for k,v in pairs(new_spicedfoods) do
	if not spicedfoods[k] then
		ia_spiced[k] = v
	end
end
for k,v in pairs(ia_spiced) do
	new_spicedfoods[k] = nil --do not let the game make the prefabs
	AddCookerRecipe("portablespicer", v)
end

PL_PREPAREDFOODS = MergeMaps(foods, warlyfoods, ia_spiced)

----------------------------------------------------------------------------------------

--The following makes "portablecookpot" a synonym of "cookpot" and also implements Warly's unique recipes
local CalculateRecipe_old = cooking.CalculateRecipe
cooking.CalculateRecipe = function(cooker, names, ...)
	-- Spicer wetgoop fix! (in the unlikely case somebody has Gourmet food and a spicer at the same time)
	for k, v in pairs(names) do
		if v:sub(-8) == "_gourmet" then
			names[k] = v:sub(1, -9)
		end
	end

	if not IA_CONFIG.oldwarly then return CalculateRecipe_old(cooker, names, ...) end

	if cooker == "portablecookpot" then cooker = "cookpot" end
	local ret
	if cooking.enableWarly and cooker == "cookpot" then
		--TODO This includes meatballs n shit now
		ret = {CalculateRecipe_old("portablecookpot", names, ...)} --get Warly recipe
	end
	if not ret or not ret[1] then
		ret = {CalculateRecipe_old(cooker, names, ...)}
	end
	return unpack(ret)
end

--This can be called when the food is done, thus don't use cooking.enableWarly
local GetRecipe_old = cooking.GetRecipe
cooking.GetRecipe = function(cooker, ...)
	if not IA_CONFIG.oldwarly then return GetRecipe_old(cooker, ...) end

	if cooker == "portablecookpot" then cooker = "cookpot" end
	-- local ret
	-- if cooking.enableWarly and cooker == "cookpot" then
		-- ret = GetRecipe_old("portablecookpot", ...)
	-- end
	-- ret = ret or GetRecipe_old(cooker, ...) or GetRecipe_old("portablecookpot", ...)
	return GetRecipe_old(cooker, ...) or GetRecipe_old("portablecookpot", ...)
end
local IsModCookingProduct_old = IsModCookingProduct
IsModCookingProduct = function(cooker, ...)
	-- if not IA_CONFIG.oldwarly then return IsModCookingProduct_old(cooker, ...) end

	if cooker == "portablecookpot" then cooker = "cookpot" end
	return IsModCookingProduct_old(cooker, ...) or IsModCookingProduct_old("portablecookpot", ...)
end
