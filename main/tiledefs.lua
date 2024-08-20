--[[
-- https://forums.kleientertainment.com/forums/topic/140904-tiles-changes-and-more/
tile_name - the name of the tile, this is how you'll refer to your tile in the WORLD_TILES table.
tile_range - the string defining the range of possible ids for the tile.
the following ranges exist: "LAND", "NOISE", "OCEAN", "IMPASSABLE"
tile_data {
    [ground_name]
    [old_static_id] - optional, the static tile id that this tile had before migrating to this API, if you aren't migrating your tiles from an old API to this one, omit this.
}
ground_tile_def {
    [name] - this is the texture for the ground, it will first attempt to load the texture at "levels/texture/<name>.tex", if that fails it will then treat <name> as the whole file path for the texture.
    [atlas] - optional, if missing it will load the same path as name, but ending in .xml instead of .tex,  otherwise behaves the same as <name> but with .xml instead of .tex.
    [noise_texture] -  this is the noise texture for the ground, it will first attempt to load the texture at "levels/texture/<noise_texture>.tex", if that fails it will then treat <noise_texture> as the whole file path for the texture.
    [runsound] - soundpath for the run sound, if omitted will default to "dontstarve/movement/run_dirt"
    [walksound] - soundpath for the walk sound, if omitted will default to "dontstarve/movement/walk_dirt"
    [snowsound] - soundpath for the snow sound, if omitted will default to "dontstarve/movement/run_snow"
    [mudsound] - soundpath for the mud sound, if omitted will default to "dontstarve/movement/run_mud"
    [flashpoint_modifier] - the flashpoint modifier for the tile, defaults to 0 if missing
    [colors] - the colors of the tile when for blending of the ocean colours, will use DEFAULT_COLOUR(see tilemanager.lua for the exact values of this table) if missing.
    [flooring] - if true, inserts this tile into the GROUND_FLOORING table.
    [hard] - if true, inserts this tile into the GROUND_HARD table.
    [cannotbedug] - if true, inserts this tile into the TERRAFORM_IMMUNE table.
    other values can also be stored in this table, and can tested for via the GetTileInfo function.
}
minimap_tile_def {
    [name] - this is the texture for the minimap, it will first attempt to load the texture at "levels/texture/<name>.tex", if that fails it will then treat <name> as the whole file path for the texture.
    [atlas] - optional, if missing it will load the same path as name, but ending in .xml instead of .tex,  otherwise behaves the same as <name> but with .xml instead of .tex.
    [noise_texture] -  this is the noise texture for the minimap, it will first attempt to load the texture at "levels/texture/<noise_texture>.tex", if that fails it will then treat <noise_texture> as the whole file path for the texture.
}
turf_def {
    [name] - the postfix for the prefabname of the turf item
    [anim] - the name of the animation to play for the turf item, if undefined it will use name instead
    [bank_build] - the bank and build containing the animation, if undefined bank_build will use the value "turf"
}
-]]

local GroundTiles = require("worldtiledefs")
local NoiseFunctions = require("noisetilefunctions")
local ChangeTileRenderOrder = ChangeTileRenderOrder
local AddTile = AddTile
GLOBAL.setfenv(1, GLOBAL)

local is_worldgen = rawget(_G, "WORLDGEN_MAIN") ~= nil
if not is_worldgen then
    TileGroups.PlOceanTiles = TileGroupManager:AddTileGroup()
end

PL_OCEAN_TILES = {}
PL_LAND_TILES = {}

local TileRanges =
{
    LAND = "LAND",
    NOISE = "NOISE",
    OCEAN = "OCEAN",
    IMPASSABLE = "IMPASSABLE",
}

local pl_tiledefs = {
    -- dst had this
    -- BEARDRUG = {
    --     tile_range = TileRanges.LAND,
    --     tile_data = {
    --         ground_name = "Beard Rug",
    --         -- old_static_id = 33,
    --     },
    --     ground_tile_def  = {
    --         name = "carpet",
    --         noise_texture = "Ground_beard_hair",
    --         runsound = "dontstarve/movement/run_carpet",
    --         walksound = "dontstarve/movement/walk_carpet",
    --         flashpoint_modifier = 0,
    --     },
    --     minimap_tile_def = {
    --         name = "map_edge",
    --         noise_texture = "interior",
    --     },
    --     --turf_def = {
    --     --    name = "beach",
    --     --    bank_build = "turf_ia",
    --     --},
    -- },
    RAINFOREST = {
        tile_range = TileRanges.LAND,
        tile_data = {
            ground_name = "Rain Forest",
            -- old_static_id = 33,
        },
        ground_tile_def = {
            name = "rain_forest",
            noise_texture = "Ground_noise_rainforest",
            runsound = "dontstarve/movement/run_woods",
            walksound = "dontstarve/movement/walk_woods",
            floor = true,
        },
        minimap_tile_def = {
            name = "map_edge",
            noise_texture = "mini_noise_rainforest",
        },
        turf_def = {
           name = "rainforest",
           anim = "rainforest",
           bank_build = "turf_1",
        },
    },
    DEEPRAINFOREST = {
        tile_range = TileRanges.LAND,
        tile_data = {
            ground_name = "Jungle Deep",
            -- old_static_id = 92,
        },
        ground_tile_def  = {
            name = "jungle_deep",
            noise_texture = "Ground_noise_jungle_deep",
            runsound = "dontstarve/movement/run_woods",
            walksound = "dontstarve/movement/walk_woods",
            cannotbedug = true,
        },
        minimap_tile_def = {
            name = "map_edge",
            noise_texture = "mini_noise_jungle_deep",
        },
        -- turf_def = {
        --     name = "jungle",
        --     bank_build = "turf_ia",
        -- },
    },
    DEEPRAINFOREST_NOCANOPY = {
        tile_range = TileRanges.LAND,
        tile_data = {
            ground_name = "Jungle Deep",
        },
        ground_tile_def  = {
            name = "jungle_deep",
            noise_texture = "Ground_noise_jungle_deep_nocanopy",
            runsound = "dontstarve/movement/run_woods",
            walksound = "dontstarve/movement/walk_woods",
        },
        minimap_tile_def = {
            name = "map_edge",
            noise_texture = "mini_noise_jungle_deep_nocanopy",
        },
        turf_def = {
            name = "deeprainforest_nocanopy",
            anim = "deepjungle",
            bank_build = "turf_1",
        },
    },
    GASJUNGLE = { --note this majestic creature is unused
        tile_range = TileRanges.LAND,
        tile_data = {
            ground_name = "Gas Jungle",
            -- old_static_id = 93,
        },
        ground_tile_def = {
            name = "jungle_deep",
            noise_texture = "ground_noise_gas",
            runsound = "dontstarve/movement/run_moss",
            walksound = "dontstarve/movement/walk_moss",
            cannotbedug = true,
        },
        minimap_tile_def = {
            name = "map_edge",
            noise_texture = "mini_gasbiome_noise",
        },
        -- turf_def = {
        --     name = "swamp",
        --     bank_build = "turf_ia",
        -- },
    },
    PLAINS = {
        tile_range = TileRanges.LAND,
        tile_data = {
            ground_name = "Plains",
            -- old_static_id = 91,
        },
        ground_tile_def = {
            name = "jungle",
            noise_texture = "Ground_plains",
            runsound = "dontstarve/movement/run_tallgrass",
            walksound = "dontstarve/movement/walk_tallgrass",
        },
        minimap_tile_def = {
            name = "map_edge",
            noise_texture = "mini_plains_noise",
        },
        turf_def = {
            name = "plains",
            anim = "plains",
            bank_build = "turf_1",
        },
    },
    PAINTED = {
        tile_range = TileRanges.LAND,
        tile_data = {
            ground_name = "Painted",
            -- old_static_id = 91,
        },
        ground_tile_def = {
            name = "swamp",
            noise_texture = "Ground_bog",
            runsound = "dontstarve/movement/run_sand",
            walksound = "dontstarve/movement/walk_sand",
            mudsound = "run_sand"
        },
        minimap_tile_def = {
            name = "map_edge",
            noise_texture = "mini_bog_noise",
        },
        turf_def = {
            name = "painted",
            anim = "bog",
            bank_build = "turf_1",
        },
    },
    SUBURB = {
        tile_range = TileRanges.LAND,
        tile_data = {
            ground_name = "Suburb",
            -- old_static_id = 91,
        },
        ground_tile_def = {
            name = "deciduous",
            noise_texture = "noise_mossy_blossom",
            runsound = "dontstarve/movement/run_dirt",
            walksound = "dontstarve/movement/walk_dirt",
            snowsound = "run_ice",
        },
        minimap_tile_def = {
            name = "map_edge",
            noise_texture = "mini_noise_mossy_blossom",
        },
        turf_def = {
            name = "moss",
            anim = "mossy_blossom",
            bank_build = "turf_1",
        },
    },
    FIELDS = {
        tile_range = TileRanges.LAND,
        tile_data = {
            ground_name = "fields",
            -- old_static_id = 91,
        },
        ground_tile_def = {
            name = "jungle",
            noise_texture = "noise_farmland",
            runsound = "dontstarve/movement/run_woods",
            walksound = "dontstarve/movement/walk_woods",
        },
        minimap_tile_def = {
            name = "map_edge",
            noise_texture = "mini_noise_farmland",
        },
        turf_def = {
            name = "fields",
            anim = "farmland",
            bank_build = "turf_1",
        },
    },
    FOUNDATION = {
        tile_range = TileRanges.LAND,
        tile_data = {
            ground_name = "Foundation",
            -- old_static_id = 91,
        },
        ground_tile_def = {
            name = "blocky",
            noise_texture = "noise_ruinsbrick_scaled",
            runsound = "dontstarve/movement/run_dirt",
            walksound = "dontstarve/movement/walk_dirt",
            snowsound = "run_ice",
            flooring = true,
            hard = true,
        },
        minimap_tile_def = {
            name = "map_edge",
            noise_texture = "mini_fanstone_noise",
        },
        turf_def = {
            name = "foundation",
            anim = "fanstone",
            bank_build = "turf_1",
        },
    },
    COBBLEROAD = {
        tile_range = TileRanges.LAND,
        tile_data = {
            ground_name = "Cobbleroad",
            -- old_static_id = 91,
        },
        ground_tile_def = {
            name = "stoneroad",
            noise_texture = "Ground_noise_cobbleroad",
            runsound = "dontstarve/movement/run_dirt",
            walksound = "dontstarve/movement/walk_dirt",
            snowsound = "run_ice",
            flooring = true,
            hard = true,
            roadways = true,
        },
        minimap_tile_def = {
            name = "map_edge",
            noise_texture = "mini_brickroad_noise",
        },
        turf_def = {
            name = "cobbleroad",
            anim = "cobbleroad",
            bank_build = "turf_1",
        },
    },
    LAWN = {
        tile_range = TileRanges.LAND,
        tile_data = {
            ground_name = "Lawn",
            -- old_static_id = 91,
        },
        ground_tile_def = {
            name = "pebble",
            noise_texture = "ground_noise_checkeredlawn",
            runsound = "dontstarve/movement/run_grass",
            walksound = "dontstarve/movement/walk_grass"
        },
        minimap_tile_def = {
            name = "map_edge",
            noise_texture = "mini_grasslawn_noise",
        },
        turf_def = {
            name = "lawn",
            anim = "checkeredlawn",
            bank_build = "turf_1",
        },
    },
    PIGRUINS = {
        tile_range = TileRanges.LAND,
        tile_data = {
            ground_name = "Pigruins",
        },
        ground_tile_def = {
            name = "blocky",
            noise_texture = "ground_ruins_slab",
            runsound = "dontstarve/movement/run_dirt",
            walksound = "dontstarve/movement/walk_dirt",
            snowsound = "run_ice",
            flooring = true,
            hard = true,
        },
        minimap_tile_def = {
            name = "map_edge",
            noise_texture = "mini_ruins_slab"
        }
    },
    PIGRUINS_NOCANOPY = {
        tile_range = TileRanges.LAND,
        tile_data = {
            ground_name = "Pigruins",
        },
        ground_tile_def = {
            name = "blocky",
            noise_texture = "ground_ruins_slab",
            runsound = "dontstarve/movement/run_dirt",
            walksound = "dontstarve/movement/walk_dirt",
            snowsound = "run_ice",
            flooring = true,
            hard = true,
        },
        minimap_tile_def = {
            name = "map_edge",
            noise_texture = "mini_ruins_slab"
        }
    },

    -------------------------------
    -- OCEAN/SEA
    -- (after Land in order to keep render order consistent)
    -------------------------------
    LILYPOND = {
        tile_range = TileRanges.OCEAN,
        tile_data = {
            name = "Lilypond"
        },
        ground_tile_def  = {
            name = "water_medium",
            noise_texture = "Ground_lilypond2",
            runsound = "run_marsh",
            walksound = "walk_marsh",
            -- flashpoint_modifier = 250, -- 亚丹：不知道谁给莲花池地皮加上的更高起火点特性，我先注释掉了，虽然在水上起火慢很合理
            is_shoreline = true,
            ocean_depth = "SHALLOW",
            cannotbedug = true,
        },
        minimap_tile_def = {
            name = "map_edge",
            noise_texture = "mini_lilypond_noise",
        },
    },

    -------------------------------
    -- IMPASSABLE
    -- (render order doesnt matter)
    -------------------------------
--[[
    VOLCANO_LAVA = {
        tile_range = TileRanges.IMPASSABLE,
        tile_data = {
            ground_name = "Lava",
        },
        minimap_tile_def = {
            name = "map_edge",
            noise_texture = "mini_lava_noise",
        },
    },
--]]
    -------------------------------
    -- NOISE
    -- (only for worldgen)
    -------------------------------
    -- I don't see any code about this tile, this Imitated according to the effect  - by Jerry
    BATTLEGROUND_RAINFOREST_NOISE = {
        tile_range = function (noise)
            if noise < 0.5 then
                return WORLD_TILES.DIRT
            end
            return WORLD_TILES.RAINFOREST
        end,
    },

}

for tile, def in pairs(pl_tiledefs) do
    local range = def.tile_range
    if type(range) == "function" then
        range = TileRanges.NOISE
    end

    AddTile(tile, range, def.tile_data, def.ground_tile_def, def.minimap_tile_def, def.turf_def)

    local tile_id = WORLD_TILES[tile]

    if def.tile_range == TileRanges.OCEAN then
        if not is_worldgen then
            TileGroupManager:AddInvalidTile(TileGroups.TransparentOceanTiles, tile_id)
            TileGroupManager:AddValidTile(TileGroups.PlOceanTiles, tile_id)
        end

        table.insert(PL_OCEAN_TILES, tile_id)
    elseif def.tile_range == TileRanges.LAND then
        table.insert(PL_LAND_TILES, tile_id)
    elseif type(def.tile_range) == "function" then
        NoiseFunctions[tile_id] = def.tile_range
    end
end

for prefab, filter in pairs(terrain.filter) do
    if type(filter) == "table" then
        table.insert(filter, WORLD_TILES.LILYPOND)
        -- if table.contains(filter, WORLD_TILES.CARPET) then
        --     table.insert(filter, WORLD_TILES.SNAKESKIN)
        -- end
    end
end

-- Priority turf
-- in ds, tile priority after the mud tile
ChangeTileRenderOrder(WORLD_TILES.PIGRUINS, WORLD_TILES.CARPET, true)
ChangeTileRenderOrder(WORLD_TILES.GASJUNGLE, WORLD_TILES.MUD, true)
ChangeTileRenderOrder(WORLD_TILES.COBBLEROAD, WORLD_TILES.MUD, true)
ChangeTileRenderOrder(WORLD_TILES.LAWN, WORLD_TILES.MUD, true)
ChangeTileRenderOrder(WORLD_TILES.FOUNDATION, WORLD_TILES.MUD, true)
ChangeTileRenderOrder(WORLD_TILES.SUBURB, WORLD_TILES.MUD, true)
ChangeTileRenderOrder(WORLD_TILES.FIELDS, WORLD_TILES.MUD, true)
ChangeTileRenderOrder(WORLD_TILES.DEEPRAINFOREST, WORLD_TILES.MUD, true)
ChangeTileRenderOrder(WORLD_TILES.RAINFOREST, WORLD_TILES.MUD, true)
ChangeTileRenderOrder(WORLD_TILES.PLAINS, WORLD_TILES.MUD, true)
ChangeTileRenderOrder(WORLD_TILES.PAINTED, WORLD_TILES.MUD, true)
ChangeTileRenderOrder(WORLD_TILES.DEEPRAINFOREST_NOCANOPY, WORLD_TILES.MUD, true)
-- ChangeTileRenderOrder(WORLD_TILES.PIGRUINS, WORLD_TILES.MUD, true)
