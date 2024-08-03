local AddDeconstructRecipe = AddDeconstructRecipe
local AddRecipe2 = AddRecipe2
local AddRecipeFilter = AddRecipeFilter
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

local function SortBefore(a, b, filter_name)  -- a before b
    SortRecipe(a, b, filter_name, 0)
end

local function SortAfter(a, b, filter_name)  -- a after b
    SortRecipe(a, b, filter_name, 1)
end

local function AquaticRecipe(name, data)
    if AllRecipes[name] then
        -- data = {distance=, shore_distance=, platform_distance=, shore_buffer_max=, shore_buffer_min=, platform_buffer_max=, platform_buffer_min=, aquatic_buffer_min=, noshore=}
        data = data or {}
        data.platform_buffer_max = data.platform_buffer_max or
                                       (data.platform_distance and math.sqrt(data.platform_distance)) or
                                       (data.distance and math.sqrt(data.distance)) or nil
        data.shore_buffer_max = data.shore_buffer_max or (data.shore_distance and ((data.shore_distance + 1) / 2)) or
                                    nil
        AllRecipes[name].aquatic = data
        AllRecipes[name].build_mode = BUILDMODE.WATER
    end
end


-- AddRecipeFilter(filter_def, index)
-- index: insertion order
-- filter_def.name: This is the filter's id and will need the string added to STRINGS.UI.CRAFTING_FILTERS[name]
-- filter_def.atlas: atlas for the icon,  can be a string or function
-- filter_def.image: icon to show in the crafting menu, can be a string or function
-- filter_def.image_size: (optional) custom image sizing
-- filter_def.custom_pos: (optional) This will not be added to the grid of filters
-- filter_def.recipes: !This is not supported! Create the filter and then pass in the filter to AddRecipe2() or AddRecipeToFilter()
AddRecipeFilter({
    name = "NAUTICAL",
    atlas = "images/hud/pl_crafting_menu_icons.xml",
    image = "filter_nautical.tex",
})

AddRecipeFilter({
    name = "ARCHAEOLOGY",
    atlas = "images/hud/pl_crafting_menu_icons.xml",
    image = "filter_archaeology.tex",
})

--- ARCHAEOLOGY ---
AddRecipe2("disarming_kit", {Ingredient("iron", 2), Ingredient("cutreeds", 2)}, TECH.NONE, {}, {"ARCHAEOLOGY"})
AddRecipe2("ballpein_hammer", {Ingredient("iron", 2), Ingredient("twigs", 1)}, TECH.SCIENCE_ONE, {}, {"ARCHAEOLOGY"})
AddRecipe2("goldpan", {Ingredient("iron", 2), Ingredient("hammer", 1)}, TECH.SCIENCE_ONE, {}, {"ARCHAEOLOGY"})
AddRecipe2("magnifying_glass", {Ingredient("iron", 1), Ingredient("twigs", 1), Ingredient("bluegem", 1)}, TECH.SCIENCE_TWO, {}, {"ARCHAEOLOGY"})

--SCIENCE
AddRecipe2("smelter", {Ingredient("cutstone", 6), Ingredient("boards", 4), Ingredient("redgem", 1)}, TECH.SCIENCE_TWO, {placer = "smelter_placer"}, {"TOOLS","STRUCTURES"})
SortBefore("smelter", "cookpot", "STRUCTURES")
SortAfter("smelter", "archive_resonator_item", "TOOLS")

AddRecipe2("basefan", {Ingredient("alloy", 2), Ingredient("transistor", 2), Ingredient("gears", 1)}, TECH.SCIENCE_TWO, {placer = "basefan_placer"}, {"STRUCTURES", "RAIN"})
SortBefore("basefan", "firesuppressor", "STRUCTURES")
SortBefore("basefan", "rainometer", "RAIN")

--TOOLS
AddRecipe2("bugrepellent", {Ingredient("tuber_crop", 6), Ingredient("venus_stalk", 1)}, TECH.SCIENCE_ONE, {}, {"TOOLS"})
SortAfter("bugrepellent", nil, "TOOLS")

AddRecipe2("machete", {Ingredient("twigs", 1),Ingredient("flint", 3)}, TECH.SCIENCE_ONE, {}, {"TOOLS"})
SortAfter("machete", "axe", "TOOLS")

AddRecipe2("goldenmachete", {Ingredient("twigs", 4),Ingredient("goldnugget", 2)}, TECH.SCIENCE_ONE, {}, {"TOOLS"})
SortAfter("goldenmachete", "goldenaxe", "TOOLS")

AddRecipe2("shears", {Ingredient("twigs", 2),Ingredient("iron", 2)}, TECH.SCIENCE_ONE, {}, {"TOOLS"})
SortAfter("shears", "goldenpitchfork", "TOOLS")

--war
AddRecipe2("blunderbuss", {Ingredient("boards", 2), Ingredient("oinc10", 1), Ingredient("gears", 1)}, TECH.SCIENCE_TWO, {}, {"WEAPONS"})
SortAfter("blunderbuss", "blowdart_sleep", "WEAPONS")

AddRecipe2("cork_bat", {Ingredient("cork", 3), Ingredient("boards", 1)}, TECH.SCIENCE_ONE, {}, {"WEAPONS"})
SortBefore("cork_bat", "hambat", "WEAPONS")

AddRecipe2("halberd", {Ingredient("alloy", 1), Ingredient("twigs", 2)}, TECH.SCIENCE_TWO, {}, {"WEAPONS", "TOOLS"})
SortAfter("halberd", "spear", "WEAPONS")
SortAfter("halberd", "shears", "TOOLS")

AddRecipe2("metalplatehat", {Ingredient("alloy", 3), Ingredient("cork", 3)}, TECH.SCIENCE_ONE, {}, {"ARMOUR"})
SortBefore("metalplatehat", "cookiecutterhat", "ARMOUR")

AddRecipe2("armor_metalplate", {Ingredient("alloy", 3), Ingredient("hammer", 1)}, TECH.SCIENCE_ONE, {}, {"ARMOUR"})
SortAfter("armor_metalplate", "armormarble", "ARMOUR")

AddRecipe2("armor_weevole", {Ingredient("weevole_carapace", 4), Ingredient("chitin", 2)}, TECH.SCIENCE_TWO, {}, {"ARMOUR", "RAIN"})
SortBefore("armor_weevole", "armorwood", "ARMOUR")
SortBefore("armor_weevole", "raincoat", "RAIN")

AddRecipe2("armorvortexcloak", {Ingredient("ancient_remnant", 5), Ingredient("armor_sanity", 1)}, TECH.LOST, {}, {"ARMOUR", "CLOTHING", "CONTAINERS", "MAGIC"})
SortAfter("armorvortexcloak", "dreadstonehat", "ARMOUR")
SortAfter("armorvortexcloak", "icepack", "CLOTHING")
SortAfter("armorvortexcloak", "spicepack", "CONTAINERS")
SortAfter("armorvortexcloak", "dreadstonehat", "MAGIC")

AddRecipe2("living_artifact", {Ingredient("infused_iron", 6), Ingredient("waterdrop", 1)}, TECH.LOST, {}, {"MAGIC", "ARMOUR", "WEAPONS"})
SortAfter("living_artifact", "nightmarefuel", "MAGIC")
SortAfter("living_artifact", nil, "ARMOUR")
SortAfter("living_artifact", nil, "WEAPONS")

--CLOTHING
AddRecipe2("antmaskhat", {Ingredient("chitin", 5),Ingredient("footballhat", 1)}, TECH.SCIENCE_ONE, {}, {"ARMOUR", "CLOTHING"})
SortAfter("antmaskhat", "footballhat", "ARMOUR")
SortAfter("antmaskhat", "bushhat", "CLOTHING")

AddRecipe2("antsuit", {Ingredient("chitin", 5),Ingredient("armorwood", 1)}, TECH.SCIENCE_ONE, {}, {"ARMOUR", "CLOTHING"})
SortAfter("antsuit", "armorwood", "ARMOUR")
SortAfter("antsuit", "antmaskhat", "CLOTHING")

AddRecipe2("bathat", {Ingredient("pigskin", 2), Ingredient("batwing", 1), Ingredient("compass", 1)}, TECH.SCIENCE_TWO, {}, {"LIGHT"})
SortAfter("bathat", "molehat", "LIGHT")

AddRecipe2("candlehat", {Ingredient("cork", 4), Ingredient("iron", 2)}, TECH.SCIENCE_ONE, {}, {"LIGHT", "RAIN"})
SortBefore("candlehat", "coldfirepit", "LIGHT")
SortBefore("candlehat", "tophat", "RAIN")

AddRecipe2("snakeskinhat", {Ingredient("snakeskin", 1), Ingredient("strawhat", 1), Ingredient("boneshard", 1)}, TECH.SCIENCE_TWO, {}, {"CLOTHING", "RAIN"})
SortBefore("snakeskinhat", "earmuffshat", "CLOTHING")
SortAfter("snakeskinhat", "rainhat", "RAIN")

AddRecipe2("armor_snakeskin", {Ingredient("snakeskin", 2), Ingredient("vine", 2), Ingredient("boneshard", 2)}, TECH.SCIENCE_ONE, {}, {"CLOTHING", "RAIN", "WINTER"})
SortBefore("armor_snakeskin", "sweatervest", "CLOTHING")
SortAfter("armor_snakeskin", "raincoat", "RAIN")
SortAfter("armor_snakeskin", "raincoat", "WINTER")

AddRecipe2("gasmaskhat", {Ingredient("peagawkfeather", 4), Ingredient("pigskin", 1), Ingredient("fabric", 1)}, TECH.SCIENCE_TWO, {}, {"CLOTHING"})
SortAfter("gasmaskhat", "icehat", "CLOTHING")

AddRecipe2("thunderhat", {Ingredient("feather_thunder", 1), Ingredient("goldnugget", 1),Ingredient("cork", 2)}, TECH.SCIENCE_TWO, {}, {"CLOTHING", "RAIN"})
SortAfter("thunderhat", "pithhat", "CLOTHING")
SortAfter("thunderhat", "eyebrellahat", "RAIN")

AddRecipe2("pithhat", {Ingredient("fabric", 1),Ingredient("vine", 3),Ingredient("cork", 6)}, TECH.SCIENCE_TWO, {}, {"CLOTHING", "RAIN"})
SortAfter("pithhat", "thunderhat", "CLOTHING")
SortAfter("pithhat", "thunderhat", "RAIN")

--MAGIC
AddRecipe2("hogusporkusator", {Ingredient("pigskin", 4), Ingredient("boards", 4), Ingredient("feather_robin_winter", 4)}, TECH.SCIENCE_ONE, {placer = "hogusporkusator_placer"}, {"MAGIC", "STRUCTURES", "PROTOTYPER"})
SortAfter("hogusporkusator", "researchlab4", "MAGIC")
SortAfter("hogusporkusator", "researchlab4", "STRUCTURES")
SortAfter("hogusporkusator", "researchlab4", "PROTOTYPER")

AddRecipe2("bonestaff", {Ingredient("pugalisk_skull", 1), Ingredient("boneshard", 1), Ingredient("nightmarefuel", 2)}, TECH.MAGIC_THREE, {} , {"WEAPONS","MAGIC"})
SortAfter("bonestaff", "antlionhat", "MAGIC")
SortAfter("bonestaff", "trident", "WEAPONS")

--REFINE
AddRecipe2("goldnugget", {Ingredient("gold_dust", 6)}, TECH.SCIENCE_ONE, {no_deconstruction = true} , {"REFINE"})
AddRecipe2("clawpalmtree_sapling_item", {Ingredient("cork", 1), Ingredient("poop", 1)}, TECH.SCIENCE_ONE, {no_deconstruction = true}, {"REFINE"})
AddRecipe2("venomgland", {Ingredient("froglegs_poison", 3)}, TECH.SCIENCE_TWO, {no_deconstruction = true} , {"REFINE"})

--DECOR
-- AddRecipe2("turf_foundation", {Ingredient("cutstone", 1)}, TECH.CITY, cityRecipeGameTypes, nil, nil, true)
-- AddRecipe2("turf_cobbleroad", {Ingredient("cutstone", 2), Ingredient("boards", 1)}, TECH.CITY, cityRecipeGameTypes, nil, nil, true)
-- AddRecipe2("turf_lawn", {Ingredient("cutgrass", 2), Ingredient("nitre", 1)}, TECH.SCIENCE_TWO)
-- AddRecipe2("turf_fields", {Ingredient("turf_rainforest", 1), Ingredient("ash", 1)}, TECH.SCIENCE_TWO)
-- AddRecipe2("turf_deeprainforest_nocanopy", {Ingredient("bramble_bulb", 1), Ingredient("cutgrass", 2), Ingredient("ash", 1)}, TECH.SCIENCE_TWO)

--NAUTICAL
AddRecipe2("boat_lograft", {Ingredient("log", 6), Ingredient("cutgrass", 4)}, TECH.NONE, {placer = "boat_lograft_placer", build_mode = BUILDMODE.WATER, build_distance = 4}, {"NAUTICAL"})
AquaticRecipe("boat_lograft", {distance = 4, platform_buffer_min = 2, aquatic_buffer_min = 1, boat = true})

AddRecipe2("boat_row", {Ingredient("boards", 3), Ingredient("vine", 4)}, TECH.SCIENCE_ONE, {placer = "boat_row_placer", build_mode = BUILDMODE.WATER, build_distance = 4}, {"NAUTICAL"})
AquaticRecipe("boat_row", {distance = 4, platform_buffer_min = 2, aquatic_buffer_min = 1, boat = true})

AddRecipe2("boat_cork", {Ingredient("cork", 4), Ingredient("rope", 1)}, TECH.SCIENCE_ONE, {placer = "boat_cork_placer", build_mode = BUILDMODE.WATER, build_distance = 4}, {"NAUTICAL"})
AquaticRecipe("boat_cork", {distance = 4, platform_buffer_min = 2, aquatic_buffer_min = 1, boat = true})

AddRecipe2("boat_cargo", {Ingredient("boards", 6), Ingredient("rope", 3)}, TECH.SCIENCE_ONE, {placer = "boat_cargo_placer", build_mode = BUILDMODE.WATER, build_distance = 4}, {"NAUTICAL"})
AquaticRecipe("boat_cargo", {distance = 4, platform_buffer_min = 2, aquatic_buffer_min = 1, boat = true})

AddRecipe2("boatrepairkit", {Ingredient("boards", 2), Ingredient("stinger", 2), Ingredient("rope", 2)}, TECH.SCIENCE_ONE, nil, {"NAUTICAL"})

AddRecipe2("boat_torch", {Ingredient("twigs", 2), Ingredient("torch", 1)}, TECH.SCIENCE_ONE, nil, {"LIGHT", "NAUTICAL"})

AddRecipe2("sail_snakeskin", {Ingredient("log", 4), Ingredient("rope", 2), Ingredient("snakeskin", 2)}, TECH.SCIENCE_TWO, nil, {"NAUTICAL"})

--CHARACTER

AddRecipe2("disguisehat", {Ingredient("twigs", 2), Ingredient("pigskin", 1), Ingredient("beardhair", 1)}, TECH.NONE, {builder_tag = "spiderwhisperer"}, {"CHARACTER", "CLOTHING"})
SortBefore("disguisehat", "spidereggsack", "CHARACTER")

AddRecipe2("poisonbalm", {Ingredient("livinglog", 1), Ingredient("venomgland", 1)}, TECH.NONE, {builder_tag = "plantkin"}, {"CHARACTER", "RESTORATION"})
SortAfter("poisonbalm", "armor_bramble", "CHARACTER")
SortBefore("poisonbalm", "healingsalve", "RESTORATION")

--Deconstruct
AddDeconstructRecipe("mandrakehouse", {Ingredient("boards", 3), Ingredient("mandrake", 2), Ingredient("cutgrass", 10)})
