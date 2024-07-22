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

AddRecipe2("goldpan", {Ingredient("iron", 2), Ingredient("hammer", 1)}, TECH.SCIENCE_ONE, {}, {"ARCHAEOLOGY"})
--SortAfter("goldpan", "goldenpitchfork", "TOOLS")
AddRecipe2("ballpein_hammer", {Ingredient("iron", 2), Ingredient("twigs", 1)}, TECH.SCIENCE_ONE, {}, {"ARCHAEOLOGY"})

--SCIENCE
AddRecipe2("smelter", {Ingredient("cutstone", 6), Ingredient("boards", 4), Ingredient("redgem", 1)}, TECH.SCIENCE_TWO, {placer = "smelter_placer"}, {"TOOLS","STRUCTURES"})
SortBefore("smelter", "cookpot", "STRUCTURES")
SortAfter("smelter", "archive_resonator_item", "TOOLS")

AddRecipe2("basefan", {Ingredient("alloy", 2), Ingredient("transistor", 2), Ingredient("gears", 1)}, TECH.SCIENCE_TWO, {placer = "basefan_placer"}, {"STRUCTURES", "RAIN"})
SortBefore("basefan", "firesuppressor", "STRUCTURES")
SortBefore("basefan", "rainometer", "RAIN")

--TOOLS
AddRecipe2("machete", {Ingredient("twigs", 1),Ingredient("flint", 3)}, TECH.SCIENCE_ONE, {}, {"TOOLS"})
SortAfter("machete", "axe", "TOOLS")

AddRecipe2("goldenmachete", {Ingredient("twigs", 4),Ingredient("goldnugget", 2)}, TECH.SCIENCE_ONE, {}, {"TOOLS"})
SortAfter("goldenmachete", "goldenaxe", "TOOLS")

AddRecipe2("shears", {Ingredient("twigs", 2),Ingredient("iron", 2)}, TECH.SCIENCE_ONE, {}, {"TOOLS"})
SortAfter("shears", "goldenpitchfork", "TOOLS")

--war
AddRecipe2("halberd", {Ingredient("alloy", 1), Ingredient("twigs", 2)}, TECH.SCIENCE_TWO, {}, {"WEAPONS","TOOLS"})
SortAfter("halberd", "spear", "WEAPONS")
SortAfter("halberd", "shears", "TOOLS")

AddRecipe2("metalplatehat", {Ingredient("alloy", 3),Ingredient("cork", 3)}, TECH.SCIENCE_ONE, {}, {"ARMOUR"})
SortBefore("metalplatehat", "cookiecutterhat", "ARMOUR")

AddRecipe2("armor_metalplate", {Ingredient("alloy", 3),Ingredient("hammer", 1)}, TECH.SCIENCE_ONE, {}, {"ARMOUR"})
SortAfter("armor_metalplate", "armormarble", "ARMOUR")

--MAGIC
AddRecipe2("bonestaff", {Ingredient("pugalisk_skull", 1), Ingredient("boneshard", 1), Ingredient("nightmarefuel", 2)}, TECH.MAGIC_THREE, {} , {"WEAPONS","MAGIC"})
SortAfter("bonestaff", "antlionhat", "MAGIC")
SortAfter("bonestaff", "trident", "WEAPONS")

--REFINE
AddRecipe2("goldnugget", {Ingredient("gold_dust", 6)}, TECH.SCIENCE_ONE, {no_deconstruction=true} , {"REFINE"})
AddRecipe2("venomgland", {Ingredient("froglegs_poison", 3)}, TECH.SCIENCE_TWO, {no_deconstruction=true} , {"REFINE"})

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

AddRecipe2("living_artifact", {Ingredient("infused_iron", 6), Ingredient("waterdrop", 1)}, TECH.LOST, {}, {"MAGIC", "ARMOUR", "WEAPONS"})
SortAfter("living_artifact", "nightmarefuel", "MAGIC")
SortAfter("living_artifact", nil, "ARMOUR")
SortAfter("living_artifact", nil, "WEAPONS")

--Deconstruct
AddDeconstructRecipe("mandrakehouse", {Ingredient("boards", 3), Ingredient("mandrake", 2), Ingredient("cutgrass", 10)})
