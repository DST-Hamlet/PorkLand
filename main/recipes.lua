local AddDeconstructRecipe = AddDeconstructRecipe
local AddRecipe2 = AddRecipe2
local AddRecipeFilter = AddRecipeFilter
local AddPrototyperDef = AddPrototyperDef
local AddRecipePostInit = AddRecipePostInit
GLOBAL.setfenv(1, GLOBAL)

local TechTree = require("techtree")

local change_recipes = require("main/change_recipes")
local DISABLE_RECIPES = change_recipes.DISABLE_RECIPES
local LOST_RECIPES = change_recipes.LOST_RECIPES

for i, recipe_name in ipairs(DISABLE_RECIPES) do
    AddRecipePostInit(recipe_name, function(recipe)
        recipe.disabled_worlds = { "porkland" }
    end)
end

for i, recipe_name in ipairs(LOST_RECIPES) do
    AddRecipePostInit(recipe_name, function(recipe)
        recipe.level = TechTree.Create(TECH.LOST)
    end)
end

AllRecipes["cookbook"].ingredients = {Ingredient("papyrus", 1), Ingredient("radish", 1)} -- TODO: 检测世界来修改配方

local _GetValidRecipe = GetValidRecipe
function GetValidRecipe(recipe_name, ...)
    local recipe = _GetValidRecipe(recipe_name, ...)
    if recipe and TheWorld and (recipe.disabled_worlds and TheWorld:HasTags(recipe.disabled_worlds)) then
        return
    end
    return recipe
end

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

local function rebuild_techtree(name)
    TECH.NONE = TechTree.Create()

    for k, v in pairs(AllRecipes) do
        v.level = TechTree.Create(v.level)
    end

    for k, v in pairs(TUNING.PROTOTYPER_TREES) do
        v = TechTree.Create(v)
        TUNING.PROTOTYPER_TREES[k] = TUNING.PROTOTYPER_TREES[k] or {}
        TUNING.PROTOTYPER_TREES[k][name] = TUNING.PROTOTYPER_TREES[k][name] or 0
    end
end

-- Taken from GlassicAPI
-- custom tech allows you to build custom prototyper or allows muliti prototypers to bonus a tech simultaneously.
-- e.g. GlassicAPI.AddTech("FRIENDSHIPRING")
---@param name string
local function AddTech(name, bonus_available)
    table.insert(TechTree.AVAILABLE_TECH, name)
    if bonus_available then
       table.insert(TechTree.BONUS_TECH, name)
    end
    rebuild_techtree(name)
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

local function IsMarshLand(pt, rot)
    local ground_tile = TheWorld.Map:GetTileAtPoint(pt.x, pt.y, pt.z)
    return ground_tile and ground_tile == WORLD_TILES.MARSH
end

local function telebase_testfn(pt, rot)
    --See telebase.lua
    local telebase_parts =
    {
        { x = -1.6, z = -1.6 },
        { x =  2.7, z = -0.8 },
        { x = -0.8, z =  2.7 },
    }
    rot = (45 - rot) * DEGREES
    local sin_rot = math.sin(rot)
    local cos_rot = math.cos(rot)
    for i, v in ipairs(telebase_parts) do
        if not TheWorld.Map:IsVisualGroundAtPoint(pt.x + v.x * cos_rot - v.z * sin_rot, pt.y, pt.z + v.z * cos_rot + v.x * sin_rot) then
            return false
        end
    end
    return true
end

AddTech("CITY", true)
AddTech("HOME", true)

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
}, #CRAFTING_FILTER_DEFS) -- insert this before the "all recipes" category

AddRecipeFilter({
    name = "ARCHAEOLOGY",
    atlas = "images/hud/pl_crafting_menu_icons.xml",
    image = "filter_archaeology.tex",
}, #CRAFTING_FILTER_DEFS)

AddRecipeFilter({
    name = "ENVIRONMENT_PROTECTION",
    atlas = "images/hud/pl_crafting_menu_icons.xml",
    image = "filter_environment_protection.tex",
}, #CRAFTING_FILTER_DEFS)

-- home filter
AddRecipeFilter({
    name =  "HOME_MISC", -- "reno_tab_homekits",
    atlas = "images/hud/pl_inventoryimages.xml",
    image = "reno_tab_homekits.tex",
    home_prototyper = true,
}, 1)

AddRecipeFilter({
    name = "HOME_COLUMN",
    atlas = "images/hud/pl_inventoryimages.xml",
    image = "reno_tab_columns.tex",
    home_prototyper = true,
}, 1)

AddRecipeFilter({
    name = "HOME_RUG",
    atlas = "images/hud/pl_inventoryimages.xml",
    image = "reno_tab_rugs.tex",
    home_prototyper = true,
}, 1)

AddRecipeFilter({
    name = "HOME_HANGINGLAMP",
    atlas = "images/hud/pl_inventoryimages.xml",
    image = "reno_tab_hanginglamps.tex",
    home_prototyper = true,
}, 1)

AddRecipeFilter({
    name = "HOME_LAMP",
    atlas = "images/hud/pl_inventoryimages.xml",
    image = "reno_tab_lamps.tex",
    home_prototyper = true,
}, 1)

AddRecipeFilter({
    name = "HOME_PLANTHOLDER",
    atlas = "images/hud/pl_inventoryimages.xml",
    image = "reno_tab_plantholders.tex",
    home_prototyper = true,
}, 1)

AddRecipeFilter({
    name = "HOME_FURNITURE",  -- shelves, chairs, tables
    atlas = "images/hud/pl_inventoryimages.xml",
    image = "reno_tab_shelves.tex",
    home_prototyper = true,
}, 1)

AddRecipeFilter({
    name = "HOME_WALL_DECORATION",  -- ornaments
    atlas = "images/hud/pl_inventoryimages.xml",
    image = "reno_tab_windows.tex",
    home_prototyper = true,
}, 1)

AddRecipeFilter({
    name = "HOME_WALLPAPER",
    atlas = "images/hud/pl_inventoryimages.xml",
    image = "reno_tab_wallpaper.tex",
    home_prototyper = true,
}, 1)

AddRecipeFilter({
    name = "HOME_FLOOR",
    atlas = "images/hud/pl_inventoryimages.xml",
    image = "reno_tab_floors.tex",
    home_prototyper = true,
}, 1)

AddRecipeFilter({
    name = "HOME_DOOR",
    atlas = "images/hud/pl_inventoryimages.xml",
    image = "reno_tab_doors.tex",
    home_prototyper = true,
}, 1)

AddPrototyperDef("key_to_city", {
    icon_atlas = "images/hud/pl_crafting_menu_icons.xml",
    icon_image = "filter_city.tex",
    is_crafting_station = true,
    filter_text = STRINGS.UI.CRAFTING_STATION_FILTERS.CITY
})

CRAFTING_FILTERS.SEAFARING.disabled_worlds = { "porkland" }
CRAFTING_FILTERS.RIDING.disabled_worlds = { "porkland" }
CRAFTING_FILTERS.WINTER.disabled_worlds = { "porkland" }
CRAFTING_FILTERS.SUMMER.disabled_worlds = { "porkland" }
CRAFTING_FILTERS.FISHING.disabled_worlds = { "porkland" }

--- ARCHAEOLOGY ---
AddRecipe2("disarming_kit", {Ingredient("iron", 2), Ingredient("cutreeds", 2)}, TECH.NONE, {}, {"ARCHAEOLOGY"})
AddRecipe2("ballpein_hammer", {Ingredient("iron", 2), Ingredient("twigs", 1)}, TECH.SCIENCE_ONE, {}, {"ARCHAEOLOGY"})
AddRecipe2("goldpan", {Ingredient("iron", 2), Ingredient("hammer", 1)}, TECH.SCIENCE_ONE, {}, {"ARCHAEOLOGY"})
AddRecipe2("magnifying_glass", {Ingredient("iron", 1), Ingredient("twigs", 1), Ingredient("bluegem", 1)}, TECH.SCIENCE_TWO, {}, {"ARCHAEOLOGY"})

-- STRUCTURES ---
AddRecipe2("smelter", {Ingredient("cutstone", 6), Ingredient("boards", 4), Ingredient("redgem", 1)}, TECH.SCIENCE_TWO, {placer = "smelter_placer", min_spacing=2}, {"REFINE","STRUCTURES"})
SortBefore("smelter", "rope", "REFINE")
SortBefore("smelter", "cookpot", "STRUCTURES")

AddRecipe2("corkchest", {Ingredient("cork", 2), Ingredient("rope", 1)}, TECH.SCIENCE_ONE, {placer="corkchest_placer", min_spacing=1}, {"STRUCTURES", "CONTAINERS"})
SortBefore("corkchest", "treasurechest", "CONTAINERS")
SortBefore("corkchest", "treasurechest", "STRUCTURES")

AddRecipe2("roottrunk", {Ingredient("bramble_bulb", 1), Ingredient("venus_stalk", 2), Ingredient("boards", 3)}, TECH.MAGIC_TWO, {placer="roottrunk_placer", min_spacing=1}, {"STRUCTURES", "CONTAINERS", "MAGIC"})
SortAfter("roottrunk", "magician_chest", "CONTAINERS")
SortAfter("roottrunk", "magician_chest", "STRUCTURES")

-- SCIENCE ---
AddRecipe2("basefan", {Ingredient("alloy", 2), Ingredient("transistor", 2), Ingredient("gears", 1)}, TECH.SCIENCE_TWO, {placer = "basefan_placer", min_spacing=2}, {"STRUCTURES", "RAIN", "ENVIRONMENT_PROTECTION"})
SortBefore("basefan", "firesuppressor", "STRUCTURES")
SortBefore("basefan", "rainometer", "RAIN")

-- TOOLS ---
AddRecipe2("bugrepellent", {Ingredient("tuber_crop", 6), Ingredient("venus_stalk", 1)}, TECH.SCIENCE_ONE, {}, {"TOOLS", "ENVIRONMENT_PROTECTION"})
SortAfter("bugrepellent", nil, "TOOLS")

AddRecipe2("machete", {Ingredient("twigs", 1),Ingredient("flint", 3)}, TECH.NONE, {}, {"TOOLS"})
SortAfter("machete", "axe", "TOOLS")

AddRecipe2("goldenmachete", {Ingredient("twigs", 4),Ingredient("goldnugget", 2)}, TECH.SCIENCE_ONE, {}, {"TOOLS"})
SortAfter("goldenmachete", "goldenaxe", "TOOLS")

AddRecipe2("shears", {Ingredient("twigs", 2),Ingredient("iron", 2)}, TECH.SCIENCE_ONE, {}, {"TOOLS"})
SortAfter("shears", "goldenpitchfork", "TOOLS")

AddRecipe2("antler", {Ingredient("hippo_antler", 1),Ingredient("bill_quill", 3),Ingredient("flint", 1)}, TECH.SCIENCE_ONE, {}, {"TOOLS"})

AddRecipe2("antler_corrupted", {Ingredient("antler", 1), Ingredient("ancient_remnant", 2)}, TECH.MAGIC_TWO, {}, {"TOOLS","MAGIC"})
SortAfter("antler_corrupted", "dreadstonehat", "MAGIC")
SortAfter("antler_corrupted", "antler", "TOOLS")

-- WAR ---
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

AddRecipe2("armor_weevole", {Ingredient("weevole_carapace", 4), Ingredient("chitin", 2)}, TECH.SCIENCE_TWO, {}, {"ARMOUR", "RAIN", "ENVIRONMENT_PROTECTION"})
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

-- CLOTHING ---
AddRecipe2("antmaskhat", {Ingredient("chitin", 5),Ingredient("footballhat", 1)}, TECH.SCIENCE_ONE, {}, {"ARMOUR", "CLOTHING"})
SortAfter("antmaskhat", "footballhat", "ARMOUR")
SortAfter("antmaskhat", "bushhat", "CLOTHING")

AddRecipe2("antsuit", {Ingredient("chitin", 5),Ingredient("armorwood", 1)}, TECH.SCIENCE_ONE, {}, {"ARMOUR", "CLOTHING"})
SortAfter("antsuit", "armorwood", "ARMOUR")
SortAfter("antsuit", "antmaskhat", "CLOTHING")

AddRecipe2("bathat", {Ingredient("pigskin", 2), Ingredient("batwing", 1), Ingredient("compass", 1)}, TECH.SCIENCE_TWO, {}, {"LIGHT", "ENVIRONMENT_PROTECTION"})
SortAfter("bathat", "molehat", "LIGHT")

AddRecipe2("candlehat", {Ingredient("cork", 4), Ingredient("iron", 2)}, TECH.SCIENCE_ONE, {}, {"LIGHT", "RAIN"})
SortBefore("candlehat", "coldfirepit", "LIGHT")
SortBefore("candlehat", "tophat", "RAIN")

AddRecipe2("snakeskinhat", {Ingredient("snakeskin", 1, nil, nil, "snakeskin_scaly.tex"), Ingredient("strawhat", 1), Ingredient("boneshard", 1)}, TECH.SCIENCE_TWO, {image = "snakeskinhat_scaly.tex"}, {"CLOTHING", "RAIN"})
SortBefore("snakeskinhat", "earmuffshat", "CLOTHING")
SortAfter("snakeskinhat", "rainhat", "RAIN")

AddRecipe2("armor_snakeskin", {Ingredient("snakeskin", 2, nil, nil, "snakeskin_scaly.tex"), Ingredient("vine", 2), Ingredient("boneshard", 2)}, TECH.SCIENCE_ONE, {image = "armor_snakeskin_scaly.tex"}, {"CLOTHING", "RAIN"})
SortBefore("armor_snakeskin", "sweatervest", "CLOTHING")
SortAfter("armor_snakeskin", "raincoat", "RAIN")

AddRecipe2("gasmaskhat", {Ingredient("peagawkfeather", 4), Ingredient("pigskin", 1), Ingredient("fabric", 1)}, TECH.SCIENCE_TWO, {}, {"CLOTHING", "ENVIRONMENT_PROTECTION"})
SortAfter("gasmaskhat", "icehat", "CLOTHING")

AddRecipe2("thunderhat", {Ingredient("feather_thunder", 1), Ingredient("goldnugget", 1),Ingredient("cork", 2)}, TECH.SCIENCE_TWO, {}, {"CLOTHING", "RAIN","ENVIRONMENT_PROTECTION"})
SortAfter("thunderhat", "pithhat", "CLOTHING")
SortAfter("thunderhat", "eyebrellahat", "RAIN")

AddRecipe2("pithhat", {Ingredient("fabric", 1),Ingredient("vine", 3),Ingredient("cork", 6)}, TECH.SCIENCE_TWO, {}, {"CLOTHING", "RAIN", "ENVIRONMENT_PROTECTION"})
SortAfter("pithhat", "thunderhat", "CLOTHING")
SortAfter("pithhat", "thunderhat", "RAIN")

-- MAGIC ---
AddRecipe2("hogusporkusator", {Ingredient("pigskin", 4), Ingredient("boards", 4), Ingredient("feather_robin_winter", 4)}, TECH.SCIENCE_ONE, {placer = "hogusporkusator_placer", min_spacing=2}, {"MAGIC", "STRUCTURES", "PROTOTYPERS"})
SortAfter("hogusporkusator", "researchlab4", "MAGIC")
SortAfter("hogusporkusator", "researchlab4", "STRUCTURES")
SortAfter("hogusporkusator", "researchlab4", "PROTOTYPERS")

AddRecipe2("bonestaff", {Ingredient("pugalisk_skull", 1), Ingredient("boneshard", 1), Ingredient("nightmarefuel", 2)}, TECH.MAGIC_THREE, {} , {"WEAPONS","MAGIC"})
SortAfter("bonestaff", "antlionhat", "MAGIC")
SortAfter("bonestaff", "trident", "WEAPONS")

AddRecipe2("ox_flute", {Ingredient("ox_horn", 1), Ingredient("nightmarefuel", 2), Ingredient("rope", 1)}, TECH.LOST, nil, {"MAGIC"})
SortAfter("ox_flute", "panflute", "MAGIC")

-- REFINE ---
AddRecipe2("goldnugget", {Ingredient("gold_dust", 6)}, TECH.SCIENCE_ONE, {no_deconstruction = true} , {"REFINE"})
AddRecipe2("clawpalmtree_sapling_item", {Ingredient("cork", 1), Ingredient("poop", 1)}, TECH.SCIENCE_ONE, {no_deconstruction = true, image = "clawpalmtree_sapling.tex"}, {"REFINE"})
AddRecipe2("venomgland", {Ingredient("froglegs_poison", 3)}, TECH.SCIENCE_TWO, {no_deconstruction = true} , {"REFINE"})

AddRecipe2("fabric", {Ingredient("bamboo", 3)}, TECH.LOST, nil, {"REFINE"})
SortAfter("fabric", "beeswax", "REFINE")

-- DECOR ---
AddRecipe2("turf_lawn", {Ingredient("cutgrass", 2), Ingredient("nitre", 1)}, TECH.SCIENCE_TWO, {numtogive = 4}, {"DECOR"})
SortAfter("turf_lawn", "turf_beard_rug", "DECOR")
AddRecipe2("turf_fields", {Ingredient("turf_rainforest", 1), Ingredient("ash", 1)}, TECH.SCIENCE_TWO, {numtogive = 4}, {"DECOR"})
SortAfter("turf_fields", "turf_lawn", "DECOR")
AddRecipe2("turf_deeprainforest_nocanopy", {Ingredient("bramble_bulb", 1), Ingredient("cutgrass", 2), Ingredient("ash", 1)}, TECH.SCIENCE_TWO, {numtogive = 4}, {"DECOR","GARDENING"})
SortAfter("turf_deeprainforest_nocanopy", "turf_fields", "DECOR")

-- NAUTICAL ---
AddRecipe2("boat_lograft", {Ingredient("log", 6), Ingredient("cutgrass", 4)}, TECH.NONE, {placer = "boat_lograft_placer", min_spacing=1, build_mode = BUILDMODE.WATER, build_distance = 4}, {"NAUTICAL"})
AquaticRecipe("boat_lograft", {distance = 4, platform_buffer_min = 2, aquatic_buffer_min = 1, boat = true})

AddRecipe2("boat_row", {Ingredient("boards", 3), Ingredient("vine", 4)}, TECH.SCIENCE_ONE, {placer = "boat_row_placer", min_spacing=1, build_mode = BUILDMODE.WATER, build_distance = 4}, {"NAUTICAL"})
AquaticRecipe("boat_row", {distance = 4, platform_buffer_min = 2, aquatic_buffer_min = 1, boat = true})

AddRecipe2("boat_cork", {Ingredient("cork", 4), Ingredient("rope", 1)}, TECH.SCIENCE_ONE, {placer = "boat_cork_placer", min_spacing=1, build_mode = BUILDMODE.WATER, build_distance = 4}, {"NAUTICAL"})
AquaticRecipe("boat_cork", {distance = 4, platform_buffer_min = 2, aquatic_buffer_min = 1, boat = true})

AddRecipe2("boat_cargo", {Ingredient("boards", 6), Ingredient("rope", 3)}, TECH.SCIENCE_ONE, {placer = "boat_cargo_placer", min_spacing=1, build_mode = BUILDMODE.WATER, build_distance = 4}, {"NAUTICAL"})
AquaticRecipe("boat_cargo", {distance = 4, platform_buffer_min = 2, aquatic_buffer_min = 1, boat = true})

AddRecipe2("boatrepairkit", {Ingredient("boards", 2), Ingredient("stinger", 2), Ingredient("rope", 2)}, TECH.SCIENCE_ONE, nil, {"NAUTICAL"})

AddRecipe2("boat_torch", {Ingredient("twigs", 2), Ingredient("torch", 1)}, TECH.SCIENCE_ONE, nil, {"LIGHT", "NAUTICAL"})

AddRecipe2("sail_snakeskin", {Ingredient("log", 4), Ingredient("rope", 2), Ingredient("snakeskin", 2, nil, nil, "snakeskin_scaly.tex")}, TECH.SCIENCE_TWO, {image = "sail_snakeskin_scaly.tex"}, {"NAUTICAL"})

AddRecipe2("trawlnet", {Ingredient("rope", 3), Ingredient("bamboo", 2)}, TECH.LOST, nil, {"TOOLS", "NAUTICAL"})
SortAfter("trawlnet", "fishingrod", "TOOLS")

-- CHARACTER ---

AddRecipe2("disguisehat", {Ingredient("twigs", 2), Ingredient("pigskin", 1), Ingredient("beardhair", 1)}, TECH.NONE, {builder_tag = "monster"}, {"CHARACTER", "CLOTHING"})
SortBefore("disguisehat", "spidereggsack", "CHARACTER")

AddRecipe2("poisonbalm", {Ingredient("livinglog", 1), Ingredient("venomgland", 1)}, TECH.NONE, {builder_tag = "plantkin"}, {"CHARACTER", "RESTORATION"})
SortAfter("poisonbalm", "armor_bramble", "CHARACTER")
SortBefore("poisonbalm", "healingsalve", "RESTORATION")

local function IsValidSprinklerTile(tile)
    return not TileGroupManager:IsOceanTile(tile) and (tile ~= WORLD_TILES.INVALID) and (tile ~= WORLD_TILES.IMPASSABLE)
end

local function GetValidWaterPointNearby(pt)
    local range = 20

    for x = pt.x - range, pt.x + range, 4 do
        for z = pt.z - range, pt.z + range, 4 do
            local tx, ty = TheWorld.Map:GetTileCoordsAtPoint(x, 0, z)
            local tile = TheWorld.Map:GetTile(tx, ty)

            if TileGroupManager:IsOceanTile(tile) then
                return true
            end
        end
    end

    return false
end

local function sprinkler_placetest(pt, rot)
    return GetValidWaterPointNearby(pt)
end

local function sprinkler_canbuild(inst, builder, pt)
    return sprinkler_placetest(pt)
end

--- GARDENING ---
AddRecipe2("sprinkler", {Ingredient("alloy", 2), Ingredient("bluegem", 1), Ingredient("ice", 6)}, TECH.SCIENCE_TWO, {placer = "sprinkler_placer", min_spacing=2, testfn = sprinkler_placetest, canbuild = sprinkler_canbuild}, {"GARDENING", "STRUCTURES"})

AddRecipe2("slow_farmplot", {Ingredient("cutgrass", 8), Ingredient("poop", 4), Ingredient("log", 4)}, TECH.SCIENCE_ONE, {placer = "slow_farmplot_placer", min_spacing=2}, {"GARDENING"})
AddRecipe2("fast_farmplot", {Ingredient("cutgrass", 10), Ingredient("poop", 6), Ingredient("rocks", 4)}, TECH.SCIENCE_TWO, {placer = "fast_farmplot_placer", min_spacing=2}, {"GARDENING"})

--- CITY ---

local function NotInInterior(pt)
    return not TheWorld.components.interiorspawner:IsInInterior(pt.x, pt.z)
end

local function NotInInterior_canbuild(inst, builder, pt)
    return NotInInterior(pt)
end

AddRecipe2("turf_foundation", {Ingredient("cutstone", 1)}, TECH.CITY, {nounlock = true, numtogive = 4})
AddRecipe2("turf_cobbleroad", {Ingredient("cutstone", 2), Ingredient("boards", 1)}, TECH.CITY, {nounlock = true, numtogive = 4})
AddRecipe2("city_lamp", {Ingredient("alloy", 1), Ingredient("transistor", 1),Ingredient("lantern",1)},  TECH.CITY, {nounlock = true, placer = "city_lamp_placer", min_spacing=2, testfn = NotInInterior, canbuild = NotInInterior_canbuild})

AddRecipe2("pighouse_city", {Ingredient("boards", 4), Ingredient("cutstone", 3), Ingredient("pigskin", 4)}, TECH.CITY, {nounlock = true, placer = "pighouse_city_placer", min_spacing=3.5, testfn = NotInInterior, canbuild = NotInInterior_canbuild})

AddRecipe2("pig_shop_deli", {Ingredient("boards", 4), Ingredient("honeyham", 1), Ingredient("pigskin", 4)}, TECH.CITY, {nounlock = true, placer = "pig_shop_deli_placer", min_spacing=3.5, testfn = NotInInterior, canbuild = NotInInterior_canbuild})
AddRecipe2("pig_shop_general", {Ingredient("boards", 4), Ingredient("axe", 3), Ingredient("pigskin", 4)}, TECH.CITY, {nounlock = true, placer = "pig_shop_general_placer", min_spacing=3.5, testfn = NotInInterior, canbuild = NotInInterior_canbuild})

AddRecipe2("pig_shop_hoofspa", {Ingredient("boards", 4), Ingredient("bandage", 3), Ingredient("pigskin", 4)}, TECH.CITY, {nounlock = true, placer = "pig_shop_hoofspa_placer", min_spacing=3.5, testfn = NotInInterior, canbuild = NotInInterior_canbuild})
AddRecipe2("pig_shop_produce", {Ingredient("boards", 4), Ingredient("eggplant", 3), Ingredient("pigskin", 4)}, TECH.CITY, {nounlock = true, placer = "pig_shop_produce_placer", min_spacing=3.5, testfn = NotInInterior, canbuild = NotInInterior_canbuild})

AddRecipe2("pig_shop_florist", {Ingredient("boards", 4), Ingredient("petals", 12), Ingredient("pigskin", 4)}, TECH.CITY, {nounlock = true, placer = "pig_shop_florist_placer", min_spacing=3.5, testfn = NotInInterior, canbuild = NotInInterior_canbuild})
AddRecipe2("pig_shop_antiquities", {Ingredient("boards", 4), Ingredient("ballpein_hammer", 3), Ingredient("pigskin", 4)}, TECH.CITY, {nounlock = true, placer = "pig_shop_antiquities_placer", min_spacing=3.5, testfn = NotInInterior, canbuild = NotInInterior_canbuild})

AddRecipe2("pig_shop_arcane", {Ingredient("boards", 4), Ingredient("nightmarefuel", 1), Ingredient("pigskin", 4)}, TECH.CITY, {nounlock = true, placer = "pig_shop_arcane_placer", min_spacing=3.5, testfn = NotInInterior, canbuild = NotInInterior_canbuild})
AddRecipe2("pig_shop_weapons", {Ingredient("boards", 4), Ingredient("spear", 3), Ingredient("pigskin", 4)}, TECH.CITY, {nounlock = true, placer = "pig_shop_weapons_placer", min_spacing=3.5, testfn = NotInInterior, canbuild = NotInInterior_canbuild})
AddRecipe2("pig_shop_hatshop", {Ingredient("boards", 4), Ingredient("tophat", 2), Ingredient("pigskin", 4)}, TECH.CITY, {nounlock = true, placer = "pig_shop_hatshop_placer", min_spacing=3.5, testfn = NotInInterior, canbuild = NotInInterior_canbuild})
AddRecipe2("pig_shop_bank", {Ingredient("cutstone", 4), Ingredient("oinc", 100), Ingredient("pigskin", 4)}, TECH.CITY, {nounlock = true, placer = "pig_shop_bank_placer", min_spacing=3.5, testfn = NotInInterior, canbuild = NotInInterior_canbuild})

AddRecipe2("pig_shop_tinker", {Ingredient("magnifying_glass", 2), Ingredient("pigskin", 4)}, TECH.CITY, {nounlock = true, placer = "pig_shop_tinker_placer", min_spacing=3.5, testfn = NotInInterior, canbuild = NotInInterior_canbuild})

AddRecipe2("pig_shop_cityhall_player", {Ingredient("boards", 4), Ingredient("goldnugget", 4), Ingredient("pigskin", 4)}, TECH.CITY, {nounlock = true, placer = "pig_shop_cityhall_placer", min_spacing=3.5, testfn = NotInInterior, canbuild = NotInInterior_canbuild})

AddRecipe2("pig_guard_tower", {Ingredient("cutstone", 3), Ingredient("halberd", 1), Ingredient("pigskin", 4)}, TECH.CITY, {nounlock = true, placer = "pig_guard_tower_placer", min_spacing=3.5, testfn = NotInInterior, canbuild = NotInInterior_canbuild})

AddRecipe2("securitycontract", {Ingredient("oinc", 10)}, TECH.CITY, {nounlock = true})

AddRecipe2("playerhouse_city", {Ingredient("boards", 4), Ingredient("cutstone", 3), Ingredient("oinc", 30)}, TECH.CITY, {nounlock = true, placer = "playerhouse_city_placer", min_spacing=4, testfn = NotInInterior, canbuild = NotInInterior_canbuild})

AddRecipe2("hedge_block_item", {Ingredient("clippings", 9), Ingredient("nitre", 1)}, TECH.CITY, {nounlock = true, numtogive = 3})
AddRecipe2("hedge_cone_item", {Ingredient("clippings", 9), Ingredient("nitre", 1)}, TECH.CITY, {nounlock = true, numtogive = 3})
AddRecipe2("hedge_layered_item", {Ingredient("clippings", 9), Ingredient("nitre", 1)}, TECH.CITY, {nounlock = true, numtogive = 3})

AddRecipe2("lawnornament_1", {Ingredient("oinc", 10)}, TECH.CITY, {nounlock = true, min_spacing = 1, placer = "lawnornament_1_placer", min_spacing=2, testfn = NotInInterior, canbuild = NotInInterior_canbuild})
AddRecipe2("lawnornament_2", {Ingredient("oinc", 10)}, TECH.CITY, {nounlock = true, min_spacing = 1, placer = "lawnornament_2_placer", min_spacing=2, testfn = NotInInterior, canbuild = NotInInterior_canbuild})
AddRecipe2("lawnornament_3", {Ingredient("oinc", 10)}, TECH.CITY, {nounlock = true, min_spacing = 1, placer = "lawnornament_3_placer", min_spacing=2, testfn = NotInInterior, canbuild = NotInInterior_canbuild})
AddRecipe2("lawnornament_4", {Ingredient("oinc", 10)}, TECH.CITY, {nounlock = true, min_spacing = 1, placer = "lawnornament_4_placer", min_spacing=2, testfn = NotInInterior, canbuild = NotInInterior_canbuild})
AddRecipe2("lawnornament_5", {Ingredient("oinc", 10)}, TECH.CITY, {nounlock = true, min_spacing = 1, placer = "lawnornament_5_placer", min_spacing=2, testfn = NotInInterior, canbuild = NotInInterior_canbuild})
AddRecipe2("lawnornament_6", {Ingredient("oinc", 10)}, TECH.CITY, {nounlock = true, min_spacing = 1, placer = "lawnornament_6_placer", min_spacing=2, testfn = NotInInterior, canbuild = NotInInterior_canbuild})
AddRecipe2("lawnornament_7", {Ingredient("oinc", 10)}, TECH.CITY, {nounlock = true, min_spacing = 1, placer = "lawnornament_7_placer", min_spacing=2, testfn = NotInInterior, canbuild = NotInInterior_canbuild})

--- HOME ---
AddRecipe2("player_house_cottage_craft", {Ingredient("oinc", 10)}, TECH.HOME, {nounlock = true}, {"HOME_MISC"})
AddRecipe2("player_house_tudor_craft",   {Ingredient("oinc", 10)}, TECH.HOME, {nounlock = true}, {"HOME_MISC"})
AddRecipe2("player_house_gothic_craft",  {Ingredient("oinc", 10)}, TECH.HOME, {nounlock = true}, {"HOME_MISC"})
AddRecipe2("player_house_brick_craft",   {Ingredient("oinc", 10)}, TECH.HOME, {nounlock = true}, {"HOME_MISC"})
AddRecipe2("player_house_turret_craft",  {Ingredient("oinc", 10)}, TECH.HOME, {nounlock = true}, {"HOME_MISC"})
AddRecipe2("player_house_villa_craft",   {Ingredient("oinc", 30)}, TECH.HOME, {nounlock = true}, {"HOME_MISC"})
AddRecipe2("player_house_manor_craft",   {Ingredient("oinc", 30)}, TECH.HOME, {nounlock = true}, {"HOME_MISC"})

AddRecipe2("deco_chair_classic",  {Ingredient("oinc", 2)},  TECH.HOME, {nounlock = true, placer = "chair_classic_placer", min_spacing=2,  image = "reno_chair_classic.tex"},  {"HOME_FURNITURE"})
AddRecipe2("deco_chair_corner",   {Ingredient("oinc", 2)},  TECH.HOME, {nounlock = true, placer = "chair_corner_placer", min_spacing=2,   image = "reno_chair_corner.tex"},   {"HOME_FURNITURE"})
AddRecipe2("deco_chair_bench",    {Ingredient("oinc", 2)},  TECH.HOME, {nounlock = true, placer = "chair_bench_placer", min_spacing=2,    image = "reno_chair_bench.tex"},    {"HOME_FURNITURE"})
AddRecipe2("deco_chair_horned",   {Ingredient("oinc", 2)},  TECH.HOME, {nounlock = true, placer = "chair_horned_placer", min_spacing=2,   image = "reno_chair_horned.tex"},   {"HOME_FURNITURE"})
AddRecipe2("deco_chair_footrest", {Ingredient("oinc", 2)},  TECH.HOME, {nounlock = true, placer = "chair_footrest_placer", min_spacing=2, image = "reno_chair_footrest.tex"}, {"HOME_FURNITURE"})
AddRecipe2("deco_chair_lounge",   {Ingredient("oinc", 2)},  TECH.HOME, {nounlock = true, placer = "chair_lounge_placer", min_spacing=2,   image = "reno_chair_lounge.tex"},   {"HOME_FURNITURE"})
AddRecipe2("deco_chair_massager", {Ingredient("oinc", 2)},  TECH.HOME, {nounlock = true, placer = "chair_massager_placer", min_spacing=2, image = "reno_chair_massager.tex"}, {"HOME_FURNITURE"})
AddRecipe2("deco_chair_stuffed",  {Ingredient("oinc", 2)},  TECH.HOME, {nounlock = true, placer = "chair_stuffed_placer", min_spacing=2,  image = "reno_chair_stuffed.tex"},  {"HOME_FURNITURE"})
AddRecipe2("deco_chair_rocking",  {Ingredient("oinc", 2)},  TECH.HOME, {nounlock = true, placer = "chair_rocking_placer", min_spacing=2,  image = "reno_chair_rocking.tex"},  {"HOME_FURNITURE"})
AddRecipe2("deco_chair_ottoman",  {Ingredient("oinc", 2)},  TECH.HOME, {nounlock = true, placer = "chair_ottoman_placer", min_spacing=2,  image = "reno_chair_ottoman.tex"},  {"HOME_FURNITURE"})
AddRecipe2("deco_chaise",         {Ingredient("oinc", 15)}, TECH.HOME, {nounlock = true, placer = "deco_chaise_placer", min_spacing=3,    image = "reno_chair_chaise.tex"},   {"HOME_FURNITURE"})

AddRecipe2("shelf_wood",         {Ingredient("oinc", 2)}, TECH.HOME, {nounlock = true, build_mode = BUILDMODE.HOME_DECOR, placer = "shelf_wood_placer",         image = "reno_shelves_wood.tex"},         {"HOME_FURNITURE"})
AddRecipe2("shelf_basic",        {Ingredient("oinc", 2)}, TECH.HOME, {nounlock = true, build_mode = BUILDMODE.HOME_DECOR, placer = "shelf_basic_placer",        image = "reno_shelves_basic.tex"},        {"HOME_FURNITURE"})
AddRecipe2("shelf_cinderblocks", {Ingredient("oinc", 1)}, TECH.HOME, {nounlock = true, build_mode = BUILDMODE.HOME_DECOR, placer = "shelf_cinderblocks_placer", image = "reno_shelves_cinderblocks.tex"}, {"HOME_FURNITURE"})
AddRecipe2("shelf_marble",       {Ingredient("oinc", 8)}, TECH.HOME, {nounlock = true, build_mode = BUILDMODE.HOME_DECOR, placer = "shelf_marble_placer",       image = "reno_shelves_marble.tex"},       {"HOME_FURNITURE"})
AddRecipe2("shelf_glass",        {Ingredient("oinc", 8)}, TECH.HOME, {nounlock = true, build_mode = BUILDMODE.HOME_DECOR, placer = "shelf_glass_placer",        image = "reno_shelves_glass.tex"},        {"HOME_FURNITURE"})
AddRecipe2("shelf_ladder",       {Ingredient("oinc", 8)}, TECH.HOME, {nounlock = true, build_mode = BUILDMODE.HOME_DECOR, placer = "shelf_ladder_placer",       image = "reno_shelves_ladder.tex"},       {"HOME_FURNITURE"})
AddRecipe2("shelf_hutch",        {Ingredient("oinc", 8)}, TECH.HOME, {nounlock = true, build_mode = BUILDMODE.HOME_DECOR, placer = "shelf_hutch_placer",        image = "reno_shelves_hutch.tex"},        {"HOME_FURNITURE"})
AddRecipe2("shelf_industrial",   {Ingredient("oinc", 8)}, TECH.HOME, {nounlock = true, build_mode = BUILDMODE.HOME_DECOR, placer = "shelf_industrial_placer",   image = "reno_shelves_industrial.tex"},   {"HOME_FURNITURE"})
AddRecipe2("shelf_adjustable",   {Ingredient("oinc", 8)}, TECH.HOME, {nounlock = true, build_mode = BUILDMODE.HOME_DECOR, placer = "shelf_adjustable_placer",   image = "reno_shelves_adjustable.tex"},   {"HOME_FURNITURE"})
AddRecipe2("shelf_midcentury",   {Ingredient("oinc", 6)}, TECH.HOME, {nounlock = true, build_mode = BUILDMODE.HOME_DECOR, placer = "shelf_midcentury_placer",   image = "reno_shelves_midcentury.tex"},   {"HOME_FURNITURE"})
AddRecipe2("shelf_wallmount",    {Ingredient("oinc", 6)}, TECH.HOME, {nounlock = true, build_mode = BUILDMODE.HOME_DECOR, placer = "shelf_wallmount_placer",    image = "reno_shelves_wallmount.tex"},    {"HOME_FURNITURE"})
AddRecipe2("shelf_aframe",       {Ingredient("oinc", 6)}, TECH.HOME, {nounlock = true, build_mode = BUILDMODE.HOME_DECOR, placer = "shelf_aframe_placer",       image = "reno_shelves_aframe.tex"},       {"HOME_FURNITURE"})
AddRecipe2("shelf_crates",       {Ingredient("oinc", 6)}, TECH.HOME, {nounlock = true, build_mode = BUILDMODE.HOME_DECOR, placer = "shelf_crates_placer",       image = "reno_shelves_crates.tex"},       {"HOME_FURNITURE"})
AddRecipe2("shelf_fridge",       {Ingredient("oinc", 6)}, TECH.HOME, {nounlock = true, build_mode = BUILDMODE.HOME_DECOR, placer = "shelf_fridge_placer",       image = "reno_shelves_fridge.tex"},       {"HOME_FURNITURE"})
AddRecipe2("shelf_floating",     {Ingredient("oinc", 6)}, TECH.HOME, {nounlock = true, build_mode = BUILDMODE.HOME_DECOR, placer = "shelf_floating_placer",     image = "reno_shelves_floating.tex"},     {"HOME_FURNITURE"})
AddRecipe2("shelf_pipe",         {Ingredient("oinc", 6)}, TECH.HOME, {nounlock = true, build_mode = BUILDMODE.HOME_DECOR, placer = "shelf_pipe_placer",         image = "reno_shelves_pipe.tex"},         {"HOME_FURNITURE"})
AddRecipe2("shelf_hattree",      {Ingredient("oinc", 6)}, TECH.HOME, {nounlock = true, build_mode = BUILDMODE.HOME_DECOR, placer = "shelf_hattree_placer",      image = "reno_shelves_hattree.tex"},      {"HOME_FURNITURE"})
AddRecipe2("shelf_pallet",       {Ingredient("oinc", 6)}, TECH.HOME, {nounlock = true, build_mode = BUILDMODE.HOME_DECOR, placer = "shelf_pallet_placer",       image = "reno_shelves_pallet.tex"},       {"HOME_FURNITURE"})

AddRecipe2("rug_round",     {Ingredient("oinc", 2)},  TECH.HOME, {nounlock = true, build_mode = BUILDMODE.HOME_DECOR, placer = "rug_round_placer",     image = "reno_rug_round.tex"},      {"HOME_RUG"})
AddRecipe2("rug_square",    {Ingredient("oinc", 2)},  TECH.HOME, {nounlock = true, build_mode = BUILDMODE.HOME_DECOR, placer = "rug_square_placer",    image = "reno_rug_square.tex"},     {"HOME_RUG"})
AddRecipe2("rug_oval",      {Ingredient("oinc", 2)},  TECH.HOME, {nounlock = true, build_mode = BUILDMODE.HOME_DECOR, placer = "rug_oval_placer",      image = "reno_rug_oval.tex"},       {"HOME_RUG"})
AddRecipe2("rug_rectangle", {Ingredient("oinc", 3)},  TECH.HOME, {nounlock = true, build_mode = BUILDMODE.HOME_DECOR, placer = "rug_rectangle_placer", image = "reno_rug_rectangle.tex"},  {"HOME_RUG"})
AddRecipe2("rug_fur",       {Ingredient("oinc", 5)},  TECH.HOME, {nounlock = true, build_mode = BUILDMODE.HOME_DECOR, placer = "rug_fur_placer",       image = "reno_rug_fur.tex"},        {"HOME_RUG"})
AddRecipe2("rug_hedgehog",  {Ingredient("oinc", 5)},  TECH.HOME, {nounlock = true, build_mode = BUILDMODE.HOME_DECOR, placer = "rug_hedgehog_placer",  image = "reno_rug_hedgehog.tex"},   {"HOME_RUG"})
AddRecipe2("rug_porcupuss", {Ingredient("oinc", 10)}, TECH.HOME, {nounlock = true, build_mode = BUILDMODE.HOME_DECOR, placer = "rug_porcupuss_placer", image = "reno_rug_porcupuss.tex"},  {"HOME_RUG"})
AddRecipe2("rug_hoofprint", {Ingredient("oinc", 5)},  TECH.HOME, {nounlock = true, build_mode = BUILDMODE.HOME_DECOR, placer = "rug_hoofprint_placer", image = "reno_rug_hoofprint.tex"},  {"HOME_RUG"})
AddRecipe2("rug_octagon",   {Ingredient("oinc", 5)},  TECH.HOME, {nounlock = true, build_mode = BUILDMODE.HOME_DECOR, placer = "rug_octagon_placer",   image = "reno_rug_octagon.tex"},    {"HOME_RUG"})
AddRecipe2("rug_swirl",     {Ingredient("oinc", 5)},  TECH.HOME, {nounlock = true, build_mode = BUILDMODE.HOME_DECOR, placer = "rug_swirl_placer",     image = "reno_rug_swirl.tex"},      {"HOME_RUG"})
AddRecipe2("rug_catcoon",   {Ingredient("oinc", 5)},  TECH.HOME, {nounlock = true, build_mode = BUILDMODE.HOME_DECOR, placer = "rug_catcoon_placer",   image = "reno_rug_catcoon.tex"},    {"HOME_RUG"})
AddRecipe2("rug_rubbermat", {Ingredient("oinc", 5)},  TECH.HOME, {nounlock = true, build_mode = BUILDMODE.HOME_DECOR, placer = "rug_rubbermat_placer", image = "reno_rug_rubbermat.tex"},  {"HOME_RUG"})
AddRecipe2("rug_web",       {Ingredient("oinc", 5)},  TECH.HOME, {nounlock = true, build_mode = BUILDMODE.HOME_DECOR, placer = "rug_web_placer",       image = "reno_rug_web.tex"},        {"HOME_RUG"})
AddRecipe2("rug_metal",     {Ingredient("oinc", 5)},  TECH.HOME, {nounlock = true, build_mode = BUILDMODE.HOME_DECOR, placer = "rug_metal_placer",     image = "reno_rug_metal.tex"},      {"HOME_RUG"})
AddRecipe2("rug_wormhole",  {Ingredient("oinc", 5)},  TECH.HOME, {nounlock = true, build_mode = BUILDMODE.HOME_DECOR, placer = "rug_wormhole_placer",  image = "reno_rug_wormhole.tex"},   {"HOME_RUG"})
AddRecipe2("rug_braid",     {Ingredient("oinc", 5)},  TECH.HOME, {nounlock = true, build_mode = BUILDMODE.HOME_DECOR, placer = "rug_braid_placer",     image = "reno_rug_braid.tex"},      {"HOME_RUG"})
AddRecipe2("rug_beard",     {Ingredient("oinc", 5)},  TECH.HOME, {nounlock = true, build_mode = BUILDMODE.HOME_DECOR, placer = "rug_beard_placer",     image = "reno_rug_beard.tex"},      {"HOME_RUG"})
AddRecipe2("rug_nailbed",   {Ingredient("oinc", 5)},  TECH.HOME, {nounlock = true, build_mode = BUILDMODE.HOME_DECOR, placer = "rug_nailbed_placer",   image = "reno_rug_nailbed.tex"},    {"HOME_RUG"})
AddRecipe2("rug_crime",     {Ingredient("oinc", 5)},  TECH.HOME, {nounlock = true, build_mode = BUILDMODE.HOME_DECOR, placer = "rug_crime_placer",     image = "reno_rug_crime.tex"},      {"HOME_RUG"})
AddRecipe2("rug_tiles",     {Ingredient("oinc", 5)},  TECH.HOME, {nounlock = true, build_mode = BUILDMODE.HOME_DECOR, placer = "rug_tiles_placer",     image = "reno_rug_tiles.tex"},      {"HOME_RUG"})

AddRecipe2("deco_lamp_fringe",       {Ingredient("oinc", 8)}, TECH.HOME, {nounlock = true, placer = "deco_lamp_fringe_placer", min_spacing=2,       image = "reno_lamp_fringe.tex"},       {"HOME_LAMP"})
AddRecipe2("deco_lamp_stainglass",   {Ingredient("oinc", 8)}, TECH.HOME, {nounlock = true, placer = "deco_lamp_stainglass_placer", min_spacing=2,   image = "reno_lamp_stainglass.tex"},   {"HOME_LAMP"})
AddRecipe2("deco_lamp_downbridge",   {Ingredient("oinc", 8)}, TECH.HOME, {nounlock = true, placer = "deco_lamp_downbridge_placer", min_spacing=2,   image = "reno_lamp_downbridge.tex"},   {"HOME_LAMP"})
AddRecipe2("deco_lamp_2embroidered", {Ingredient("oinc", 8)}, TECH.HOME, {nounlock = true, placer = "deco_lamp_2embroidered_placer", min_spacing=2, image = "reno_lamp_2embroidered.tex"}, {"HOME_LAMP"})
AddRecipe2("deco_lamp_ceramic",      {Ingredient("oinc", 8)}, TECH.HOME, {nounlock = true, placer = "deco_lamp_ceramic_placer", min_spacing=2,      image = "reno_lamp_ceramic.tex"},      {"HOME_LAMP"})
AddRecipe2("deco_lamp_glass",        {Ingredient("oinc", 8)}, TECH.HOME, {nounlock = true, placer = "deco_lamp_glass_placer", min_spacing=2,        image = "reno_lamp_glass.tex"},        {"HOME_LAMP"})
AddRecipe2("deco_lamp_2fringes",     {Ingredient("oinc", 8)}, TECH.HOME, {nounlock = true, placer = "deco_lamp_2fringes_placer", min_spacing=2,     image = "reno_lamp_2fringes.tex"},     {"HOME_LAMP"})
AddRecipe2("deco_lamp_candelabra",   {Ingredient("oinc", 8)}, TECH.HOME, {nounlock = true, placer = "deco_lamp_candelabra_placer", min_spacing=2,   image = "reno_lamp_candelabra.tex"},   {"HOME_LAMP"})
AddRecipe2("deco_lamp_elizabethan",  {Ingredient("oinc", 8)}, TECH.HOME, {nounlock = true, placer = "deco_lamp_elizabethan_placer", min_spacing=2,  image = "reno_lamp_elizabethan.tex"},  {"HOME_LAMP"})
AddRecipe2("deco_lamp_gothic",       {Ingredient("oinc", 8)}, TECH.HOME, {nounlock = true, placer = "deco_lamp_gothic_placer", min_spacing=2,       image = "reno_lamp_gothic.tex"},       {"HOME_LAMP"})
AddRecipe2("deco_lamp_orb",          {Ingredient("oinc", 8)}, TECH.HOME, {nounlock = true, placer = "deco_lamp_orb_placer", min_spacing=2,          image = "reno_lamp_orb.tex"},          {"HOME_LAMP"})
AddRecipe2("deco_lamp_bellshade",    {Ingredient("oinc", 8)}, TECH.HOME, {nounlock = true, placer = "deco_lamp_bellshade_placer", min_spacing=2,    image = "reno_lamp_bellshade.tex"},    {"HOME_LAMP"})
AddRecipe2("deco_lamp_crystals",     {Ingredient("oinc", 8)}, TECH.HOME, {nounlock = true, placer = "deco_lamp_crystals_placer", min_spacing=2,     image = "reno_lamp_crystals.tex"},     {"HOME_LAMP"})
AddRecipe2("deco_lamp_upturn",       {Ingredient("oinc", 8)}, TECH.HOME, {nounlock = true, placer = "deco_lamp_upturn_placer", min_spacing=2,       image = "reno_lamp_upturn.tex"},       {"HOME_LAMP"})
AddRecipe2("deco_lamp_2upturns",     {Ingredient("oinc", 8)}, TECH.HOME, {nounlock = true, placer = "deco_lamp_2upturns_placer", min_spacing=2,     image = "reno_lamp_2upturns.tex"},     {"HOME_LAMP"})
AddRecipe2("deco_lamp_spool",        {Ingredient("oinc", 8)}, TECH.HOME, {nounlock = true, placer = "deco_lamp_spool_placer", min_spacing=2,        image = "reno_lamp_spool.tex"},        {"HOME_LAMP"})
AddRecipe2("deco_lamp_edison",       {Ingredient("oinc", 8)}, TECH.HOME, {nounlock = true, placer = "deco_lamp_edison_placer", min_spacing=2,       image = "reno_lamp_edison.tex"},       {"HOME_LAMP"})
AddRecipe2("deco_lamp_adjustable",   {Ingredient("oinc", 8)}, TECH.HOME, {nounlock = true, placer = "deco_lamp_adjustable_placer", min_spacing=2,   image = "reno_lamp_adjustable.tex"},   {"HOME_LAMP"})
AddRecipe2("deco_lamp_rightangles",  {Ingredient("oinc", 8)}, TECH.HOME, {nounlock = true, placer = "deco_lamp_rightangles_placer", min_spacing=2,  image = "reno_lamp_rightangles.tex"},  {"HOME_LAMP"})
AddRecipe2("deco_lamp_hoofspa",      {Ingredient("oinc", 8)}, TECH.HOME, {nounlock = true, placer = "deco_lamp_hoofspa_placer", min_spacing=2,      image = "reno_lamp_hoofspa.tex"},      {"HOME_LAMP"})

-- AddRecipe2("deco_plantholder_fancy",        {Ingredient("oinc", 6)}, TECH.HOME, {nounlock = true, placer = "deco_plantholder_fancy_placer", min_spacing=2, image = "reno_plantholder_fancy.tex"}, {"HOME_PLANTHOLDER"})
AddRecipe2("deco_plantholder_basic",        {Ingredient("oinc", 6)}, TECH.HOME, {nounlock = true, placer = "deco_plantholder_basic_placer", min_spacing=2,        image = "reno_plantholder_basic.tex"},        {"HOME_PLANTHOLDER"})
AddRecipe2("deco_plantholder_wip",          {Ingredient("oinc", 6)}, TECH.HOME, {nounlock = true, placer = "deco_plantholder_wip_placer", min_spacing=2,          image = "reno_plantholder_wip.tex"},          {"HOME_PLANTHOLDER"})
AddRecipe2("deco_plantholder_marble",       {Ingredient("oinc", 6)}, TECH.HOME, {nounlock = true, placer = "deco_plantholder_marble_placer", min_spacing=2,       image = "reno_plantholder_marble.tex"},       {"HOME_PLANTHOLDER"})
AddRecipe2("deco_plantholder_bonsai",       {Ingredient("oinc", 6)}, TECH.HOME, {nounlock = true, placer = "deco_plantholder_bonsai_placer", min_spacing=2,       image = "reno_plantholder_bonsai.tex"},       {"HOME_PLANTHOLDER"})
AddRecipe2("deco_plantholder_dishgarden",   {Ingredient("oinc", 6)}, TECH.HOME, {nounlock = true, placer = "deco_plantholder_dishgarden_placer", min_spacing=2,   image = "reno_plantholder_dishgarden.tex"},   {"HOME_PLANTHOLDER"})
AddRecipe2("deco_plantholder_philodendron", {Ingredient("oinc", 6)}, TECH.HOME, {nounlock = true, placer = "deco_plantholder_philodendron_placer", min_spacing=2, image = "reno_plantholder_philodendron.tex"}, {"HOME_PLANTHOLDER"})
AddRecipe2("deco_plantholder_orchid",       {Ingredient("oinc", 6)}, TECH.HOME, {nounlock = true, placer = "deco_plantholder_orchid_placer", min_spacing=2,       image = "reno_plantholder_orchid.tex"},       {"HOME_PLANTHOLDER"})
AddRecipe2("deco_plantholder_draceana",     {Ingredient("oinc", 6)}, TECH.HOME, {nounlock = true, placer = "deco_plantholder_draceana_placer", min_spacing=2,     image = "reno_plantholder_draceana.tex"},     {"HOME_PLANTHOLDER"})
AddRecipe2("deco_plantholder_xerographica", {Ingredient("oinc", 6)}, TECH.HOME, {nounlock = true, placer = "deco_plantholder_xerographica_placer", min_spacing=2, image = "reno_plantholder_xerographica.tex"}, {"HOME_PLANTHOLDER"})
AddRecipe2("deco_plantholder_birdcage",     {Ingredient("oinc", 6)}, TECH.HOME, {nounlock = true, placer = "deco_plantholder_birdcage_placer", min_spacing=2,     image = "reno_plantholder_birdcage.tex"},     {"HOME_PLANTHOLDER"})
AddRecipe2("deco_plantholder_palm",         {Ingredient("oinc", 6)}, TECH.HOME, {nounlock = true, placer = "deco_plantholder_palm_placer", min_spacing=2,         image = "reno_plantholder_palm.tex"},         {"HOME_PLANTHOLDER"})
AddRecipe2("deco_plantholder_zz",           {Ingredient("oinc", 6)}, TECH.HOME, {nounlock = true, placer = "deco_plantholder_zz_placer", min_spacing=2,           image = "reno_plantholder_zz.tex"},           {"HOME_PLANTHOLDER"})
AddRecipe2("deco_plantholder_fernstand",    {Ingredient("oinc", 6)}, TECH.HOME, {nounlock = true, placer = "deco_plantholder_fernstand_placer", min_spacing=2,    image = "reno_plantholder_fernstand.tex"},    {"HOME_PLANTHOLDER"})
AddRecipe2("deco_plantholder_fern",         {Ingredient("oinc", 6)}, TECH.HOME, {nounlock = true, placer = "deco_plantholder_fern_placer", min_spacing=2,         image = "reno_plantholder_fern.tex"},         {"HOME_PLANTHOLDER"})
AddRecipe2("deco_plantholder_terrarium",    {Ingredient("oinc", 6)}, TECH.HOME, {nounlock = true, placer = "deco_plantholder_terrarium_placer", min_spacing=2,    image = "reno_plantholder_terrarium.tex"},    {"HOME_PLANTHOLDER"})
AddRecipe2("deco_plantholder_plantpet",     {Ingredient("oinc", 6)}, TECH.HOME, {nounlock = true, placer = "deco_plantholder_plantpet_placer", min_spacing=2,     image = "reno_plantholder_plantpet.tex"},     {"HOME_PLANTHOLDER"})
AddRecipe2("deco_plantholder_traps",        {Ingredient("oinc", 6)}, TECH.HOME, {nounlock = true, placer = "deco_plantholder_traps_placer", min_spacing=2,        image = "reno_plantholder_traps.tex"},        {"HOME_PLANTHOLDER"})
AddRecipe2("deco_plantholder_pitchers",     {Ingredient("oinc", 6)}, TECH.HOME, {nounlock = true, placer = "deco_plantholder_pitchers_placer", min_spacing=2,     image = "reno_plantholder_pitchers.tex"},     {"HOME_PLANTHOLDER"})

AddRecipe2("deco_plantholder_winterfeasttreeofsadness", {Ingredient("oinc", 2), Ingredient("twigs", 1)}, TECH.HOME, {onunlock = true, placer = "deco_plantholder_winterfeasttreeofsadness_placer", min_spacing=2, image = "reno_plantholder_winterfeasttreeofsadness.tex"}, {"HOME_PLANTHOLDER"})
AddRecipe2("deco_plantholder_winterfeasttree",          {Ingredient("oinc", 50)},                        TECH.HOME, {onunlock = true, placer = "deco_plantholder_winterfeasttree_placer", min_spacing=2,          image = "reno_lamp_festivetree.tex"},                     {"HOME_PLANTHOLDER"})

AddRecipe2("deco_table_round",  {Ingredient("oinc", 2)}, TECH.HOME, {nounlock= true, placer = "deco_table_round_placer", min_spacing=2,  image = "reno_table_round.tex"},  {"HOME_FURNITURE"})
AddRecipe2("deco_table_banker", {Ingredient("oinc", 4)}, TECH.HOME, {nounlock= true, placer = "deco_table_banker_placer", min_spacing=2, image = "reno_table_banker.tex"}, {"HOME_FURNITURE"})
AddRecipe2("deco_table_diy",    {Ingredient("oinc", 3)}, TECH.HOME, {nounlock= true, placer = "deco_table_diy_placer", min_spacing=2,    image = "reno_table_diy.tex"},    {"HOME_FURNITURE"})
AddRecipe2("deco_table_raw",    {Ingredient("oinc", 1)}, TECH.HOME, {nounlock= true, placer = "deco_table_raw_placer", min_spacing=2,    image = "reno_table_raw.tex"},    {"HOME_FURNITURE"})
AddRecipe2("deco_table_crate",  {Ingredient("oinc", 1)}, TECH.HOME, {nounlock= true, placer = "deco_table_crate_placer", min_spacing=2,  image = "reno_table_crate.tex"},  {"HOME_FURNITURE"})
AddRecipe2("deco_table_chess",  {Ingredient("oinc", 1)}, TECH.HOME, {nounlock= true, placer = "deco_table_chess_placer", min_spacing=2,  image = "reno_table_chess.tex"},  {"HOME_FURNITURE"})

-- AddRecipe2("deco_wallornament_fulllength_mirror", {Ingredient("oinc", 10)},                         TECH.HOME, {nounlock = true, build_mode = BUILDMODE.HOME_DECOR, placer = "deco_wallornament_fulllength_mirror_placer",   image = "reno_wallornament_fulllength_mirror"}, {"HOME_WALL_DECORATION"})
AddRecipe2("deco_wallornament_photo",             {Ingredient("oinc", 2)},                          TECH.HOME, {nounlock = true, build_mode = BUILDMODE.HOME_DECOR, placer = "deco_wallornament_photo_placer",               image = "reno_wallornament_photo.tex"},             {"HOME_WALL_DECORATION"})
AddRecipe2("deco_wallornament_embroidery_hoop",   {Ingredient("oinc", 3)},                          TECH.HOME, {nounlock = true, build_mode = BUILDMODE.HOME_DECOR, placer = "deco_wallornament_embroidery_hoop_placer",     image = "reno_wallornament_embroidery_hoop.tex"},   {"HOME_WALL_DECORATION"})
AddRecipe2("deco_wallornament_mosaic",            {Ingredient("oinc", 4)},                          TECH.HOME, {nounlock = true, build_mode = BUILDMODE.HOME_DECOR, placer = "deco_wallornament_mosaic_placer",              image = "reno_wallornament_mosaic.tex"},            {"HOME_WALL_DECORATION"})
AddRecipe2("deco_wallornament_wreath",            {Ingredient("oinc", 4)},                          TECH.HOME, {nounlock = true, build_mode = BUILDMODE.HOME_DECOR, placer = "deco_wallornament_wreath_placer",              image = "reno_wallornament_wreath.tex"},            {"HOME_WALL_DECORATION"})
AddRecipe2("deco_wallornament_axe",               {Ingredient("oinc", 5),  Ingredient("axe", 1)},   TECH.HOME, {nounlock = true, build_mode = BUILDMODE.HOME_DECOR, placer = "deco_wallornament_axe_placer",                 image = "reno_wallornament_axe.tex"},               {"HOME_WALL_DECORATION"})
AddRecipe2("deco_wallornament_hunt",              {Ingredient("oinc", 5),  Ingredient("spear", 1)}, TECH.HOME, {nounlock = true, build_mode = BUILDMODE.HOME_DECOR, placer = "deco_wallornament_hunt_placer",                image = "reno_wallornament_hunt.tex"},              {"HOME_WALL_DECORATION"})
AddRecipe2("deco_wallornament_periodic_table",    {Ingredient("oinc", 5)},                          TECH.HOME, {nounlock = true, build_mode = BUILDMODE.HOME_DECOR, placer = "deco_wallornament_periodic_table_placer",      image = "reno_wallornament_periodic_table.tex"},    {"HOME_WALL_DECORATION"})
AddRecipe2("deco_wallornament_gears_art",         {Ingredient("oinc", 8)},                          TECH.HOME, {nounlock = true, build_mode = BUILDMODE.HOME_DECOR, placer = "deco_wallornament_gears_art_placer",           image = "reno_wallornament_gears_art.tex"},         {"HOME_WALL_DECORATION"})
AddRecipe2("deco_wallornament_cape",              {Ingredient("oinc", 5)},                          TECH.HOME, {nounlock = true, build_mode = BUILDMODE.HOME_DECOR, placer = "deco_wallornament_cape_placer",                image = "reno_wallornament_cape.tex"},              {"HOME_WALL_DECORATION"})
AddRecipe2("deco_wallornament_no_smoking",        {Ingredient("oinc", 3)},                          TECH.HOME, {nounlock = true, build_mode = BUILDMODE.HOME_DECOR, placer = "deco_wallornament_no_smoking_placer",          image = "reno_wallornament_no_smoking.tex"},        {"HOME_WALL_DECORATION"})
AddRecipe2("deco_wallornament_black_cat",         {Ingredient("oinc", 5)},                          TECH.HOME, {nounlock = true, build_mode = BUILDMODE.HOME_DECOR, placer = "deco_wallornament_black_cat_placer",           image = "reno_wallornament_black_cat.tex"},         {"HOME_WALL_DECORATION"})
AddRecipe2("deco_antiquities_wallfish",           {Ingredient("oinc", 2),  Ingredient("fish", 1)},  TECH.HOME, {nounlock = true, build_mode = BUILDMODE.HOME_DECOR, placer = "deco_antiquities_wallfish_placer",             image = "reno_antiquities_wallfish.tex"},           {"HOME_WALL_DECORATION"})
AddRecipe2("deco_antiquities_beefalo",            {Ingredient("oinc", 10), Ingredient("horn", 1)},  TECH.HOME, {nounlock = true, build_mode = BUILDMODE.HOME_DECOR, placer = "deco_antiquities_beefalo_placer",              image = "reno_antiquities_beefalo.tex"},            {"HOME_WALL_DECORATION"})

--AddRecipe2("window_round_curtains_nails",         {Ingredient("boards", 2)},                                     RENO_RECIPETABS.HOME, TECH.HOME, RECIPE_GAME_TYPE.PORKLAND, "window_round_curtains_nails_placer", nil, true, nil, nil, nil, true)
AddRecipe2("window_small_peaked_curtain", {Ingredient("oinc", 3)}, TECH.HOME, {nounlock = true, build_mode = BUILDMODE.HOME_DECOR, placer = "window_small_peaked_curtain_placer",  image = "reno_window_small_peaked_curtain.tex"},    {"HOME_WALL_DECORATION"})
AddRecipe2("window_round_burlap",         {Ingredient("oinc", 3)}, TECH.HOME, {nounlock = true, build_mode = BUILDMODE.HOME_DECOR, placer = "window_round_burlap_placer",          image = "reno_window_round_burlap.tex"},            {"HOME_WALL_DECORATION"})
AddRecipe2("window_small_peaked",         {Ingredient("oinc", 3)}, TECH.HOME, {nounlock = true, build_mode = BUILDMODE.HOME_DECOR, placer = "window_small_peaked_placer",          image = "reno_window_small_peaked.tex"},            {"HOME_WALL_DECORATION"})
AddRecipe2("window_large_square",         {Ingredient("oinc", 4)}, TECH.HOME, {nounlock = true, build_mode = BUILDMODE.HOME_DECOR, placer = "window_large_square_placer",          image = "reno_window_large_square.tex"},            {"HOME_WALL_DECORATION"})
AddRecipe2("window_tall",                 {Ingredient("oinc", 4)}, TECH.HOME, {nounlock = true, build_mode = BUILDMODE.HOME_DECOR, placer = "window_tall_placer",                  image = "reno_window_tall.tex"},                    {"HOME_WALL_DECORATION"})
AddRecipe2("window_large_square_curtain", {Ingredient("oinc", 5)}, TECH.HOME, {nounlock = true, build_mode = BUILDMODE.HOME_DECOR, placer = "window_large_square_curtain_placer",  image = "reno_window_large_square_curtain.tex"},    {"HOME_WALL_DECORATION"})
AddRecipe2("window_tall_curtain",         {Ingredient("oinc", 5)}, TECH.HOME, {nounlock = true, build_mode = BUILDMODE.HOME_DECOR, placer = "window_tall_curtain_placer",          image = "reno_window_tall_curtain.tex"},            {"HOME_WALL_DECORATION"})

AddRecipe2("window_greenhouse",           {Ingredient("oinc", 8)}, TECH.HOME, {nounlock = true, build_mode = BUILDMODE.HOME_DECOR, placer = "window_greenhouse_placer",            image = "reno_window_greenhouse.tex"},              {"HOME_WALL_DECORATION"})

--cassielu: why change them?
AddRecipe2("deco_wood_beam",      {Ingredient("oinc", 1)},  TECH.HOME, {nounlock = true, build_mode = BUILDMODE.HOME_DECOR, placer = "deco_wood_cornerbeam_placer",      image = "reno_cornerbeam_wood.tex",      nameoverride = "deco_wood",      description = "deco_wood"},      {"HOME_COLUMN"})
AddRecipe2("deco_millinery_beam", {Ingredient("oinc", 1)},  TECH.HOME, {nounlock = true, build_mode = BUILDMODE.HOME_DECOR, placer = "deco_millinery_cornerbeam_placer", image = "reno_cornerbeam_millinery.tex", nameoverride = "deco_millinery", description = "deco_millinery"}, {"HOME_COLUMN"})
AddRecipe2("deco_round_beam",     {Ingredient("oinc", 1)},  TECH.HOME, {nounlock = true, build_mode = BUILDMODE.HOME_DECOR, placer = "deco_round_cornerbeam_placer",     image = "reno_cornerbeam_round.tex",     nameoverride = "deco_round",     description = "deco_round"},     {"HOME_COLUMN"})
AddRecipe2("deco_marble_beam",    {Ingredient("oinc", 5)},  TECH.HOME, {nounlock = true, build_mode = BUILDMODE.HOME_DECOR, placer = "deco_marble_cornerbeam_placer",    image = "reno_cornerbeam_marble.tex",    nameoverride = "deco_marble",    description = "deco_marble"},    {"HOME_COLUMN"})

AddRecipe2("interior_floor_wood",        {Ingredient("oinc", 5)},  TECH.HOME, {nounlock = true}, {"HOME_FLOOR"})
AddRecipe2("interior_floor_marble",      {Ingredient("oinc", 15)}, TECH.HOME, {nounlock = true}, {"HOME_FLOOR"})
AddRecipe2("interior_floor_check",       {Ingredient("oinc", 7)},  TECH.HOME, {nounlock = true}, {"HOME_FLOOR"})
AddRecipe2("interior_floor_plaid_tile",  {Ingredient("oinc", 10)}, TECH.HOME, {nounlock = true}, {"HOME_FLOOR"})
AddRecipe2("interior_floor_sheet_metal", {Ingredient("oinc", 6)},  TECH.HOME, {nounlock = true}, {"HOME_FLOOR"})

AddRecipe2("interior_floor_gardenstone",    {Ingredient("oinc", 10)}, TECH.HOME, {nounlock = true}, {"HOME_FLOOR"})
AddRecipe2("interior_floor_geometrictiles", {Ingredient("oinc", 12)}, TECH.HOME, {nounlock = true}, {"HOME_FLOOR"})
AddRecipe2("interior_floor_shag_carpet",    {Ingredient("oinc", 6)},  TECH.HOME, {nounlock = true}, {"HOME_FLOOR"})
AddRecipe2("interior_floor_transitional",   {Ingredient("oinc", 6)},  TECH.HOME, {nounlock = true}, {"HOME_FLOOR"})
AddRecipe2("interior_floor_woodpanels",     {Ingredient("oinc", 10)}, TECH.HOME, {nounlock = true}, {"HOME_FLOOR"})
AddRecipe2("interior_floor_herringbone",    {Ingredient("oinc", 12)}, TECH.HOME, {nounlock = true}, {"HOME_FLOOR"})
AddRecipe2("interior_floor_hexagon",        {Ingredient("oinc", 12)}, TECH.HOME, {nounlock = true}, {"HOME_FLOOR"})
AddRecipe2("interior_floor_hoof_curvy",     {Ingredient("oinc", 12)}, TECH.HOME, {nounlock = true}, {"HOME_FLOOR"})
AddRecipe2("interior_floor_octagon",        {Ingredient("oinc", 12)}, TECH.HOME, {nounlock = true}, {"HOME_FLOOR"})

AddRecipe2("interior_wall_wood",      {Ingredient("oinc", 1)},  TECH.HOME, {nounlock = true}, {"HOME_WALLPAPER"})
AddRecipe2("interior_wall_checkered", {Ingredient("oinc", 6)},  TECH.HOME, {nounlock = true}, {"HOME_WALLPAPER"})
AddRecipe2("interior_wall_floral",    {Ingredient("oinc", 6)},  TECH.HOME, {nounlock = true}, {"HOME_WALLPAPER"})
AddRecipe2("interior_wall_sunflower", {Ingredient("oinc", 6)},  TECH.HOME, {nounlock = true}, {"HOME_WALLPAPER"})
AddRecipe2("interior_wall_harlequin", {Ingredient("oinc", 10)}, TECH.HOME, {nounlock = true}, {"HOME_WALLPAPER"})

AddRecipe2("interior_wall_peagawk",           {Ingredient("oinc", 6)},  TECH.HOME, {nounlock = true}, {"HOME_WALLPAPER"})
AddRecipe2("interior_wall_plain_ds",          {Ingredient("oinc", 4)},  TECH.HOME, {nounlock = true}, {"HOME_WALLPAPER"})
AddRecipe2("interior_wall_plain_rog",         {Ingredient("oinc", 4)},  TECH.HOME, {nounlock = true}, {"HOME_WALLPAPER"})
AddRecipe2("interior_wall_rope",              {Ingredient("oinc", 6)},  TECH.HOME, {nounlock = true}, {"HOME_WALLPAPER"})
AddRecipe2("interior_wall_circles",           {Ingredient("oinc", 10)}, TECH.HOME, {nounlock = true}, {"HOME_WALLPAPER"})
AddRecipe2("interior_wall_marble",            {Ingredient("oinc", 15)}, TECH.HOME, {nounlock = true}, {"HOME_WALLPAPER"})
AddRecipe2("interior_wall_mayorsoffice",      {Ingredient("oinc", 15)}, TECH.HOME, {nounlock = true}, {"HOME_WALLPAPER"})
AddRecipe2("interior_wall_fullwall_moulding", {Ingredient("oinc", 15)}, TECH.HOME, {nounlock = true}, {"HOME_WALLPAPER"})
AddRecipe2("interior_wall_upholstered",       {Ingredient("oinc", 8)},  TECH.HOME, {nounlock = true}, {"HOME_WALLPAPER"})

AddRecipe2("swinging_light_basic_bulb",         {Ingredient("oinc", 5)},  TECH.HOME, {nounlock = true, build_mode = BUILDMODE.HOME_DECOR, placer = "swinging_light_basic_bulb_placer",         image = "reno_light_basic_bulb.tex"},         {"HOME_HANGINGLAMP"})
AddRecipe2("swinging_light_basic_metal",        {Ingredient("oinc", 6)},  TECH.HOME, {nounlock = true, build_mode = BUILDMODE.HOME_DECOR, placer = "swinging_light_basic_metal_placer",        image = "reno_light_basic_metal.tex"},        {"HOME_HANGINGLAMP"})
AddRecipe2("swinging_light_chandalier_candles", {Ingredient("oinc", 8)},  TECH.HOME, {nounlock = true, build_mode = BUILDMODE.HOME_DECOR, placer = "swinging_light_chandalier_candles_placer", image = "reno_light_chandalier_candles.tex"}, {"HOME_HANGINGLAMP"})
AddRecipe2("swinging_light_rope_1",             {Ingredient("oinc", 1)},  TECH.HOME, {nounlock = true, build_mode = BUILDMODE.HOME_DECOR, placer = "swinging_light_rope_1_placer",             image = "reno_light_rope_1.tex"},             {"HOME_HANGINGLAMP"})
AddRecipe2("swinging_light_rope_2",             {Ingredient("oinc", 1)},  TECH.HOME, {nounlock = true, build_mode = BUILDMODE.HOME_DECOR, placer = "swinging_light_rope_2_placer",             image = "reno_light_rope_2.tex"},             {"HOME_HANGINGLAMP"})
AddRecipe2("swinging_light_floral_bulb",        {Ingredient("oinc", 10)}, TECH.HOME, {nounlock = true, build_mode = BUILDMODE.HOME_DECOR, placer = "swinging_light_floral_bulb_placer",        image = "reno_light_floral_bulb.tex"},        {"HOME_HANGINGLAMP"})
AddRecipe2("swinging_light_pendant_cherries",   {Ingredient("oinc", 12)}, TECH.HOME, {nounlock = true, build_mode = BUILDMODE.HOME_DECOR, placer = "swinging_light_pendant_cherries_placer",   image = "reno_light_pendant_cherries.tex"},   {"HOME_HANGINGLAMP"})
AddRecipe2("swinging_light_floral_scallop",     {Ingredient("oinc", 12)}, TECH.HOME, {nounlock = true, build_mode = BUILDMODE.HOME_DECOR, placer = "swinging_light_floral_scallop_placer",     image = "reno_light_floral_scallop.tex"},     {"HOME_HANGINGLAMP"})
AddRecipe2("swinging_light_floral_bloomer",     {Ingredient("oinc", 12)}, TECH.HOME, {nounlock = true, build_mode = BUILDMODE.HOME_DECOR, placer = "swinging_light_floral_bloomer_placer",     image = "reno_light_floral_bloomer.tex"},     {"HOME_HANGINGLAMP"})
AddRecipe2("swinging_light_tophat",             {Ingredient("oinc", 12)}, TECH.HOME, {nounlock = true, build_mode = BUILDMODE.HOME_DECOR, placer = "swinging_light_tophat_placer",             image = "reno_light_tophat.tex"},             {"HOME_HANGINGLAMP"})
AddRecipe2("swinging_light_derby",              {Ingredient("oinc", 12)}, TECH.HOME, {nounlock = true, build_mode = BUILDMODE.HOME_DECOR, placer = "swinging_light_derby_placer",              image = "reno_light_derby.tex"},              {"HOME_HANGINGLAMP"})

-- DOORS
local function GetDoorDirection(pt)
    local center = TheWorld.components.interiorspawner:GetInteriorCenter(pt)
    local origin = center:GetPosition()
    local delta = pt - origin
    if math.abs(delta.x) > math.abs(delta.z) then
        -- north or south
        if delta.x > 0 then
            return "south"
        else
            return "north"
        end
    else
        -- east or west
        if delta.z < 0 then
            return "west"
        else
            return "east"
        end
    end
end

-- Check if the door is facing the initial room's exit
local function CanBuildHouseDoor(recipe, builder, pt)
    local interior_spawner = TheWorld.components.interiorspawner
    if not interior_spawner:IsInInteriorRegion(pt.x, pt.z) then
        return false
    end
    local room_id = interior_spawner:PositionToIndex(pt)
    local house_id = interior_spawner:GetPlayerHouseByRoomId(room_id)
    if not house_id then
        return false
    end
    -- Just test if it's pointing north and that room is the origin room for now
    if GetDoorDirection(pt) == "north" then
        local id = interior_spawner:GetPlayerRoomInDirection(house_id, room_id, interior_spawner:GetNorth())
        local x, y = interior_spawner:GetPlayerRoomIndexById(house_id, id)
        return not (x == 0 and y == 0)
    end
    return true
end

AddRecipe2("wood_door",     {Ingredient("oinc", 10)}, TECH.HOME, {nounlock = true, build_mode = BUILDMODE.HOME_DECOR, canbuild = CanBuildHouseDoor, placer = "wood_door_placer",    image = "wood_door.tex"},    {"HOME_DOOR"})
AddRecipe2("stone_door",    {Ingredient("oinc", 10)}, TECH.HOME, {nounlock = true, build_mode = BUILDMODE.HOME_DECOR, canbuild = CanBuildHouseDoor, placer = "stone_door_placer",   image = "stone_door.tex"},   {"HOME_DOOR"})
AddRecipe2("organic_door",  {Ingredient("oinc", 15)}, TECH.HOME, {nounlock = true, build_mode = BUILDMODE.HOME_DECOR, canbuild = CanBuildHouseDoor, placer = "organic_door_placer", image = "organic_door.tex"}, {"HOME_DOOR"})
AddRecipe2("iron_door",     {Ingredient("oinc", 15)}, TECH.HOME, {nounlock = true, build_mode = BUILDMODE.HOME_DECOR, canbuild = CanBuildHouseDoor, placer = "iron_door_placer",    image = "iron_door.tex"},    {"HOME_DOOR"})
AddRecipe2("curtain_door",  {Ingredient("oinc", 15)}, TECH.HOME, {nounlock = true, build_mode = BUILDMODE.HOME_DECOR, canbuild = CanBuildHouseDoor, placer = "curtain_door_placer", image = "curtain_door.tex"}, {"HOME_DOOR"})
AddRecipe2("plate_door",    {Ingredient("oinc", 15)}, TECH.HOME, {nounlock = true, build_mode = BUILDMODE.HOME_DECOR, canbuild = CanBuildHouseDoor, placer = "plate_door_placer",   image = "plate_door.tex"},   {"HOME_DOOR"})
AddRecipe2("round_door",    {Ingredient("oinc", 20)}, TECH.HOME, {nounlock = true, build_mode = BUILDMODE.HOME_DECOR, canbuild = CanBuildHouseDoor, placer = "round_door_placer",   image = "round_door.tex"},   {"HOME_DOOR"})
AddRecipe2("pillar_door",   {Ingredient("oinc", 20)}, TECH.HOME, {nounlock = true, build_mode = BUILDMODE.HOME_DECOR, canbuild = CanBuildHouseDoor, placer = "pillar_door_placer",  image = "pillar_door.tex"},  {"HOME_DOOR"})

AddRecipe2("construction_permit", {Ingredient("oinc", 50)}, TECH.HOME, {nounlock = true}, {"HOME_DOOR"})
AddRecipe2("demolition_permit",   {Ingredient("oinc", 10)}, TECH.HOME, {nounlock = true}, {"HOME_DOOR"})

-- Deconstruct ---
AddDeconstructRecipe("pig_guard_tower_palace", {Ingredient("cutstone", 3), Ingredient("halberd", 2), Ingredient("pigskin", 4)})
AddDeconstructRecipe("pig_shop_academy", {Ingredient("boards", 4), Ingredient("relic_1", 1), Ingredient("relic_2", 1), Ingredient("pigskin", 4)})
AddDeconstructRecipe("pighouse_farm", {Ingredient("cutstone", 3), Ingredient("pitchfork", 1), Ingredient("seeds", 6), Ingredient("pigskin", 4)})
AddDeconstructRecipe("pighouse_mine", {Ingredient("cutstone", 3), Ingredient("pickaxe", 2), Ingredient("pigskin", 4)})
AddDeconstructRecipe("mandrakehouse", {Ingredient("boards", 3), Ingredient("mandrake", 2), Ingredient("cutgrass", 10)})

AddDeconstructRecipe("topiary_1", {Ingredient("oinc", 20)})
AddDeconstructRecipe("topiary_2", {Ingredient("oinc", 20)})
AddDeconstructRecipe("topiary_3", {Ingredient("oinc", 20)})
AddDeconstructRecipe("topiary_4", {Ingredient("oinc", 20)})
