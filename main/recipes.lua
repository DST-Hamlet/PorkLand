local AddRecipe2 = AddRecipe2
local AddRecipePostInit = AddRecipePostInit
local AddDeconstructRecipe = AddDeconstructRecipe
local AddCharacterRecipe = AddCharacterRecipe
GLOBAL.setfenv(1, GLOBAL)

local function SortRecipe(a, b, filter_name, offset)
    local filter = CRAFTING_FILTERS[filter_name]
    if filter and filter.recipes then
        for sortvalue, product in ipairs(filter.recipes) do
            if product == a then
                table.remove(filter.recipes, sortvalue)
                break
            end
        end

        local target_position = #filter.recipes + 1
        for sortvalue, product in ipairs(filter.recipes) do
            if product == b then
                target_position = sortvalue + offset
                break
            end
        end

        table.insert(filter.recipes, target_position, a)
    end
end

local function SortBefore(a, b, filter_name)
    SortRecipe(a, b, filter_name, 0)
end

local function SortAfter(a, b, filter_name)
    SortRecipe(a, b, filter_name, 1)
end

local function AquaticRecipe(name, data)
    if AllRecipes[name] then
        --data = {distance=, shore_distance=, platform_distance=, shore_buffer_max=, shore_buffer_min=, platform_buffer_max=, platform_buffer_min=, aquatic_buffer_min=, noshore=}
        data = data or {}
        data.platform_buffer_max = data.platform_buffer_max or (data.platform_distance and math.sqrt(data.platform_distance)) or (data.distance and math.sqrt(data.distance)) or nil
        data.shore_buffer_max = data.shore_buffer_max or (data.shore_distance and ((data.shore_distance+1)/2)) or nil
        AllRecipes[name].aquatic = data
    end
end

AddRecipe2("machete",			{Ingredient("twigs", 1), Ingredient("flint", 3)}, 												TECH.NONE, 	 	  nil, {"TOOLS"})
AddRecipe2("goldenmachete",	 	{Ingredient("twigs", 4), Ingredient("goldnugget", 2)},											TECH.SCIENCE_TWO, nil, {"TOOLS"})

AddRecipe2("shears",			{Ingredient("twigs", 2), Ingredient("iron", 2)}, 												TECH.SCIENCE_ONE, nil, {"TOOLS"})
AddRecipe2("disarming_kit",	 	{Ingredient("iron", 2), Ingredient("cutreeds", 2)},												TECH.NONE, 		  nil, {"TOOLS"})
AddRecipe2("ballpein_hammer",	{Ingredient("iron", 2), Ingredient("twigs", 1)}, 												TECH.SCIENCE_ONE, nil, {"TOOLS"})
AddRecipe2("goldpan",			{Ingredient("iron", 2), Ingredient("hammer", 1)}, 												TECH.SCIENCE_ONE, nil, {"TOOLS"})
AddRecipe2("magnifying_glass",	{Ingredient("iron", 1), Ingredient("twigs", 1), Ingredient("bluegem", 1)},						TECH.SCIENCE_TWO, nil, {"TOOLS"})
AddRecipe2("bugrepellent",		{Ingredient("tuber_crop", 6), Ingredient("venus_stalk", 1)}, 									TECH.SCIENCE_ONE, nil, {"TOOLS"})
AddRecipe2("antler",			{Ingredient("bill_quill", 3), Ingredient("hippo_antler", 1), Ingredient("flint", 1)},			TECH.SCIENCE_ONE, nil, {"TOOLS"})

AddRecipe2("bathat",			{Ingredient("pigskin", 2), Ingredient("batwing", 1), Ingredient("compass", 1)},  				TECH.SCIENCE_TWO, nil, {"LIGHT"})
AddRecipe2("candlehat",			{Ingredient("cork", 4), Ingredient("iron", 2)}, 												TECH.SCIENCE_ONE, nil, {"LIGHT"})

AddRecipe2("clawpalmtree_sapling",	{Ingredient("cork", 1), Ingredient("poop", 1)},  											TECH.SCIENCE_ONE, nil, {"REFINE"})
AddRecipe2("goldnugget",		{Ingredient("gold_dust", 6)},  																	TECH.SCIENCE_ONE, nil, {"REFINE"})
AddRecipe2("venomgland",		{Ingredient("froglegs_poison", 3)},  															TECH.SCIENCE_TWO, nil, {"REFINE"})

AddRecipe2("armor_weevole",		{Ingredient("weevole_carapace", 4), Ingredient("chitin", 2)}, 									TECH.SCIENCE_TWO, nil, {"ARMOUR"})
AddRecipe2("antsuit",			{Ingredient("chitin", 5), Ingredient("armorwood", 1)}, 											TECH.SCIENCE_ONE, nil, {"ARMOUR"})
AddRecipe2("antmaskhat",		{Ingredient("chitin", 5), Ingredient("footballhat", 1)}, 										TECH.SCIENCE_ONE, nil, {"ARMOUR"})
AddRecipe2("metalplatehat",		{Ingredient("alloy", 3), Ingredient("cork", 3)}, 												TECH.SCIENCE_ONE, nil, {"ARMOUR"})
AddRecipe2("armor_metalplate",	{Ingredient("alloy", 3), Ingredient("hammer", 1)}, 												TECH.SCIENCE_ONE, nil, {"ARMOUR"})

AddRecipe2("halberd",			{Ingredient("alloy", 1), Ingredient("twigs", 2)}, 												TECH.SCIENCE_ONE, nil, {"WEAPONS"})
AddRecipe2("cork_bat",			{Ingredient("cork", 3), Ingredient("boards", 1)},  												TECH.SCIENCE_ONE, nil, {"WEAPONS"})
AddRecipe2("blunderbuss",		{Ingredient("oinc10", 1), Ingredient("boards", 2), Ingredient("gears", 1)}, 					TECH.SCIENCE_ONE, nil, {"WEAPONS"})

AddRecipe2("corkchest",			{Ingredient("cork", 2), Ingredient("rope", 1)}, 												TECH.SCIENCE_ONE, {min_spacing=1, placer="corkchest_placer"}, {"CONTAINERS"})
AddRecipe2("roottrunk_child",	{Ingredient("bramble_bulb", 1), Ingredient("venus_stalk", 2), Ingredient("boards", 2)},			TECH.SCIENCE_ONE, {min_spacing=1, placer="roottrunk_child_placer"}, {"CONTAINERS", "MAGIC", "STRUCTURES"})
AddRecipe2("smelter",			{Ingredient("cutstone", 6), Ingredient("boards", 4), Ingredient("redgem", 1)}, 					TECH.SCIENCE_TWO, {placer="smetler_placer"}, {"PROTOTYPERS", "STRUCTURES"})
AddRecipe2("basefan",			{Ingredient("alloy", 2), Ingredient("transistor", 2), Ingredient("gears", 1)},  				TECH.SCIENCE_TWO, {placer="basefan_placer"}, {"PROTOTYPERS", "RAIN", "STRUCTURES"})
AddRecipe2("sprinkler",			{Ingredient("alloy", 2), Ingredient("bluegem", 1), Ingredient("ice", 6)},  						TECH.SCIENCE_TWO, {placer="sprinkler_placer"}, {"GARDENING"})

AddRecipe2("disguisehat",		{Ingredient("twigs", 2), Ingredient("pigskin", 1), Ingredient("beardhair", 1)},  				TECH.SCIENCE_TWO, nil, {"CLOTHING"})
AddRecipe2("pithhat",			{Ingredient("fabric", 1), Ingredient("vine", 3), Ingredient("cork", 6)},  						TECH.SCIENCE_TWO, nil, {"CLOTHING"})
AddRecipe2("thunderhat", 		{Ingredient("feather_thunder", 1), Ingredient("goldnugget", 1), Ingredient("cork", 2)},  		TECH.SCIENCE_TWO, nil, {"CLOTHING"})
AddRecipe2("gasmaskhat",		{Ingredient("peagawkfeather", 4), Ingredient("fabric", 1), Ingredient("pigskin", 1)}, 			TECH.SCIENCE_ONE, nil, {"CLOTHING"})
AddRecipe2("snakeskinhat", 		{Ingredient("snakeskin_scaly", 1), Ingredient("strawhat", 1), Ingredient("boneshard", 1)},		TECH.SCIENCE_TWO, {image="snakeskinhat_scaly.tex"}, {"CLOTHING"})
AddRecipe2("armor_snakeskin", 	{Ingredient("snakeskin_scaly", 2), Ingredient("vine", 2), Ingredient("boneshard", 2)}, 			TECH.SCIENCE_ONE, {image="armor_snakeskin_scaly.tex"}, {"CLOTHING"})

AddRecipe2("hogusporkusator",	{Ingredient("pigskin", 4), Ingredient("boards", 4), Ingredient("feather_robin_winter", 4)},		TECH.MAGIC_ONE,   {placer="hogusporkusator_placer"}, {"MAGIC"})
AddRecipe2("armorvortexcloak",	{Ingredient("ancient_remnant", 5), Ingredient("armor_sanity", 1)},								TECH.LOST, 		  nil, {"MAGIC", "ARMOUR", "CONTAINERS"})
AddRecipe2("antler_corrupted",  {Ingredient("antler", 1), Ingredient("ancient_remnant", 2)}, 									TECH.MAGIC_TWO,   nil, {"MAGIC"})
AddRecipe2("living_artifact",	{Ingredient("infused_iron", 6), Ingredient("waterdrop", 1)},									TECH.LOST, 		  nil, {"MAGIC", "ARMOUR"})
AddRecipe2("bonestaff",			{Ingredient("pugalisk_skull", 1), Ingredient("boneshard", 1), Ingredient("nightmarefuel", 2)},	TECH.MAGIC_TWO,   nil, {"MAGIC", "WEAPONS"})

AddRecipe2("turf_lawn", 		{Ingredient("cutgrass", 2), Ingredient("nitre", 1)},											TECH.SCIENCE_TWO, nil, {"DECOR"})
AddRecipe2("turf_fields",		{Ingredient("turf_rainforest", 1), Ingredient("ash", 1)},										TECH.SCIENCE_TWO, nil, {"DECOR"})
AddRecipe2("turf_deeprainforest_nocanopy",	{Ingredient("bramble_bulb", 1), Ingredient("cutgrass", 2), Ingredient("ash", 1)},	TECH.SCIENCE_TWO, nil, {"DECOR", "GARDENING"})

AddRecipe2("boat_torch", 		{Ingredient("twigs", 2), Ingredient("torch", 1)}, 												TECH.SCIENCE_ONE, nil, {"LIGHT","SEAFARING"})
AddRecipe2("boatrepairkit", 	{Ingredient("boards", 2), Ingredient("stinger", 2), Ingredient("rope", 2)}, 					TECH.SCIENCE_ONE, nil, {"SEAFARING"})
AddRecipe2("snakeskinsail", 	{Ingredient("log", 4), Ingredient("rope", 2), Ingredient("snakeskin_scaly", 2)},				TECH.SCIENCE_TWO, {image="snakeskinsail_scaly.tex"}, {"SEAFARING"})
AddRecipe2("corkboat",			{Ingredient("rope", 1), Ingredient("cork", 4)},													TECH.NONE, 		  nil, {"SEAFARING"})
AddRecipe2("boat_lograft", 		{Ingredient("log", 6), Ingredient("cutgrass", 4)}, 												TECH.NONE, {image="lograft.tex",placer="boat_lograft_placer"}, 		{"SEAFARING"})
AddRecipe2("boat_row", 			{Ingredient("boards", 3), Ingredient("vine", 4)}, 												TECH.SCIENCE_ONE, {image="rowboat.tex",placer="boat_row_placer"}, 	{"SEAFARING"})
AddRecipe2("boat_cargo", 		{Ingredient("boards", 6), Ingredient("rope", 3)}, 												TECH.SCIENCE_TWO, {image="cargoboat.tex",placer="boat_cargo_placer"}, {"SEAFARING"})

AquaticRecipe("boat_row", 		{distance=4, platform_buffer_min=2})
AquaticRecipe("boat_lograft", 	{distance=4, platform_buffer_min=2})
AquaticRecipe("boat_cargo", 	{distance=4, platform_buffer_min=2})

--Sorting--
SortBefore("shears", "hammer", "TOOLS")
--SortAfter("machete", "pickaxe", "TOOLS") --don't work (
--SortAfter("goldenmachete", "goldenpickaxe", "TOOLS")--don't work (

SortAfter("boat_torch", "minerhat", "LIGHT")
SortAfter("bathat", "molehat", "LIGHT")
SortBefore("candlehat", "minerhat", "LIGHT")

SortAfter("smelter", "sculptingtable", "PROTOTYPERS")
SortAfter("basefan", "smelter", "PROTOTYPERS")

SortBefore("hogusporkusator", "researchlab4", "MAGIC")
SortAfter("armorvortexcloak", "armor_sanity", "MAGIC")
SortAfter("antler_corrupted", "armorvortexcloak", "MAGIC")
SortAfter("living_artifact", "antler_corrupted", "MAGIC")
SortAfter("roottrunk_child", "armorslurper", "MAGIC")
SortAfter("bonestaff", "icestaff", "MAGIC")

SortAfter("clawpalmtree_sapling", "cutstone", "REFINE")
SortAfter("goldnugget", "papyrus", "REFINE")
SortAfter("venomgland", "livinglog", "REFINE")

SortAfter("halberd", "spear", "WEAPONS")
SortBefore("cork_bat", "hambat", "WEAPONS")
SortAfter("blunderbuss", "staff_tornado", "WEAPONS")
SortAfter("bonestaff", "icestaff", "WEAPONS")

SortAfter("armor_weevole", "armormarble", "ARMOUR")
SortAfter("antmaskhat", "armor_weevole", "ARMOUR")
SortAfter("antsuit", "antmaskhat", "ARMOUR")
SortAfter("metalplatehat", "footballhat", "ARMOUR")
SortAfter("armor_metalplate", "metalplatehat", "ARMOUR")

SortAfter("disguisehat", "mermhat", "CLOTHING")

SortAfter("gasmaskhat", "catcoonhat", "CLOTHING")
SortAfter("pithhat", "watermelonhat", "CLOTHING")
SortAfter("thunderhat", "pithhat", "CLOTHING")
SortBefore("snakeskinhat", "raincoat", "CLOTHING")
SortAfter("armor_snakeskin", "raincoat", "CLOTHING")

SortBefore("boatrepairkit", "seafaring_prototyper", "SEAFARING")
SortAfter("corkboat", "boat_item", "SEAFARING")
SortAfter("boat_lograft", "corkboat", "SEAFARING")
SortAfter("boat_row", "boat_lograft", "SEAFARING")
SortAfter("boat_cargo", "boat_row", "SEAFARING")


------------------
------ CITY ------
------------------
AddRecipe2("turf_foundation",	 		{Ingredient("cutstone", 1)},															TECH.CITY_TWO, {nounlock=true, numtogive=4}, 											{"CRAFTING_STATION"})
AddRecipe2("turf_cobbleroad",	 		{Ingredient("cutstone", 2), Ingredient("boards", 1)},									TECH.CITY_TWO, {nounlock=true, numtogive=4}, 											{"CRAFTING_STATION"})
AddRecipe2("city_lamp",			 		{Ingredient("alloy", 1), Ingredient("transistor", 1), Ingredient("lantern",1)},			TECH.CITY_TWO, {nounlock=true, 				  placer="city_lamp_placer"}, 				{"CRAFTING_STATION"})
AddRecipe2("pighouse_city",		 		{Ingredient("boards", 4), Ingredient("cutstone", 3), Ingredient("pigskin", 4)},			TECH.CITY_TWO, {nounlock=true, min_spacing=1, placer="pighouse_city_placer"}, 			{"CRAFTING_STATION"})
AddRecipe2("pig_shop_deli",				{Ingredient("boards", 4), Ingredient("honeyham", 1), Ingredient("pigskin", 4)},			TECH.CITY_TWO, {nounlock=true, min_spacing=1, placer="pig_shop_deli_placer"}, 			{"CRAFTING_STATION"})
AddRecipe2("pig_shop_general",			{Ingredient("boards", 4), Ingredient("axe", 3), Ingredient("pigskin", 4)},				TECH.CITY_TWO, {nounlock=true, min_spacing=1, placer="pig_shop_general_placer"},		{"CRAFTING_STATION"})
AddRecipe2("pig_shop_hoofspa",			{Ingredient("boards", 4), Ingredient("bandage", 3), Ingredient("pigskin", 4)},			TECH.CITY_TWO, {nounlock=true, min_spacing=1, placer="pig_shop_hoofspa_placer"},		{"CRAFTING_STATION"})
AddRecipe2("pig_shop_produce",			{Ingredient("boards", 4), Ingredient("eggplant", 3), Ingredient("pigskin", 4)},			TECH.CITY_TWO, {nounlock=true, min_spacing=1, placer="pig_shop_produce_placer"},		{"CRAFTING_STATION"})
AddRecipe2("pig_shop_florist",			{Ingredient("boards", 4), Ingredient("petals", 12), Ingredient("pigskin", 4)},			TECH.CITY_TWO, {nounlock=true, min_spacing=1, placer="pig_shop_florist_placer"},		{"CRAFTING_STATION"})
AddRecipe2("pig_shop_antiquities",		{Ingredient("boards", 4), Ingredient("ballpein_hammer", 3), Ingredient("pigskin", 4)}, 	TECH.CITY_TWO, {nounlock=true, min_spacing=1, placer="pig_shop_antiquities_placer"}, 	{"CRAFTING_STATION"})
AddRecipe2("pig_shop_arcane",			{Ingredient("boards", 4), Ingredient("nightmarefuel", 1), Ingredient("pigskin", 4)},	TECH.CITY_TWO, {nounlock=true, min_spacing=1, placer="pig_shop_arcane_placer"}, 		{"CRAFTING_STATION"})
AddRecipe2("pig_shop_weapons",			{Ingredient("boards", 4), Ingredient("spear", 3), Ingredient("pigskin", 4)},			TECH.CITY_TWO, {nounlock=true, min_spacing=1, placer="pig_shop_weapons_placer"}, 		{"CRAFTING_STATION"})
AddRecipe2("pig_shop_hatshop",	 		{Ingredient("boards", 4), Ingredient("tophat", 2), Ingredient("pigskin", 4)},			TECH.CITY_TWO, {nounlock=true, min_spacing=1, placer="pig_shop_hatshop_placer"}, 		{"CRAFTING_STATION"})
AddRecipe2("pig_shop_bank",				{Ingredient("cutstone", 4), Ingredient("oinc", 100), Ingredient("pigskin", 4)},			TECH.CITY_TWO, {nounlock=true, min_spacing=1, placer="pig_shop_bank_placer"}, 			{"CRAFTING_STATION"})
AddRecipe2("pig_shop_tinker",			{Ingredient("magnifying_glass", 2), Ingredient("pigskin", 4)},							TECH.CITY_TWO, {nounlock=true, min_spacing=1, placer="pig_shop_tinker_placer"}, 		{"CRAFTING_STATION"})
AddRecipe2("pig_shop_cityhall_player",	{Ingredient("boards", 4), Ingredient("goldnugget", 4), Ingredient("pigskin", 4)},		TECH.CITY_TWO, {nounlock=true, min_spacing=1, placer="pig_shop_cityhall_placer"}, 		{"CRAFTING_STATION"})
AddRecipe2("pig_guard_tower",	 		{Ingredient("cutstone", 3), Ingredient("halberd", 1), Ingredient("pigskin", 4)},		TECH.CITY_TWO, {nounlock=true, min_spacing=1, placer="pig_guard_tower_placer"}, 		{"CRAFTING_STATION"})
AddRecipe2("playerhouse_city",			{Ingredient("boards", 4), Ingredient("cutstone", 3), Ingredient("oinc", 30)},			TECH.CITY_TWO, {nounlock=true, min_spacing=1, placer="deed_placer"}, 					{"CRAFTING_STATION"})
AddRecipe2("hedge_block_item",		 	{Ingredient("clippings", 9), Ingredient("nitre", 1)},									TECH.CITY_TWO, {nounlock=true, min_spacing=1, numtogive=3}, 							{"CRAFTING_STATION"})
AddRecipe2("hedge_cone_item",		 	{Ingredient("clippings", 9), Ingredient("nitre", 1)},									TECH.CITY_TWO, {nounlock=true, min_spacing=1, numtogive=3}, 							{"CRAFTING_STATION"})
AddRecipe2("hedge_layered_item",		{Ingredient("clippings", 9), Ingredient("nitre", 1)},									TECH.CITY_TWO, {nounlock=true, min_spacing=1, numtogive=3}, 							{"CRAFTING_STATION"})
AddRecipe2("pig_guard_tower",			{Ingredient("cutstone", 5), Ingredient("halberd", 1), Ingredient("pigskin", 4)},		TECH.CITY_TWO, {nounlock=true, min_spacing=1, placer="pig_guard_tower_placer"}, 		{"CRAFTING_STATION"})
AddRecipe2("securitycontract",	 		{Ingredient("oinc", 10)},																TECH.CITY_TWO, {nounlock=true}, 														{"CRAFTING_STATION"})
AddRecipe2("lawnornament_1",	 		{Ingredient("oinc", 10)},																TECH.CITY_TWO, {nounlock=true, min_spacing=1, placer="lawnornament_1_placer"}, 			{"CRAFTING_STATION"})
AddRecipe2("lawnornament_2",	 		{Ingredient("oinc", 10)},																TECH.CITY_TWO, {nounlock=true, min_spacing=1, placer="lawnornament_2_placer"}, 			{"CRAFTING_STATION"})
AddRecipe2("lawnornament_3",	 		{Ingredient("oinc", 10)},																TECH.CITY_TWO, {nounlock=true, min_spacing=1, placer="lawnornament_3_placer"}, 			{"CRAFTING_STATION"})
AddRecipe2("lawnornament_4",	 		{Ingredient("oinc", 10)},																TECH.CITY_TWO, {nounlock=true, min_spacing=1, placer="lawnornament_4_placer"}, 			{"CRAFTING_STATION"})
AddRecipe2("lawnornament_5",	 		{Ingredient("oinc", 10)},																TECH.CITY_TWO, {nounlock=true, min_spacing=1, placer="lawnornament_5_placer"}, 			{"CRAFTING_STATION"})
AddRecipe2("lawnornament_6",	 		{Ingredient("oinc", 10)},																TECH.CITY_TWO, {nounlock=true, min_spacing=1, placer="lawnornament_6_placer"}, 			{"CRAFTING_STATION"})
AddRecipe2("lawnornament_7",	 		{Ingredient("oinc", 10)},																TECH.CITY_TWO, {nounlock=true, min_spacing=1, placer="lawnornament_7_placer"}, 			{"CRAFTING_STATION"})

--[[
AddRecipe2("player_house_cottage_craft",		{Ingredient("oinc",10)}, TECH.HOME_TWO, {nounlock=true}, 																									{"CRAFTING_STATION"})
AddRecipe2("player_house_tudor_craft",			{Ingredient("oinc",10)}, TECH.HOME_TWO, {nounlock=true}, 																									{"CRAFTING_STATION"})
AddRecipe2("player_house_gothic_craft",			{Ingredient("oinc",10)}, TECH.HOME_TWO, {nounlock=true}, 																									{"CRAFTING_STATION"})
AddRecipe2("player_house_brick_craft",			{Ingredient("oinc",10)}, TECH.HOME_TWO, {nounlock=true}, 																									{"CRAFTING_STATION"})
AddRecipe2("player_house_turret_craft",			{Ingredient("oinc",10)}, TECH.HOME_TWO, {nounlock=true}, 																									{"CRAFTING_STATION"})
AddRecipe2("player_house_villa_craft",			{Ingredient("oinc",30)}, TECH.HOME_TWO, {nounlock=true}, 																									{"CRAFTING_STATION"})
AddRecipe2("player_house_manor_craft",			{Ingredient("oinc",30)}, TECH.HOME_TWO, {nounlock=true}, 																									{"CRAFTING_STATION"})

AddRecipe2("deco_chair_classic",				{Ingredient("oinc",2)},	 TECH.HOME_TWO, {nounlock=true, image="reno_chair_classic.tex",		placer="chair_classic_placer"},	 								{"CRAFTING_STATION"})
AddRecipe2("deco_chair_corner",					{Ingredient("oinc",2)},	 TECH.HOME_TWO, {nounlock=true, image="reno_chair_corner.tex",		placer="chair_corner_placer"},	 								{"CRAFTING_STATION"})
AddRecipe2("deco_chair_bench",					{Ingredient("oinc",2)},	 TECH.HOME_TWO, {nounlock=true, image="reno_chair_bench.tex",		placer="chair_bench_placer"},	 								{"CRAFTING_STATION"})
AddRecipe2("deco_chair_horned",					{Ingredient("oinc",2)},	 TECH.HOME_TWO, {nounlock=true, image="reno_chair_horned.tex",		placer="chair_horned_placer"},	 								{"CRAFTING_STATION"})
AddRecipe2("deco_chair_footrest",				{Ingredient("oinc",2)},	 TECH.HOME_TWO, {nounlock=true, image="reno_chair_footrest.tex",	placer="chair_footrest_placer"}, 								{"CRAFTING_STATION"})
AddRecipe2("deco_chair_lounge",					{Ingredient("oinc",2)},	 TECH.HOME_TWO, {nounlock=true, image="reno_chair_lounge.tex",		placer="chair_lounge_placer"},	 								{"CRAFTING_STATION"})
AddRecipe2("deco_chair_massager",				{Ingredient("oinc",2)},	 TECH.HOME_TWO, {nounlock=true, image="reno_chair_massager.tex",	placer="chair_massager_placer"}, 								{"CRAFTING_STATION"})
AddRecipe2("deco_chair_stuffed",				{Ingredient("oinc",2)},	 TECH.HOME_TWO, {nounlock=true, image="reno_chair_stuffed.tex",		placer="chair_stuffed_placer"},	 								{"CRAFTING_STATION"})
AddRecipe2("deco_chair_rocking",				{Ingredient("oinc",2)},	 TECH.HOME_TWO, {nounlock=true, image="reno_chair_rocking.tex",		placer="chair_rocking_placer"},	 								{"CRAFTING_STATION"})
AddRecipe2("deco_chair_ottoman",				{Ingredient("oinc",2)},	 TECH.HOME_TWO, {nounlock=true, image="reno_chair_ottoman.tex",		placer="chair_ottoman_placer"},	 								{"CRAFTING_STATION"})
AddRecipe2("deco_chaise",	 					{Ingredient("oinc",15)}, TECH.HOME_TWO, {nounlock=true, image="reno_chair_chaise.tex", 		placer="deco_chaise_placer"},	 								{"CRAFTING_STATION"})

AddRecipe2("shelves_wood",						{Ingredient("oinc",2)},	 TECH.HOME_TWO, {nounlock=true, image="reno_shelves_wood.tex"}, 																	{"CRAFTING_STATION"})
AddRecipe2("shelves_basic",						{Ingredient("oinc",2)},	 TECH.HOME_TWO, {nounlock=true, image="reno_shelves_basic.tex"}, 																	{"CRAFTING_STATION"})
AddRecipe2("shelves_cinderblocks", 				{Ingredient("oinc",1)},	 TECH.HOME_TWO, {nounlock=true, image="reno_shelves_cinderblocks.tex"}, 															{"CRAFTING_STATION"})
AddRecipe2("shelves_marble",					{Ingredient("oinc",8)},	 TECH.HOME_TWO, {nounlock=true, image="reno_shelves_marble.tex"}, 																	{"CRAFTING_STATION"})
AddRecipe2("shelves_glass",	 					{Ingredient("oinc",8)},	 TECH.HOME_TWO, {nounlock=true, image="reno_shelves_glass.tex"}, 																	{"CRAFTING_STATION"})
AddRecipe2("shelves_ladder",					{Ingredient("oinc",8)},	 TECH.HOME_TWO, {nounlock=true, image="reno_shelves_ladder.tex"}, 																	{"CRAFTING_STATION"})
AddRecipe2("shelves_hutch",	 					{Ingredient("oinc",8)},	 TECH.HOME_TWO, {nounlock=true, image="reno_shelves_hutch.tex"}, 																	{"CRAFTING_STATION"})
AddRecipe2("shelves_industrial",				{Ingredient("oinc",8)},	 TECH.HOME_TWO, {nounlock=true, image="reno_shelves_industrial.tex"},																{"CRAFTING_STATION"})
AddRecipe2("shelves_adjustable",				{Ingredient("oinc",8)},	 TECH.HOME_TWO, {nounlock=true, image="reno_shelves_adjustable.tex"}, 																{"CRAFTING_STATION"})
AddRecipe2("shelves_midcentury", 				{Ingredient("oinc",6)},	 TECH.HOME_TWO, {nounlock=true, image="reno_shelves_midcentury.tex"}, 																{"CRAFTING_STATION"})
AddRecipe2("shelves_wallmount",					{Ingredient("oinc",6)},	 TECH.HOME_TWO, {nounlock=true, image="reno_shelves_wallmount.tex"}, 																{"CRAFTING_STATION"})
AddRecipe2("shelves_aframe",					{Ingredient("oinc",6)},	 TECH.HOME_TWO, {nounlock=true, image="reno_shelves_aframe.tex"}, 																	{"CRAFTING_STATION"})
AddRecipe2("shelves_crates",					{Ingredient("oinc",6)},	 TECH.HOME_TWO, {nounlock=true, image="reno_shelves_crates.tex"}, 																	{"CRAFTING_STATION"})
AddRecipe2("shelves_fridge",					{Ingredient("oinc",6)},	 TECH.HOME_TWO, {nounlock=true, image="reno_shelves_fridge.tex"}, 																	{"CRAFTING_STATION"})
AddRecipe2("shelves_floating",					{Ingredient("oinc",6)},	 TECH.HOME_TWO, {nounlock=true, image="reno_shelves_floating.tex"}, 																{"CRAFTING_STATION"})
AddRecipe2("shelves_pipe",	 					{Ingredient("oinc",6)},	 TECH.HOME_TWO, {nounlock=true, image="reno_shelves_pipe.tex"}, 																	{"CRAFTING_STATION"})
AddRecipe2("shelves_hattree",					{Ingredient("oinc",6)},	 TECH.HOME_TWO, {nounlock=true, image="reno_shelves_hattree.tex"}, 																	{"CRAFTING_STATION"})
AddRecipe2("shelves_pallet",					{Ingredient("oinc",6)},	 TECH.HOME_TWO, {nounlock=true, image="reno_shelves_pallet.tex"}, 																	{"CRAFTING_STATION"})

AddRecipe2("rug_round",							{Ingredient("oinc",2)},	 TECH.HOME_TWO, {nounlock=true, image="reno_rug_round.tex",		placer="rug_round_placer"},	 										{"CRAFTING_STATION"})
AddRecipe2("rug_square",						{Ingredient("oinc",2)},	 TECH.HOME_TWO, {nounlock=true, image="reno_rug_square.tex",	placer="rug_square_placer"},										{"CRAFTING_STATION"})
AddRecipe2("rug_oval",							{Ingredient("oinc",2)},	 TECH.HOME_TWO, {nounlock=true, image="reno_rug_oval.tex",		placer="rug_oval_placer"},	 										{"CRAFTING_STATION"})
AddRecipe2("rug_rectangle",						{Ingredient("oinc",3)},	 TECH.HOME_TWO, {nounlock=true, image="reno_rug_rectangle.tex",	placer="rug_rectangle_placer"},										{"CRAFTING_STATION"})
AddRecipe2("rug_fur",							{Ingredient("oinc",5)},	 TECH.HOME_TWO, {nounlock=true, image="reno_rug_fur.tex",		placer="rug_fur_placer"},	 										{"CRAFTING_STATION"})
AddRecipe2("rug_hedgehog",						{Ingredient("oinc",5)},	 TECH.HOME_TWO, {nounlock=true, image="reno_rug_hedgehog.tex",	placer="rug_hedgehog_placer"},										{"CRAFTING_STATION"})
AddRecipe2("rug_porcupuss",						{Ingredient("oinc",10)}, TECH.HOME_TWO, {nounlock=true, image="reno_rug_porcupuss.tex",	placer="rug_porcupuss_placer"},										{"CRAFTING_STATION"})
AddRecipe2("rug_hoofprint",						{Ingredient("oinc",5)},	 TECH.HOME_TWO, {nounlock=true, image="reno_rug_hoofprint.tex",	placer="rug_hoofprint_placer"},										{"CRAFTING_STATION"})
AddRecipe2("rug_octagon",						{Ingredient("oinc",5)},	 TECH.HOME_TWO, {nounlock=true, image="reno_rug_octagon.tex",	placer="rug_octagon_placer"},										{"CRAFTING_STATION"})
AddRecipe2("rug_swirl",	 						{Ingredient("oinc",5)},	 TECH.HOME_TWO, {nounlock=true, image="reno_rug_swirl.tex",		placer="rug_swirl_placer"},	 										{"CRAFTING_STATION"})
AddRecipe2("rug_catcoon",						{Ingredient("oinc",5)},	 TECH.HOME_TWO, {nounlock=true, image="reno_rug_catcoon.tex",	placer="rug_catcoon_placer"},										{"CRAFTING_STATION"})
AddRecipe2("rug_rubbermat",						{Ingredient("oinc",5)},	 TECH.HOME_TWO, {nounlock=true, image="reno_rug_rubbermat.tex",	placer="rug_rubbermat_placer"},										{"CRAFTING_STATION"})
AddRecipe2("rug_web",	 						{Ingredient("oinc",5)},	 TECH.HOME_TWO, {nounlock=true, image="reno_rug_web.tex",		placer="rug_web_placer"},	 										{"CRAFTING_STATION"})
AddRecipe2("rug_metal",	 						{Ingredient("oinc",5)},	 TECH.HOME_TWO, {nounlock=true, image="reno_rug_metal.tex",		placer="rug_metal_placer"},	 										{"CRAFTING_STATION"})
AddRecipe2("rug_wormhole",						{Ingredient("oinc",5)},	 TECH.HOME_TWO, {nounlock=true, image="reno_rug_wormhole.tex",	placer="rug_wormhole_placer"},										{"CRAFTING_STATION"})
AddRecipe2("rug_braid",	 						{Ingredient("oinc",5)},	 TECH.HOME_TWO, {nounlock=true, image="reno_rug_braid.tex",		placer="rug_braid_placer"},	 										{"CRAFTING_STATION"})
AddRecipe2("rug_beard",	 						{Ingredient("oinc",5)},	 TECH.HOME_TWO, {nounlock=true, image="reno_rug_beard.tex",		placer="rug_beard_placer"},	 										{"CRAFTING_STATION"})
AddRecipe2("rug_nailbed",						{Ingredient("oinc",5)},	 TECH.HOME_TWO, {nounlock=true, image="reno_rug_nailbed.tex",	placer="rug_nailbed_placer"},										{"CRAFTING_STATION"})
AddRecipe2("rug_crime",	 						{Ingredient("oinc",5)},	 TECH.HOME_TWO, {nounlock=true, image="reno_rug_crime.tex",		placer="rug_crime_placer"},	 										{"CRAFTING_STATION"})
AddRecipe2("rug_tiles",	 						{Ingredient("oinc",5)},	 TECH.HOME_TWO, {nounlock=true, image="reno_rug_tiles.tex",		placer="rug_tiles_placer"},	 										{"CRAFTING_STATION"})

AddRecipe2("deco_lamp_fringe",        			{Ingredient("oinc",8)},  TECH.HOME_TWO, {nounlock=true, image="reno_lamp_fringe.tex",		placer="deco_lamp_fringe_placer"},	 							{"CRAFTING_STATION"})
AddRecipe2("deco_lamp_stainglass",    			{Ingredient("oinc",8)},  TECH.HOME_TWO, {nounlock=true, image="reno_lamp_stainglass.tex",	placer="deco_lamp_stainglass_placer"},							{"CRAFTING_STATION"})
AddRecipe2("deco_lamp_downbridge",    			{Ingredient("oinc",8)},  TECH.HOME_TWO, {nounlock=true, image="reno_lamp_downbridge.tex",	placer="deco_lamp_downbridge_placer"},							{"CRAFTING_STATION"})
AddRecipe2("deco_lamp_2embroidered",  			{Ingredient("oinc",8)},  TECH.HOME_TWO, {nounlock=true, image="reno_lamp_2embroidered.tex",	placer="deco_lamp_2embroidered_placer"},						{"CRAFTING_STATION"})
AddRecipe2("deco_lamp_ceramic",       			{Ingredient("oinc",8)},  TECH.HOME_TWO, {nounlock=true, image="reno_lamp_ceramic.tex",		placer="deco_lamp_ceramic_placer"},	 							{"CRAFTING_STATION"})
AddRecipe2("deco_lamp_glass",         			{Ingredient("oinc",8)},  TECH.HOME_TWO, {nounlock=true, image="reno_lamp_glass.tex",		placer="deco_lamp_glass_placer"},	 							{"CRAFTING_STATION"})
AddRecipe2("deco_lamp_2fringes",      			{Ingredient("oinc",8)},  TECH.HOME_TWO, {nounlock=true, image="reno_lamp_2fringes.tex",		placer="deco_lamp_2fringes_placer"},							{"CRAFTING_STATION"})
AddRecipe2("deco_lamp_candelabra",    			{Ingredient("oinc",8)},  TECH.HOME_TWO, {nounlock=true, image="reno_lamp_candelabra.tex",	placer="deco_lamp_candelabra_placer"},							{"CRAFTING_STATION"})
AddRecipe2("deco_lamp_elizabethan",   			{Ingredient("oinc",8)},  TECH.HOME_TWO, {nounlock=true, image="reno_lamp_elizabethan.tex",	placer="deco_lamp_elizabethan_placer"},							{"CRAFTING_STATION"})
AddRecipe2("deco_lamp_gothic",        			{Ingredient("oinc",8)},  TECH.HOME_TWO, {nounlock=true, image="reno_lamp_gothic.tex",		placer="deco_lamp_gothic_placer"},	 							{"CRAFTING_STATION"})
AddRecipe2("deco_lamp_orb",           			{Ingredient("oinc",8)},  TECH.HOME_TWO, {nounlock=true, image="reno_lamp_orb.tex",			placer="deco_lamp_orb_placer"},	 								{"CRAFTING_STATION"})
AddRecipe2("deco_lamp_bellshade",     			{Ingredient("oinc",8)},  TECH.HOME_TWO, {nounlock=true, image="reno_lamp_bellshade.tex",	placer="deco_lamp_bellshade_placer"},							{"CRAFTING_STATION"})
AddRecipe2("deco_lamp_crystals",      			{Ingredient("oinc",8)},  TECH.HOME_TWO, {nounlock=true, image="reno_lamp_crystals.tex",		placer="deco_lamp_crystals_placer"},							{"CRAFTING_STATION"})
AddRecipe2("deco_lamp_upturn",        			{Ingredient("oinc",8)},  TECH.HOME_TWO, {nounlock=true, image="reno_lamp_upturn.tex",		placer="deco_lamp_upturn_placer"},								{"CRAFTING_STATION"})
AddRecipe2("deco_lamp_2upturns",      			{Ingredient("oinc",8)},  TECH.HOME_TWO, {nounlock=true, image="reno_lamp_2upturns.tex",		placer="deco_lamp_2upturns_placer"},							{"CRAFTING_STATION"})
AddRecipe2("deco_lamp_spool",         			{Ingredient("oinc",8)},  TECH.HOME_TWO, {nounlock=true, image="reno_lamp_spool.tex",		placer="deco_lamp_spool_placer"},								{"CRAFTING_STATION"})
AddRecipe2("deco_lamp_edison",        			{Ingredient("oinc",8)},  TECH.HOME_TWO, {nounlock=true, image="reno_lamp_edison.tex",		placer="deco_lamp_edison_placer"},								{"CRAFTING_STATION"})
AddRecipe2("deco_lamp_adjustable",    			{Ingredient("oinc",8)},  TECH.HOME_TWO, {nounlock=true, image="reno_lamp_adjustable.tex",	placer="deco_lamp_adjustable_placer"},							{"CRAFTING_STATION"})
AddRecipe2("deco_lamp_rightangles",   			{Ingredient("oinc",8)},  TECH.HOME_TWO, {nounlock=true, image="reno_lamp_rightangles.tex",	placer="deco_lamp_rightangles_placer"},							{"CRAFTING_STATION"})
AddRecipe2("deco_lamp_hoofspa",  				{Ingredient("oinc",8)},  TECH.HOME_TWO, {nounlock=true, image="reno_lamp_hoofspa.tex",		placer="deco_lamp_hoofspa_placer"},	 							{"CRAFTING_STATION"})
	
AddRecipe2("deco_plantholder_basic",        	{Ingredient("oinc",6)},  TECH.HOME_TWO, {nounlock=true, image="reno_plantholder_basic.tex",			placer="deco_plantholder_basic_placer"},	 			{"CRAFTING_STATION"})
AddRecipe2("deco_plantholder_wip",          	{Ingredient("oinc",6)},  TECH.HOME_TWO, {nounlock=true, image="reno_plantholder_wip.tex",			placer="deco_plantholder_wip_placer"},	 				{"CRAFTING_STATION"})
AddRecipe2("deco_plantholder_marble",        	{Ingredient("oinc",6)},  TECH.HOME_TWO, {nounlock=true, image="reno_plantholder_marble.tex",		placer="deco_plantholder_marble_placer"},	 			{"CRAFTING_STATION"})
AddRecipe2("deco_plantholder_bonsai",       	{Ingredient("oinc",6)},  TECH.HOME_TWO, {nounlock=true, image="reno_plantholder_bonsai.tex",		placer="deco_plantholder_bonsai_placer"},	 			{"CRAFTING_STATION"})
AddRecipe2("deco_plantholder_dishgarden",   	{Ingredient("oinc",6)},  TECH.HOME_TWO, {nounlock=true, image="reno_plantholder_dishgarden.tex",	placer="deco_plantholder_dishgarden_placer"},			{"CRAFTING_STATION"})
AddRecipe2("deco_plantholder_philodendron",		{Ingredient("oinc",6)},  TECH.HOME_TWO, {nounlock=true, image="reno_plantholder_philodendron.tex",	placer="deco_plantholder_philodendron_placer"},			{"CRAFTING_STATION"})
AddRecipe2("deco_plantholder_orchid",       	{Ingredient("oinc",6)},  TECH.HOME_TWO, {nounlock=true, image="reno_plantholder_orchid.tex",		placer="deco_plantholder_orchid_placer"},				{"CRAFTING_STATION"})
AddRecipe2("deco_plantholder_draceana",     	{Ingredient("oinc",6)},  TECH.HOME_TWO, {nounlock=true, image="reno_plantholder_draceana.tex",		placer="deco_plantholder_draceana_placer"},				{"CRAFTING_STATION"})
AddRecipe2("deco_plantholder_xerographica",		{Ingredient("oinc",6)},  TECH.HOME_TWO, {nounlock=true, image="reno_plantholder_xerographica.tex",	placer="deco_plantholder_xerographica_placer"},			{"CRAFTING_STATION"})
AddRecipe2("deco_plantholder_birdcage",     	{Ingredient("oinc",6)},  TECH.HOME_TWO, {nounlock=true, image="reno_plantholder_birdcage.tex",		placer="deco_plantholder_birdcage_placer"},				{"CRAFTING_STATION"})
AddRecipe2("deco_plantholder_palm",         	{Ingredient("oinc",6)},  TECH.HOME_TWO, {nounlock=true, image="reno_plantholder_palm.tex",			placer="deco_plantholder_palm_placer"},	 				{"CRAFTING_STATION"})
AddRecipe2("deco_plantholder_zz",           	{Ingredient("oinc",6)},  TECH.HOME_TWO, {nounlock=true, image="reno_plantholder_zz.tex",			placer="deco_plantholder_zz_placer"},	 				{"CRAFTING_STATION"})
AddRecipe2("deco_plantholder_fernstand",    	{Ingredient("oinc",6)},  TECH.HOME_TWO, {nounlock=true, image="reno_plantholder_fernstand.tex",		placer="deco_plantholder_fernstand_placer"},			{"CRAFTING_STATION"})
AddRecipe2("deco_plantholder_fern",         	{Ingredient("oinc",6)},  TECH.HOME_TWO, {nounlock=true, image="reno_plantholder_fern.tex",			placer="deco_plantholder_fern_placer"},	 				{"CRAFTING_STATION"})
AddRecipe2("deco_plantholder_terrarium",    	{Ingredient("oinc",6)},  TECH.HOME_TWO, {nounlock=true, image="reno_plantholder_terrarium.tex",		placer="deco_plantholder_terrarium_placer"},			{"CRAFTING_STATION"})
AddRecipe2("deco_plantholder_plantpet",     	{Ingredient("oinc",6)},  TECH.HOME_TWO, {nounlock=true, image="reno_plantholder_plantpet.tex",		placer="deco_plantholder_plantpet_placer"},	 			{"CRAFTING_STATION"})
AddRecipe2("deco_plantholder_traps",        	{Ingredient("oinc",6)},  TECH.HOME_TWO, {nounlock=true, image="reno_plantholder_traps.tex",			placer="deco_plantholder_traps_placer"},	 			{"CRAFTING_STATION"})
AddRecipe2("deco_plantholder_pitchers",     	{Ingredient("oinc",6)},  TECH.HOME_TWO, {nounlock=true, image="reno_plantholder_pitchers.tex",		placer="deco_plantholder_pitchers_placer"},	 			{"CRAFTING_STATION"})

AddRecipe2("deco_plantholder_winterfeasttreeofsadness", {Ingredient("oinc",2),Ingredient("twigs",1)},	TECH.HOME_TWO, {nounlock=true, image="reno_plantholder_winterfeasttreeofsadness.tex",	placer="deco_plantholder_winterfeasttreeofsadness_placer"},	{"CRAFTING_STATION"})
AddRecipe2("deco_plantholder_winterfeasttree",     		{Ingredient("oinc",50)},						TECH.HOME_TWO, {nounlock=true, image="reno_lamp_festivetree.tex",	placer="deco_plantholder_winterfeasttree_placer"},	 	{"CRAFTING_STATION"})

AddRecipe2("deco_table_round",					{Ingredient("oinc",2)},  TECH.HOME_TWO, {nounlock=true, image="reno_table_round.tex",					placer="deco_table_round_placer"},					{"CRAFTING_STATION"})
AddRecipe2("deco_table_banker",					{Ingredient("oinc",4)},  TECH.HOME_TWO, {nounlock=true, image="reno_table_banker.tex",					placer="deco_table_banker_placer"},					{"CRAFTING_STATION"})
AddRecipe2("deco_table_diy",					{Ingredient("oinc",3)},  TECH.HOME_TWO, {nounlock=true, image="reno_table_diy.tex",						placer="deco_table_diy_placer"},	 				{"CRAFTING_STATION"})
AddRecipe2("deco_table_raw",					{Ingredient("oinc",1)},  TECH.HOME_TWO, {nounlock=true, image="reno_table_raw.tex",						placer="deco_table_raw_placer"},	 				{"CRAFTING_STATION"})
AddRecipe2("deco_table_crate",					{Ingredient("oinc",1)},  TECH.HOME_TWO, {nounlock=true, image="reno_table_crate.tex",					placer="deco_table_crate_placer"},					{"CRAFTING_STATION"})
AddRecipe2("deco_table_chess",					{Ingredient("oinc",1)},  TECH.HOME_TWO, {nounlock=true, image="reno_table_chess.tex",					placer="deco_table_chess_placer"},					{"CRAFTING_STATION"})

AddRecipe2("deco_wallornament_photo",			{Ingredient("oinc",2)},	 TECH.HOME_TWO, {nounlock=true, image="reno_wallornament_photo.tex",			placer="deco_wallornament_photo_placer"}, 			{"CRAFTING_STATION"})
AddRecipe2("deco_wallornament_embroidery_hoop",	{Ingredient("oinc",3)},	 TECH.HOME_TWO, {nounlock=true, image="reno_wallornament_embroidery_hoop.tex",	placer="deco_wallornament_embroidery_hoop_placer"}, {"CRAFTING_STATION"})
AddRecipe2("deco_wallornament_mosaic",			{Ingredient("oinc",4)},	 TECH.HOME_TWO, {nounlock=true, image="reno_wallornament_mosaic.tex",			placer="deco_wallornament_mosaic_placer"}, 			{"CRAFTING_STATION"})
AddRecipe2("deco_wallornament_wreath",			{Ingredient("oinc",4)},	 TECH.HOME_TWO, {nounlock=true, image="reno_wallornament_wreath.tex",			placer="deco_wallornament_wreath_placer"}, 			{"CRAFTING_STATION"})
AddRecipe2("deco_wallornament_axe",				{Ingredient("oinc",5)},  TECH.HOME_TWO, {nounlock=true, image="reno_wallornament_axe.tex",				placer="deco_wallornament_axe_placer"}, 			{"CRAFTING_STATION"})
AddRecipe2("deco_wallornament_hunt",			{Ingredient("oinc",5)},  TECH.HOME_TWO, {nounlock=true, image="reno_wallornament_hunt.tex",				placer="deco_wallornament_hunt_placer"}, 			{"CRAFTING_STATION"})
AddRecipe2("deco_wallornament_periodic_table", 	{Ingredient("oinc",5)},  TECH.HOME_TWO, {nounlock=true, image="reno_wallornament_periodic_table.tex",	placer="deco_wallornament_periodic_table_placer"}, 	{"CRAFTING_STATION"})
AddRecipe2("deco_wallornament_gears_art",		{Ingredient("oinc",8)},  TECH.HOME_TWO, {nounlock=true, image="reno_wallornament_gears_art.tex",		placer="deco_wallornament_gears_art_placer"}, 		{"CRAFTING_STATION"})
AddRecipe2("deco_wallornament_cape",			{Ingredient("oinc",5)},  TECH.HOME_TWO, {nounlock=true, image="reno_wallornament_cape.tex",				placer="deco_wallornament_cape_placer"}, 			{"CRAFTING_STATION"})
AddRecipe2("deco_wallornament_no_smoking",		{Ingredient("oinc",3)},  TECH.HOME_TWO, {nounlock=true, image="reno_wallornament_no_smoking.tex",		placer="deco_wallornament_no_smoking_placer"}, 		{"CRAFTING_STATION"})
AddRecipe2("deco_wallornament_black_cat",		{Ingredient("oinc",5)},  TECH.HOME_TWO, {nounlock=true, image="reno_wallornament_black_cat.tex",		placer="deco_wallornament_black_cat_placer"}, 		{"CRAFTING_STATION"})
AddRecipe2("deco_antiquities_wallfish",			{Ingredient("oinc",2),	Ingredient("fish",1)},	TECH.HOME_TWO, {nounlock=true, image="reno_antiquities_wallfish.tex", placer="deco_antiquities_wallfish_placer"}, 	{"CRAFTING_STATION"})
AddRecipe2("deco_antiquities_beefalo",			{Ingredient("oinc",10),	Ingredient("horn",1)},	TECH.HOME_TWO, {nounlock=true, image="reno_antiquities_beefalo.tex",  placer="deco_antiquities_beefalo_placer"},	{"CRAFTING_STATION"})

AddRecipe2("window_small_peaked_curtain", 		{Ingredient("oinc",3)},  TECH.HOME_TWO, {nounlock=true, image="reno_window_small_peaked_curtain.tex",	placer="window_small_peaked_curtain_placer"}, 		{"CRAFTING_STATION"})
AddRecipe2("window_round_burlap",				{Ingredient("oinc",3)},  TECH.HOME_TWO, {nounlock=true, image="reno_window_round_burlap.tex",			placer="window_round_burlap_placer"}, 				{"CRAFTING_STATION"})
AddRecipe2("window_small_peaked",				{Ingredient("oinc",3)},  TECH.HOME_TWO, {nounlock=true, image="reno_window_small_peaked.tex",			placer="window_small_peaked_placer"}, 				{"CRAFTING_STATION"})
AddRecipe2("window_large_square",				{Ingredient("oinc",4)},  TECH.HOME_TWO, {nounlock=true, image="reno_window_large_square.tex",			placer="window_large_square_placer"}, 				{"CRAFTING_STATION"})
AddRecipe2("window_tall",	 					{Ingredient("oinc",4)},  TECH.HOME_TWO, {nounlock=true, image="reno_window_tall.tex",					placer="window_tall_placer"}, 						{"CRAFTING_STATION"})
AddRecipe2("window_large_square_curtain", 		{Ingredient("oinc",5)},  TECH.HOME_TWO, {nounlock=true, image="reno_window_large_square_curtain.tex",	placer="window_large_square_curtain_placer"}, 		{"CRAFTING_STATION"})
AddRecipe2("window_tall_curtain",				{Ingredient("oinc",5)},  TECH.HOME_TWO, {nounlock=true, image="reno_window_tall_curtain.tex",			placer="window_tall_curtain_placer"}, 				{"CRAFTING_STATION"})
AddRecipe2("window_greenhouse",					{Ingredient("oinc",8)},  TECH.HOME_TWO, {nounlock=true, image="reno_window_greenhouse.tex",				placer="window_greenhouse_placer"}, 				{"CRAFTING_STATION"})

AddRecipe2("deco_wood",							{Ingredient("oinc",1)},  TECH.HOME_TWO, {nounlock=true, image="reno_cornerbeam_wood.tex",				placer="deco_cornerbeam_wood_placer"}, 				{"CRAFTING_STATION"})
AddRecipe2("deco_millinery",	 				{Ingredient("oinc",1)},  TECH.HOME_TWO, {nounlock=true, image="reno_cornerbeam_millinery.tex",			placer="deco_cornerbeam_millinery_placer"}, 		{"CRAFTING_STATION"})
AddRecipe2("deco_round",		 				{Ingredient("oinc",1)},  TECH.HOME_TWO, {nounlock=true, image="reno_cornerbeam_round.tex",				placer="deco_cornerbeam_round_placer"}, 			{"CRAFTING_STATION"})
AddRecipe2("deco_marble",						{Ingredient("oinc",5)},  TECH.HOME_TWO, {nounlock=true, image="reno_cornerbeam_marble.tex",				placer="deco_cornerbeam_marble_placer"}, 			{"CRAFTING_STATION"})

AddRecipe2("interior_floor_wood",				{Ingredient("oinc",5)},  TECH.HOME_TWO, {nounlock=true}, {"CRAFTING_STATION"})
AddRecipe2("interior_floor_marble",				{Ingredient("oinc",15)}, TECH.HOME_TWO, {nounlock=true}, {"CRAFTING_STATION"})
AddRecipe2("interior_floor_check",				{Ingredient("oinc",7)},  TECH.HOME_TWO, {nounlock=true}, {"CRAFTING_STATION"})
AddRecipe2("interior_floor_plaid_tile",			{Ingredient("oinc",10)}, TECH.HOME_TWO, {nounlock=true}, {"CRAFTING_STATION"})
AddRecipe2("interior_floor_sheet_metal",		{Ingredient("oinc",6)},	 TECH.HOME_TWO, {nounlock=true}, {"CRAFTING_STATION"})
AddRecipe2("interior_floor_gardenstone", 		{Ingredient("oinc",10)}, TECH.HOME_TWO, {nounlock=true}, {"CRAFTING_STATION"})
AddRecipe2("interior_floor_geometrictiles", 	{Ingredient("oinc",12)}, TECH.HOME_TWO, {nounlock=true}, {"CRAFTING_STATION"})
AddRecipe2("interior_floor_shag_carpet", 		{Ingredient("oinc",6)},	 TECH.HOME_TWO, {nounlock=true}, {"CRAFTING_STATION"})
AddRecipe2("interior_floor_transitional", 		{Ingredient("oinc",6)},	 TECH.HOME_TWO, {nounlock=true}, {"CRAFTING_STATION"})
AddRecipe2("interior_floor_woodpanels", 		{Ingredient("oinc",10)}, TECH.HOME_TWO, {nounlock=true}, {"CRAFTING_STATION"})
AddRecipe2("interior_floor_herringbone", 		{Ingredient("oinc",12)}, TECH.HOME_TWO, {nounlock=true}, {"CRAFTING_STATION"})
AddRecipe2("interior_floor_hexagon",	 		{Ingredient("oinc",12)}, TECH.HOME_TWO, {nounlock=true}, {"CRAFTING_STATION"})
AddRecipe2("interior_floor_hoof_curvy",	 		{Ingredient("oinc",12)}, TECH.HOME_TWO, {nounlock=true}, {"CRAFTING_STATION"})
AddRecipe2("interior_floor_octagon",	 		{Ingredient("oinc",12)}, TECH.HOME_TWO, {nounlock=true}, {"CRAFTING_STATION"})

AddRecipe2("interior_wall_wood", 				{Ingredient("oinc",1)},	 TECH.HOME_TWO, {nounlock=true}, {"CRAFTING_STATION"})
AddRecipe2("interior_wall_checkered", 			{Ingredient("oinc",6)},	 TECH.HOME_TWO, {nounlock=true}, {"CRAFTING_STATION"})
AddRecipe2("interior_wall_floral", 				{Ingredient("oinc",6)},	 TECH.HOME_TWO, {nounlock=true}, {"CRAFTING_STATION"})
AddRecipe2("interior_wall_sunflower", 			{Ingredient("oinc",6)},	 TECH.HOME_TWO, {nounlock=true}, {"CRAFTING_STATION"})
AddRecipe2("interior_wall_harlequin", 			{Ingredient("oinc",10)}, TECH.HOME_TWO, {nounlock=true}, {"CRAFTING_STATION"})
AddRecipe2("interior_wall_peagawk", 			{Ingredient("oinc",6)},  TECH.HOME_TWO, {nounlock=true}, {"CRAFTING_STATION"})
AddRecipe2("interior_wall_plain_ds", 			{Ingredient("oinc",4)},  TECH.HOME_TWO, {nounlock=true}, {"CRAFTING_STATION"})
AddRecipe2("interior_wall_plain_rog", 			{Ingredient("oinc",4)},  TECH.HOME_TWO, {nounlock=true}, {"CRAFTING_STATION"})
AddRecipe2("interior_wall_rope", 				{Ingredient("oinc",6)},  TECH.HOME_TWO, {nounlock=true}, {"CRAFTING_STATION"})
AddRecipe2("interior_wall_circles", 			{Ingredient("oinc",10)}, TECH.HOME_TWO, {nounlock=true}, {"CRAFTING_STATION"})
AddRecipe2("interior_wall_marble", 				{Ingredient("oinc",15)}, TECH.HOME_TWO, {nounlock=true}, {"CRAFTING_STATION"})
AddRecipe2("interior_wall_mayorsoffice",		{Ingredient("oinc",15)}, TECH.HOME_TWO, {nounlock=true}, {"CRAFTING_STATION"})
AddRecipe2("interior_wall_fullwall_moulding",	{Ingredient("oinc",15)}, TECH.HOME_TWO, {nounlock=true}, {"CRAFTING_STATION"})
AddRecipe2("interior_wall_upholstered",			{Ingredient("oinc",8)},  TECH.HOME_TWO, {nounlock=true}, {"CRAFTING_STATION"})

AddRecipe2("swinging_light_basic_bulb",			{Ingredient("oinc",5)},	 TECH.HOME_TWO, {nounlock=true, image="reno_light_basic_bulb.tex",			placer="swinging_light_basic_bulb_placer"},	 			{"CRAFTING_STATION"})
AddRecipe2("swinging_light_basic_metal",		{Ingredient("oinc",6)},  TECH.HOME_TWO, {nounlock=true, image="reno_light_basic_metal.tex",			placer="swinging_light_basic_metal_placer"},	 		{"CRAFTING_STATION"})
AddRecipe2("swinging_light_chandalier_candles", {Ingredient("oinc",8)},  TECH.HOME_TWO, {nounlock=true, image="reno_light_chandalier_candles.tex",	placer="swinging_light_chandalier_candles_placer"},	 	{"CRAFTING_STATION"})
AddRecipe2("swinging_light_rope_1",				{Ingredient("oinc",1)},  TECH.HOME_TWO, {nounlock=true, image="reno_light_rope_1.tex",				placer="swinging_light_rope_1_placer"},	 				{"CRAFTING_STATION"})
AddRecipe2("swinging_light_rope_2",				{Ingredient("oinc",1)},  TECH.HOME_TWO, {nounlock=true, image="reno_light_rope_2.tex",				placer="swinging_light_rope_2_placer"},	 				{"CRAFTING_STATION"})
AddRecipe2("swinging_light_floral_bulb",		{Ingredient("oinc",10)}, TECH.HOME_TWO, {nounlock=true, image="reno_light_floral_bulb.tex",			placer="swinging_light_floral_bulb_placer"},			{"CRAFTING_STATION"})
AddRecipe2("swinging_light_pendant_cherries", 	{Ingredient("oinc",12)}, TECH.HOME_TWO, {nounlock=true, image="reno_light_pendant_cherries.tex",	placer="swinging_light_pendant_cherries_placer"},	 	{"CRAFTING_STATION"})
AddRecipe2("swinging_light_floral_scallop", 	{Ingredient("oinc",12)}, TECH.HOME_TWO, {nounlock=true, image="reno_light_floral_scallop.tex",		placer="swinging_light_floral_scallop_placer"},	 		{"CRAFTING_STATION"})
AddRecipe2("swinging_light_floral_bloomer", 	{Ingredient("oinc",12)}, TECH.HOME_TWO, {nounlock=true, image="reno_light_floral_bloomer.tex",		placer="swinging_light_floral_bloomer_placer"},	 		{"CRAFTING_STATION"})
AddRecipe2("swinging_light_tophat", 			{Ingredient("oinc",12)}, TECH.HOME_TWO, {nounlock=true, image="reno_light_tophat.tex",				placer="swinging_light_tophat_placer"},	 				{"CRAFTING_STATION"})
AddRecipe2("swinging_light_derby", 				{Ingredient("oinc",12)}, TECH.HOME_TWO, {nounlock=true, image="reno_light_derby.tex",				placer="swinging_light_derby_placer"},	 				{"CRAFTING_STATION"})

AddRecipe2("wood_door",							{Ingredient("oinc",10)}, TECH.HOME_TWO, {nounlock=true, 											placer="wood_door_placer"},	 				{"CRAFTING_STATION"})
AddRecipe2("stone_door",						{Ingredient("oinc",10)}, TECH.HOME_TWO, {nounlock=true, 											placer="stone_door_placer"},	 			{"CRAFTING_STATION"})
AddRecipe2("organic_door", 						{Ingredient("oinc",15)}, TECH.HOME_TWO, {nounlock=true, 											placer="organic_door_placer"},	 			{"CRAFTING_STATION"})
AddRecipe2("iron_door", 						{Ingredient("oinc",15)}, TECH.HOME_TWO, {nounlock=true, 											placer="iron_door_placer"},	 				{"CRAFTING_STATION"})
AddRecipe2("curtain_door", 						{Ingredient("oinc",15)}, TECH.HOME_TWO, {nounlock=true, 											placer="curtain_door_placer"},	 			{"CRAFTING_STATION"})
AddRecipe2("plate_door", 						{Ingredient("oinc",25)}, TECH.HOME_TWO, {nounlock=true, 											placer="plate_door_placer"},	 			{"CRAFTING_STATION"})
AddRecipe2("round_door", 						{Ingredient("oinc",20)}, TECH.HOME_TWO, {nounlock=true, 											placer="round_door_placer"},	 			{"CRAFTING_STATION"})
AddRecipe2("pillar_door", 						{Ingredient("oinc",20)}, TECH.HOME_TWO, {nounlock=true, 											placer="pillar_door_placer"},	 			{"CRAFTING_STATION"})
]]
AddDeconstructRecipe("pig_guard_tower_palace", {Ingredient("cutstone", 3), Ingredient("halberd", 2), Ingredient("pigskin", 4)})
AddDeconstructRecipe("pig_shop_academy", {Ingredient("boards", 4), Ingredient("relic_1", 1), Ingredient("relic_2", 1), Ingredient("pigskin", 4)})
AddDeconstructRecipe("pighouse_farm", {Ingredient("cutstone", 3), Ingredient("pitchfork", 1), Ingredient("seeds", 6), Ingredient("pigskin", 4)})
AddDeconstructRecipe("pighouse_mine", {Ingredient("cutstone", 3), Ingredient("pickaxe", 2), Ingredient("pigskin", 4)})
AddDeconstructRecipe("mandrakehouse", {Ingredient("boards", 3), Ingredient("mandrake", 2), Ingredient("cutgrass", 10)})

AddDeconstructRecipe("topiary_1", {Ingredient("oinc", 20)})
AddDeconstructRecipe("topiary_2", {Ingredient("oinc", 20)})
AddDeconstructRecipe("topiary_3", {Ingredient("oinc", 20)})
AddDeconstructRecipe("topiary_4", {Ingredient("oinc", 20)})
