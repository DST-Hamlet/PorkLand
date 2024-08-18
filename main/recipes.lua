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

local TechTree = require("techtree")
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

AddTech("CITY", false)

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

AddRecipeFilter({
    name = "CITY",
    atlas = "images/hud/pl_crafting_menu_icons.xml",
    image = "filter_city.tex",
}, #CRAFTING_FILTER_DEFS)

--- ARCHAEOLOGY ---
AddRecipe2("disarming_kit", {Ingredient("iron", 2), Ingredient("cutreeds", 2)}, TECH.NONE, {}, {"ARCHAEOLOGY"})
AddRecipe2("ballpein_hammer", {Ingredient("iron", 2), Ingredient("twigs", 1)}, TECH.SCIENCE_ONE, {}, {"ARCHAEOLOGY"})
AddRecipe2("goldpan", {Ingredient("iron", 2), Ingredient("hammer", 1)}, TECH.SCIENCE_ONE, {}, {"ARCHAEOLOGY"})
AddRecipe2("magnifying_glass", {Ingredient("iron", 1), Ingredient("twigs", 1), Ingredient("bluegem", 1)}, TECH.SCIENCE_TWO, {}, {"ARCHAEOLOGY"})

-- SCIENCE ---
AddRecipe2("smelter", {Ingredient("cutstone", 6), Ingredient("boards", 4), Ingredient("redgem", 1)}, TECH.SCIENCE_TWO, {placer = "smelter_placer"}, {"TOOLS","STRUCTURES"})
SortBefore("smelter", "cookpot", "STRUCTURES")
SortAfter("smelter", "archive_resonator_item", "TOOLS")

AddRecipe2("basefan", {Ingredient("alloy", 2), Ingredient("transistor", 2), Ingredient("gears", 1)}, TECH.SCIENCE_TWO, {placer = "basefan_placer"}, {"STRUCTURES", "RAIN", "ENVIRONMENT_PROTECTION"})
SortBefore("basefan", "firesuppressor", "STRUCTURES")
SortBefore("basefan", "rainometer", "RAIN")

-- TOOLS ---
AddRecipe2("bugrepellent", {Ingredient("tuber_crop", 6), Ingredient("venus_stalk", 1)}, TECH.SCIENCE_ONE, {}, {"TOOLS", "ENVIRONMENT_PROTECTION"})
SortAfter("bugrepellent", nil, "TOOLS")

AddRecipe2("machete", {Ingredient("twigs", 1),Ingredient("flint", 3)}, TECH.SCIENCE_ONE, {}, {"TOOLS"})
SortAfter("machete", "axe", "TOOLS")

AddRecipe2("goldenmachete", {Ingredient("twigs", 4),Ingredient("goldnugget", 2)}, TECH.SCIENCE_ONE, {}, {"TOOLS"})
SortAfter("goldenmachete", "goldenaxe", "TOOLS")

AddRecipe2("shears", {Ingredient("twigs", 2),Ingredient("iron", 2)}, TECH.SCIENCE_ONE, {}, {"TOOLS"})
SortAfter("shears", "goldenpitchfork", "TOOLS")

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
AddRecipe2("hogusporkusator", {Ingredient("pigskin", 4), Ingredient("boards", 4), Ingredient("feather_robin_winter", 4)}, TECH.SCIENCE_ONE, {placer = "hogusporkusator_placer"}, {"MAGIC", "STRUCTURES", "PROTOTYPERS"})
SortAfter("hogusporkusator", "researchlab4", "MAGIC")
SortAfter("hogusporkusator", "researchlab4", "STRUCTURES")
SortAfter("hogusporkusator", "researchlab4", "PROTOTYPERS")

AddRecipe2("bonestaff", {Ingredient("pugalisk_skull", 1), Ingredient("boneshard", 1), Ingredient("nightmarefuel", 2)}, TECH.MAGIC_THREE, {} , {"WEAPONS","MAGIC"})
SortAfter("bonestaff", "antlionhat", "MAGIC")
SortAfter("bonestaff", "trident", "WEAPONS")

-- REFINE ---
AddRecipe2("goldnugget", {Ingredient("gold_dust", 6)}, TECH.SCIENCE_ONE, {no_deconstruction = true} , {"REFINE"})
AddRecipe2("clawpalmtree_sapling_item", {Ingredient("cork", 1), Ingredient("poop", 1)}, TECH.SCIENCE_ONE, {no_deconstruction = true, image = "clawpalmtree_sapling.tex"}, {"REFINE"})
AddRecipe2("venomgland", {Ingredient("froglegs_poison", 3)}, TECH.SCIENCE_TWO, {no_deconstruction = true} , {"REFINE"})

-- DECOR ---
-- AddRecipe2("turf_foundation", {Ingredient("cutstone", 1)}, TECH.CITY, cityRecipeGameTypes, nil, nil, true)
-- AddRecipe2("turf_cobbleroad", {Ingredient("cutstone", 2), Ingredient("boards", 1)}, TECH.CITY, cityRecipeGameTypes, nil, nil, true)
-- AddRecipe2("turf_lawn", {Ingredient("cutgrass", 2), Ingredient("nitre", 1)}, TECH.SCIENCE_TWO)
-- AddRecipe2("turf_fields", {Ingredient("turf_rainforest", 1), Ingredient("ash", 1)}, TECH.SCIENCE_TWO)
-- AddRecipe2("turf_deeprainforest_nocanopy", {Ingredient("bramble_bulb", 1), Ingredient("cutgrass", 2), Ingredient("ash", 1)}, TECH.SCIENCE_TWO)

-- NAUTICAL ---
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

AddRecipe2("sail_snakeskin", {Ingredient("log", 4), Ingredient("rope", 2), Ingredient("snakeskin", 2, nil, nil, "snakeskin_scaly.tex")}, TECH.SCIENCE_TWO, {image = "sail_snakeskin_scaly.tex"}, {"NAUTICAL"})

-- CHARACTER ---

AddRecipe2("disguisehat", {Ingredient("twigs", 2), Ingredient("pigskin", 1), Ingredient("beardhair", 1)}, TECH.NONE, {builder_tag = "spiderwhisperer"}, {"CHARACTER", "CLOTHING"})
SortBefore("disguisehat", "spidereggsack", "CHARACTER")

AddRecipe2("poisonbalm", {Ingredient("livinglog", 1), Ingredient("venomgland", 1)}, TECH.NONE, {builder_tag = "plantkin"}, {"CHARACTER", "RESTORATION"})
SortAfter("poisonbalm", "armor_bramble", "CHARACTER")
SortBefore("poisonbalm", "healingsalve", "RESTORATION")

local function IsValidSprinklerTile(tile)
    return not TileGroupManager:IsOceanTile(tile) and (tile ~= WORLD_TILES.INVALID) and (tile ~= WORLD_TILES.IMPASSABLE)
end

local function GetValidWaterPointNearby(pt)
    local range = 20

    local cx, cy = TheWorld.Map:GetTileCoordsAtPoint(pt.x, 0, pt.z)
    local center_tile = TheWorld.Map:GetTile(cx, cy)

    local min_sq_dist = 999999999999
    local best_point = nil

    for x = pt.x - range, pt.x + range, 1 do
        for z = pt.z - range, pt.z + range, 1 do
            local tx, ty = TheWorld.Map:GetTileCoordsAtPoint(x, 0, z)
            local tile = TheWorld.Map:GetTile(tx, ty)

            if IsValidSprinklerTile(center_tile) and TileGroupManager:IsOceanTile(tile) then
                local cur_point = Vector3(x, 0, z)
                local cur_sq_dist = cur_point:DistSq(pt)

                if cur_sq_dist < min_sq_dist then
                    min_sq_dist = cur_sq_dist
                    best_point = cur_point
                end
            end
        end
    end

    return best_point
end

local function sprinkler_placetest(pt, rot)
    return GetValidWaterPointNearby(pt) ~= nil
end

AddRecipe2("sprinkler", {Ingredient("alloy", 2), Ingredient("bluegem", 1), Ingredient("ice", 6)}, TECH.SCIENCE_TWO, {placer = "sprinkler_placer", testfn = sprinkler_placetest}, {"GARDENING", "STRUCTURES"})

AddRecipe2("corkchest", {Ingredient("cork", 2), Ingredient("rope", 1)}, TECH.SCIENCE_ONE, {placer="corkchest_placer", min_spacing=1}, {"STRUCTURES", "CONTAINERS"})

AddRecipe2("roottrunk_child", {Ingredient("bramble_bulb", 1), Ingredient("venus_stalk", 2), Ingredient("boards", 3)}, TECH.MAGIC_TWO, {placer="roottrunk_child_placer", min_spacing=2}, {"STRUCTURES", "CONTAINERS", "MAGIC"})

local function NotInInterior(pt)
    return not TheWorld.components.interiorspawner:IsInInterior(pt.x, pt.z)
end

--- CITY ---
AddRecipe2("turf_foundation", {Ingredient("cutstone", 1)}, TECH.CITY, {nounlock = true}, {"CITY"})
AddRecipe2("turf_cobbleroad", {Ingredient("cutstone", 2), Ingredient("boards", 1)}, TECH.CITY, {nounlock = true}, {"CITY"})
AddRecipe2("city_lamp", {Ingredient("alloy", 1), Ingredient("transistor", 1),Ingredient("lantern",1)},  TECH.CITY, {nounlock = true, placer = "city_lamp_placer"}, {"CITY"})

AddRecipe2("pighouse_city", {Ingredient("boards", 4), Ingredient("cutstone", 3), Ingredient("pigskin", 4)}, TECH.CITY, {nounlock = true, placer = "pighouse_city_placer", testfn = NotInInterior}, {"CITY"})

AddRecipe2("pig_shop_deli", {Ingredient("boards", 4), Ingredient("honeyham", 1), Ingredient("pigskin", 4)}, TECH.CITY, {nounlock = true, placer = "pig_shop_deli_placer", testfn = NotInInterior}, {"CITY"})
AddRecipe2("pig_shop_general", {Ingredient("boards", 4), Ingredient("axe", 3), Ingredient("pigskin", 4)}, TECH.CITY, {nounlock = true, placer = "pig_shop_general_placer", testfn = NotInInterior}, {"CITY"})

AddRecipe2("pig_shop_hoofspa", {Ingredient("boards", 4), Ingredient("bandage", 3), Ingredient("pigskin", 4)}, TECH.CITY, {nounlock = true, placer = "pig_shop_hoofspa_placer", testfn = NotInInterior}, {"CITY"})
AddRecipe2("pig_shop_produce", {Ingredient("boards", 4), Ingredient("eggplant", 3), Ingredient("pigskin", 4)}, TECH.CITY, {nounlock = true, placer = "pig_shop_produce_placer", testfn = NotInInterior}, {"CITY"})

AddRecipe2("pig_shop_florist", {Ingredient("boards", 4), Ingredient("petals", 12), Ingredient("pigskin", 4)}, TECH.CITY, {nounlock = true, placer = "pig_shop_florist_placer", testfn = NotInInterior}, {"CITY"})
AddRecipe2("pig_shop_antiquities", {Ingredient("boards", 4), Ingredient("ballpein_hammer", 3), Ingredient("pigskin", 4)}, TECH.CITY, {nounlock = true, placer = "pig_shop_antiquities_placer", testfn = NotInInterior}, {"CITY"})

AddRecipe2("pig_shop_arcane", {Ingredient("boards", 4), Ingredient("nightmarefuel", 1), Ingredient("pigskin", 4)}, TECH.CITY, {nounlock = true, placer = "pig_shop_arcane_placer", testfn = NotInInterior}, {"CITY"})
AddRecipe2("pig_shop_weapons", {Ingredient("boards", 4), Ingredient("spear", 3), Ingredient("pigskin", 4)}, TECH.CITY, {nounlock = true, placer = "pig_shop_weapons_placer", testfn = NotInInterior}, {"CITY"})
AddRecipe2("pig_shop_hatshop", {Ingredient("boards", 4), Ingredient("tophat", 2), Ingredient("pigskin", 4)}, TECH.CITY, {nounlock = true, placer = "pig_shop_hatshop_placer", testfn = NotInInterior}, {"CITY"})
AddRecipe2("pig_shop_bank", {Ingredient("cutstone", 4), Ingredient("oinc", 100), Ingredient("pigskin", 4)}, TECH.CITY, {nounlock = true, placer = "pig_shop_bank_placer", testfn = NotInInterior}, {"CITY"})

AddRecipe2("pig_shop_tinker", {Ingredient("magnifying_glass", 2), Ingredient("pigskin", 4)}, TECH.CITY, {nounlock = true, placer = "pig_shop_tinker_placer", testfn = NotInInterior}, {"CITY"})

AddRecipe2("pig_shop_cityhall_player", {Ingredient("boards", 4), Ingredient("goldnugget", 4), Ingredient("pigskin", 4)}, TECH.CITY, {nounlock = true, placer = "pig_shop_cityhall_placer", testfn = NotInInterior}, {"CITY"})

AddRecipe2("pig_guard_tower", {Ingredient("cutstone", 3), Ingredient("halberd", 1), Ingredient("pigskin", 4)}, TECH.CITY, {nounlock = true, placer = "pig_guard_tower_placer", testfn = NotInInterior}, {"CITY"})

AddRecipe2("securitycontract", {Ingredient("oinc", 10)}, TECH.CITY, {nounlock = true}, {"CITY"})

AddRecipe2("playerhouse_city", {Ingredient("boards", 4), Ingredient("cutstone", 3), Ingredient("oinc", 30)}, TECH.CITY, {nounlock = true, placer = "playerhouse_city_placer", testfn = NotInInterior}, {"CITY"})

AddRecipe2("hedge_block_item", {Ingredient("clippings", 9), Ingredient("nitre", 1)}, TECH.CITY, {nounlock = true, min_spacing = 3}, {"CITY"})
AddRecipe2("hedge_cone_item", {Ingredient("clippings", 9), Ingredient("nitre", 1)}, TECH.CITY, {nounlock = true, min_spacing = 3}, {"CITY"})
AddRecipe2("hedge_layered_item", {Ingredient("clippings", 9), Ingredient("nitre", 1)}, TECH.CITY, {nounlock = true, min_spacing = 3}, {"CITY"})

AddRecipe2("lawnornament_1", {Ingredient("oinc", 10)}, TECH.CITY, {nounlock = true, min_spacing = 1, placer = "lawnornament_1_placer"}, {"CITY"})
AddRecipe2("lawnornament_2", {Ingredient("oinc", 10)}, TECH.CITY, {nounlock = true, min_spacing = 1, placer = "lawnornament_2_placer"}, {"CITY"})
AddRecipe2("lawnornament_3", {Ingredient("oinc", 10)}, TECH.CITY, {nounlock = true, min_spacing = 1, placer = "lawnornament_3_placer"}, {"CITY"})
AddRecipe2("lawnornament_4", {Ingredient("oinc", 10)}, TECH.CITY, {nounlock = true, min_spacing = 1, placer = "lawnornament_4_placer"}, {"CITY"})
AddRecipe2("lawnornament_5", {Ingredient("oinc", 10)}, TECH.CITY, {nounlock = true, min_spacing = 1, placer = "lawnornament_5_placer"}, {"CITY"})
AddRecipe2("lawnornament_6", {Ingredient("oinc", 10)}, TECH.CITY, {nounlock = true, min_spacing = 1, placer = "lawnornament_6_placer"}, {"CITY"})
AddRecipe2("lawnornament_7", {Ingredient("oinc", 10)}, TECH.CITY, {nounlock = true, min_spacing = 1, placer = "lawnornament_7_placer"}, {"CITY"})

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
