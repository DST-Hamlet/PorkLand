-- This file loads all static layouts and contains all non-static layouts
local StaticLayout = require("map/static_layout")
local AllLayouts = require("map/layouts").Layouts

local ground_types = {
    -- Translates tile type index from constants.lua into tiled tileset.
    -- Order they appear here is the order they will be used in tiled.
    WORLD_TILES.IMPASSABLE, WORLD_TILES.ROAD, WORLD_TILES.ROCKY, WORLD_TILES.DIRT,
    WORLD_TILES.SAVANNA, WORLD_TILES.GRASS, WORLD_TILES.FOREST, WORLD_TILES.MARSH,

    WORLD_TILES.WOODFLOOR, WORLD_TILES.CARPET, WORLD_TILES.CHECKER,WORLD_TILES.CAVE,
    WORLD_TILES.FUNGUS, WORLD_TILES.SINKHOLE, WORLD_TILES.WALL_ROCKY, WORLD_TILES.WALL_DIRT,

    WORLD_TILES.WALL_MARSH, WORLD_TILES.WALL_CAVE, WORLD_TILES.WALL_FUNGUS, WORLD_TILES.WALL_SINKHOLE,
    WORLD_TILES.UNDERROCK, WORLD_TILES.MUD, WORLD_TILES.WALL_MUD, WORLD_TILES.WALL_WOOD,

    WORLD_TILES.BRICK, WORLD_TILES.BRICK_GLOW, WORLD_TILES.TILES, WORLD_TILES.TILES_GLOW,
    WORLD_TILES.TRIM, WORLD_TILES.TRIM_GLOW, WORLD_TILES.WALL_HUNESTONE, WORLD_TILES.WALL_HUNESTONE_GLOW,

    WORLD_TILES.WALL_STONEEYE, WORLD_TILES.WALL_STONEEYE_GLOW, WORLD_TILES.FUNGUSRED, WORLD_TILES.FUNGUSGREEN,
    WORLD_TILES.BEACH, WORLD_TILES.JUNGLE, WORLD_TILES.SWAMP, WORLD_TILES.OCEAN_SHALLOW,

    WORLD_TILES.OCEAN_MEDIUM, WORLD_TILES.OCEAN_DEEP, WORLD_TILES.OCEAN_CORAL, WORLD_TILES.MANGROVE,
    WORLD_TILES.MAGMAFIELD, WORLD_TILES.TIDALMARSH, WORLD_TILES.MEADOW, WORLD_TILES.VOLCANO,

    WORLD_TILES.VOLCANO_LAVA, WORLD_TILES.ASH, WORLD_TILES.VOLCANO_ROCK, WORLD_TILES.OCEAN_SHIPGRAVEYARD,
    WORLD_TILES.COBBLEROAD, WORLD_TILES.FOUNDATION, WORLD_TILES.DEEPRAINFOREST, WORLD_TILES.LAWN,

    WORLD_TILES.PIGRUINS, WORLD_TILES.LILYPOND, WORLD_TILES.GASJUNGLE, WORLD_TILES.SUBURB,
    WORLD_TILES.RAINFOREST, WORLD_TILES.PIGRUINS_NOCANOPY, WORLD_TILES.PLAINS, WORLD_TILES.PAINTED,

    WORLD_TILES.BATTLEGROUND, WORLD_TILES.INTERIOR, WORLD_TILES.FIELDS
}

local function LilypadResource()
    return math.random() < 0.5 and {"frog_poison_lilypad"} or {"mosquito_lilypad"}
end

AllLayouts["lilypad"] = StaticLayout.Get("map/static_layouts/lilypad", {
    water = true,
    areas = {
        resource_area = LilypadResource
    }
})
AllLayouts["lilypad"].ground_types = ground_types

AllLayouts["lilypad2"] = StaticLayout.Get("map/static_layouts/lilypad_2", {
    water = true,
    areas = {
        resource_area = LilypadResource,
        resource_area2 = LilypadResource
    }
})
AllLayouts["lilypad2"].ground_types = ground_types

AllLayouts["PigRuinsHead"] = StaticLayout.Get("map/static_layouts/pig_ruins_head", {
    areas = {
        item1 = {"pig_ruins_head"},
        item2 = function()
            local list = {"smashingpot", "grass", "pig_ruins_torch"}
            for i = #list, 1, -1 do
                if math.random() < 0.7 then
                    table.remove(list, i)
                end
            end
            return list
        end
    }
})
AllLayouts["PigRuinsHead"].ground_types = ground_types

local function GetRandomSmashingpot()
    return math.random() < 0.7 and {"smashingpot"} or nil
end

local function GetSmashingpot()
    return math.random() < 1 and {"smashingpot"} or nil
end

AllLayouts["PigRuinsArtichoke"] = StaticLayout.Get("map/static_layouts/pig_ruins_artichoke", {
    areas = {
        item1 = GetRandomSmashingpot,
        item2 = {"pig_ruins_artichoke"}
    }
})
AllLayouts["PigRuinsArtichoke"].ground_types = ground_types

local PigRuinsEntranceProps = {
    areas = {
        item1 = GetSmashingpot,
        item2 = GetSmashingpot,
        item3 = GetSmashingpot
    }
}

AllLayouts["PigRuinsEntrance1"] = StaticLayout.Get("map/static_layouts/pig_ruins_entrance_1", PigRuinsEntranceProps)
AllLayouts["PigRuinsEntrance1"].ground_types = ground_types

AllLayouts["PigRuinsEntrance2"] = StaticLayout.Get("map/static_layouts/pig_ruins_entrance_2")
AllLayouts["PigRuinsEntrance2"].ground_types = ground_types

AllLayouts["PigRuinsEntrance3"] = StaticLayout.Get("map/static_layouts/pig_ruins_entrance_3")
AllLayouts["PigRuinsEntrance3"].ground_types = ground_types

AllLayouts["PigRuinsEntrance4"] = StaticLayout.Get("map/static_layouts/pig_ruins_entrance_4", PigRuinsEntranceProps)
AllLayouts["PigRuinsEntrance4"].ground_types = ground_types

AllLayouts["PigRuinsEntrance5"] = StaticLayout.Get("map/static_layouts/pig_ruins_entrance_5", PigRuinsEntranceProps)
AllLayouts["PigRuinsEntrance5"].ground_types = ground_types

AllLayouts["PigRuinsExit1"] = StaticLayout.Get("map/static_layouts/pig_ruins_exit_1")
AllLayouts["PigRuinsExit1"].ground_types = ground_types

local PigRuinsExitProps = {
    areas = {
        item1 = GetRandomSmashingpot,
        item2 = GetRandomSmashingpot,
        item3 = GetRandomSmashingpot
    }
}

AllLayouts["PigRuinsExit2"] = StaticLayout.Get("map/static_layouts/pig_ruins_exit_2", PigRuinsExitProps)
AllLayouts["PigRuinsExit2"].ground_types = ground_types

AllLayouts["PigRuinsExit4"] = StaticLayout.Get("map/static_layouts/pig_ruins_exit_4", PigRuinsExitProps)
AllLayouts["PigRuinsExit4"].ground_types = ground_types

AllLayouts["pig_ruins_nocanopy"] = StaticLayout.Get("map/static_layouts/pig_ruins_nocanopy")
AllLayouts["pig_ruins_nocanopy"].ground_types = ground_types

AllLayouts["pig_ruins_nocanopy_2"] = StaticLayout.Get("map/static_layouts/pig_ruins_nocanopy_2")
AllLayouts["pig_ruins_nocanopy_2"].ground_types = ground_types

AllLayouts["pig_ruins_nocanopy_3"] = StaticLayout.Get("map/static_layouts/pig_ruins_nocanopy_3")
AllLayouts["pig_ruins_nocanopy_3"].ground_types = ground_types

AllLayouts["pig_ruins_nocanopy_4"] = StaticLayout.Get("map/static_layouts/pig_ruins_nocanopy_4")
AllLayouts["pig_ruins_nocanopy_4"].ground_types = ground_types

AllLayouts["mandraketown"] = StaticLayout.Get("map/static_layouts/mandraketown")
AllLayouts["mandraketown"].ground_types = ground_types

AllLayouts["nettlegrove"] = StaticLayout.Get("map/static_layouts/nettlegrove")
AllLayouts["nettlegrove"].ground_types = ground_types

AllLayouts["fountain_of_youth"] = StaticLayout.Get("map/static_layouts/pugalisk_fountain")
AllLayouts["fountain_of_youth"].ground_types = ground_types

AllLayouts["roc_nest"] = StaticLayout.Get("map/static_layouts/roc_nest")
AllLayouts["roc_nest"].ground_types = ground_types

AllLayouts["roc_cave"] = StaticLayout.Get("map/static_layouts/roc_cave")
AllLayouts["roc_cave"].ground_types = ground_types

AllLayouts["teleportato_hamlet_potato_layout"] = StaticLayout.Get("map/static_layouts/teleportato_hamlet_potato_layout")
AllLayouts["teleportato_hamlet_potato_layout"].ground_types = ground_types

AllLayouts["city_park_1"] = StaticLayout.Get("map/static_layouts/city_park_1")
AllLayouts["city_park_1"].ground_types = ground_types

AllLayouts["city_park_2"] = StaticLayout.Get("map/static_layouts/city_park_2")
AllLayouts["city_park_2"].ground_types = ground_types

AllLayouts["city_park_3"] = StaticLayout.Get("map/static_layouts/city_park_3")
AllLayouts["city_park_3"].ground_types = ground_types

AllLayouts["city_park_4"] = StaticLayout.Get("map/static_layouts/city_park_4")
AllLayouts["city_park_4"].ground_types = ground_types

AllLayouts["city_park_5"] = StaticLayout.Get("map/static_layouts/city_park_5")
AllLayouts["city_park_5"].ground_types = ground_types

AllLayouts["city_park_6"] = StaticLayout.Get("map/static_layouts/city_park_6")
AllLayouts["city_park_6"].ground_types = ground_types

AllLayouts["city_park_7"] = StaticLayout.Get("map/static_layouts/city_park_7")
AllLayouts["city_park_7"].ground_types = ground_types

AllLayouts["city_park_8"] = StaticLayout.Get("map/static_layouts/city_park_8")
AllLayouts["city_park_8"].ground_types = ground_types

AllLayouts["city_park_9"] = StaticLayout.Get("map/static_layouts/city_park_9")
AllLayouts["city_park_9"].ground_types = ground_types

AllLayouts["city_park_10"] = StaticLayout.Get("map/static_layouts/city_park_10")
AllLayouts["city_park_10"].ground_types = ground_types

AllLayouts["farm_1"] = StaticLayout.Get("map/static_layouts/farm_1")
AllLayouts["farm_1"].ground_types = ground_types

AllLayouts["farm_2"] = StaticLayout.Get("map/static_layouts/farm_2")
AllLayouts["farm_2"].ground_types = ground_types

AllLayouts["farm_3"] = StaticLayout.Get("map/static_layouts/farm_3")
AllLayouts["farm_3"].ground_types = ground_types

AllLayouts["farm_4"] = StaticLayout.Get("map/static_layouts/farm_4")
AllLayouts["farm_4"].ground_types = ground_types

AllLayouts["farm_5"] = StaticLayout.Get("map/static_layouts/farm_5")
AllLayouts["farm_5"].ground_types = ground_types

AllLayouts["farm_fill_1"] = StaticLayout.Get("map/static_layouts/farm_fill_1")
AllLayouts["farm_fill_1"].ground_types = ground_types

AllLayouts["farm_fill_2"] = StaticLayout.Get("map/static_layouts/farm_fill_2")
AllLayouts["farm_fill_2"].ground_types = ground_types

AllLayouts["farm_fill_3"] = StaticLayout.Get("map/static_layouts/farm_fill_3")
AllLayouts["farm_fill_3"].ground_types = ground_types

AllLayouts["pig_playerhouse_1"] = StaticLayout.Get("map/static_layouts/pig_playerhouse_1")
AllLayouts["pig_playerhouse_1"].ground_types = ground_types

AllLayouts["pig_palace_1"] = StaticLayout.Get("map/static_layouts/pig_palace_1")
AllLayouts["pig_palace_1"].ground_types = ground_types

AllLayouts["pig_cityhall_1"] = StaticLayout.Get("map/static_layouts/pig_cityhall_1")
AllLayouts["pig_cityhall_1"].ground_types = ground_types
