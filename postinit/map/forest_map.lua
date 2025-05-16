local modimport = modimport
GLOBAL.setfenv(1, GLOBAL)

require("constants")
require("mathutil")
require("map/storygen")

local Levels = require("map/levels")

local build_map = require("map/build_map")
local build_porkland = require("map/build_porkland")
local startlocations = require("map/startlocations")
local forest_map = require("map/forest_map")
local BuildPorkLandStory = require("map/pl_storygen")
local MULTIPLY = forest_map.MULTIPLY
local TRANSLATE_TO_PREFABS = forest_map.TRANSLATE_TO_PREFABS
local TRANSLATE_AND_OVERRIDE = forest_map.TRANSLATE_AND_OVERRIDE

TRANSLATE_TO_PREFABS["lotus"] = { "lotus" }
TRANSLATE_TO_PREFABS["pangolden"] = { "pangolden" }
TRANSLATE_TO_PREFABS["asparagus"] = { "asparagus_planted" }
TRANSLATE_TO_PREFABS["dungpile"] = { "dungpile" }
TRANSLATE_TO_PREFABS["hanging_vine_patch"] = { "hanging_vine_patch" }
TRANSLATE_TO_PREFABS["peagawk"] = { "peagawk" }
TRANSLATE_TO_PREFABS["pog"] = { "pog" }
TRANSLATE_TO_PREFABS["thunderbirdnest"] = {"thunderbirdnest"}
TRANSLATE_TO_PREFABS["grass_tall_bunches"] = { "grass_tall_bunches" }
TRANSLATE_TO_PREFABS["grass_tall"] = { "grass_tall" }

TRANSLATE_AND_OVERRIDE["deep_jungle_fern_noise"] = { "deep_jungle_fern_noise", "deep_jungle_fern_noise_plant" }
TRANSLATE_AND_OVERRIDE["jungle_border_vine"] = { "jungle_border_vine" }
--TRANSLATE_TO_PREFABS["bermudatriangle"] =    {"bermudatriangle_MARKER"}

local function season_fn(season, data)
    local seasons = data.seasons

    seasons.seasonplateau = season
    seasons.elapseddaysinseasonplateau = 0
    seasons.totaldaysinseasonplateau = TUNING.SEASON_VERYHARSH_DEFAULT
    seasons.remainingdaysinseasonplateau = TUNING.SEASON_VERYHARSH_DEFAULT

    return data
end

local SEASONS = forest_map.SEASONS
SEASONS["temperate"] = season_fn
SEASONS["humid"] = season_fn
SEASONS["lush"] = season_fn

local function validate_ground_tile(tile)
    return WORLD_TILES.IMPASSABLE
end

local SKIP_GEN_CHECKS = false
local _Generate = forest_map.Generate
local GetTileForNoiseTile = ToolUtil.GetUpvalue(_Generate, "GetTileForNoiseTile")
local TranslateWorldGenChoices = ToolUtil.GetUpvalue(_Generate, "TranslateWorldGenChoices")
local SpawnFunctions = {
    pickspawnprefab = ToolUtil.GetUpvalue(_Generate, "pickspawnprefab"),
    pickspawngroup = ToolUtil.GetUpvalue(_Generate, "pickspawngroup"),
    pickspawncountprefabforground = ToolUtil.GetUpvalue(_Generate, "pickspawncountprefabforground"),
}

local function GetWorldGenParams(level, level_type)
    local current_gen_params = deepcopy(level.overrides)
    local default_impassible_tile = WORLD_TILES.IMPASSABLE

    local story_gen_params = {}
    story_gen_params.impassible_value = default_impassible_tile
    story_gen_params.level_type = level_type

    if current_gen_params.start_location == nil then
        current_gen_params.start_location = "default"
    end

    if current_gen_params.start_location ~= nil then
        local start_loc = startlocations.GetStartLocation(current_gen_params.start_location)
        story_gen_params.start_setpeice = type(start_loc.start_setpeice) == "table" and start_loc.start_setpeice[math.random(#start_loc.start_setpeice)] or start_loc.start_setpeice
        story_gen_params.start_node = type(start_loc.start_node) == "table" and start_loc.start_node[math.random(#start_loc.start_node)] or start_loc.start_node
        if story_gen_params.start_node == nil then
            -- existing_start_node is no longer supported
            story_gen_params.start_node = type(start_loc.existing_start_node) == "table" and start_loc.existing_start_node[math.random(#start_loc.existing_start_node)] or start_loc.existing_start_node
        end
    end

    if current_gen_params.islands ~= nil then
        local percent = {always = 1, never = 0, default = 0.2, sometimes = 0.1, often = 0.8}
        story_gen_params.island_percent = percent[current_gen_params.islands]
    end

    if current_gen_params.branching ~= nil then
        story_gen_params.branching = current_gen_params.branching
    end

    if current_gen_params.loop ~= nil then
        local loop_percent = { never = 0, default = nil, always = 1.0 }
        local loop_target = { never = "any", default = nil, always = "end"}
        story_gen_params.loop_percent = loop_percent[current_gen_params.loop]
        story_gen_params.loop_target = loop_target[current_gen_params.loop]
    end

    if current_gen_params.keep_disconnected_tiles ~= nil then
        story_gen_params.keep_disconnected_tiles = current_gen_params.keep_disconnected_tiles
    end

    if current_gen_params.no_joining_islands ~= nil then
        story_gen_params.no_joining_islands = current_gen_params.no_joining_islands
    end

    if current_gen_params.has_ocean ~= nil then
        story_gen_params.has_ocean = current_gen_params.has_ocean
    end

    if current_gen_params.no_wormholes_to_disconnected_tiles ~= nil then
        story_gen_params.no_wormholes_to_disconnected_tiles = current_gen_params.no_wormholes_to_disconnected_tiles
    end

    if current_gen_params.wormhole_prefab ~= nil then
        story_gen_params.wormhole_prefab = current_gen_params.wormhole_prefab
    end

    ApplySpecialEvent(current_gen_params.specialevent)
    for k, event_name in pairs(SPECIAL_EVENTS) do
        if current_gen_params[event_name] == "enabled" then
            ApplyExtraEvent(event_name)
        end
    end

    return current_gen_params, story_gen_params
end

local function InitWorld(world_size, join_islands, topology_save)
    WorldSim:SetPointsBarrenOrReservedTile(WORLD_TILES.ROAD)
    WorldSim:SetResolveNoiseFunction(GetTileForNoiseTile)
    WorldSim:SetValidateGroundTileFunction(validate_ground_tile)

    local min_size = 350
    if world_size ~= nil then
        local sizes
        if PLATFORM == "PS4" then
            sizes = {
                ["default"] = 350,
                ["medium"] = 400,
                ["large"] = 425,
            }
        else
            sizes = {
                ["tiny"] = 1,
                ["small"] = 50,
                ["medium"] = 400,
                ["default"] = 425, -- default == large, at the moment...
                ["large"] = 425,
                ["huge"] = 450,
            }
        end

        if sizes[world_size] then
            min_size = sizes[world_size]
            print("New size:", min_size, world_size)
        else
            print("ERROR: Worldgen preset had an invalid size: " .. world_size)
        end
    end
    local map_width = min_size
    local map_height = min_size
    WorldSim:SetWorldSize(map_width, map_height)

    WorldSim:WorldGen_InitializeNodePoints();

    WorldSim:WorldGen_VoronoiPass(100)

    print("Baking map...", min_size)

    if not WorldSim:WorldGen_Commit() then
        return nil
    end

    if WorldSim:GenerateVoronoiMap(math.random(), 0, 20) == false then--math.random(0,100)) -- AM: Dont use the tend
        return nil
    end

    topology_save.root:ApplyPoisonTag()

    WorldSim:ConvertToTileMap(min_size)

    print("Map Baked!")
    map_width, map_height = WorldSim:GetWorldSize()

    -- Note: This also generates land tiles
    local ground_fill = WORLD_TILES.DIRT
    WorldSim:ForceConnectivity(join_islands, false, ground_fill)

    -- WorldSim:SeparateIslands()

    return map_width, map_height
end

local function MakeFakeStory(story_gen_params)
    local level_data = Levels.GetDataForLevelID("PORKLAND_TEST")
    level_data.overrides.world_size = "medium"
    local level = Level(level_data)
    level:ChooseTasks()
    level:ChooseSetPieces()
    local tasks = level:GetTasksForLevel()

    local topology_save, storygen = BuildPorkLandStory(tasks, story_gen_params, level)

    return topology_save, storygen
end

local function GeneratePorkland(prefab, map_width, map_height, tasks, level, level_type, ...)
    TRANSLATE_TO_PREFABS["grass"] = {"grass", "grass_tall", "grass_tall_bunche_patch"}

    local current_gen_params, story_gen_params = GetWorldGenParams(level, level_type)

    local join_islands = not current_gen_params.no_joining_islands

    print("Creating story...")
    local topology_save, storygen = BuildPorkLandStory(tasks, story_gen_params, level)

    print("Init world...")
    map_width, map_height = InitWorld(current_gen_params.world_size, join_islands, topology_save)

    if map_width == nil or map_height == nil then
        return nil
    end

    local entities = {}
    local save = {
        ents = entities,
        map = {
            tiles = "",
            roads = {},
            topology = {},
            generated = {
                densities = {},
            },
            prefab = prefab,
            has_ocean = current_gen_params.has_ocean,
        },
    }

    if level.id == "PORKLAND_DEFAULT" then
        modimport("postinit/map/worldsim")

        build_map.RecordMap(topology_save)

        collectgarbage("collect")
        WorldSim:ResetAll()

        local fake_topology_save, fake_storygen = MakeFakeStory(story_gen_params)
        map_width, map_height = InitWorld("medium", join_islands, fake_topology_save)

        local result = build_map.ReBuildMap(map_width, map_height)
        if not result then
            print("PANIC: Failed to generate map!")
            return nil
        end

        save.map.topology.node_datas = WorldSim:GetNodeDatas()

        WorldSim:CreateNodeIdTileMap()
        topology_save.root:SaveEncode({width = map_width, height = map_height}, save.map.topology)
    else
        topology_save.root:SaveEncode({width = map_width, height = map_height}, save.map.topology)
        WorldSim:CreateNodeIdTileMap(save.map.topology.ids)
    end

    -- Run Node specific functions here
    local nodes = topology_save.root:GetNodes(true)
    for _, node in pairs(nodes) do
        node:SetTilesViaFunction(entities, map_width, map_height)
    end

    local translated_prefabs, runtime_overrides = TranslateWorldGenChoices(current_gen_params)

    print("Populating voronoi...")
    topology_save.root:GlobalPrePopulate(entities, map_width, map_height)
    topology_save.root:ConvertGround(SpawnFunctions, entities, map_width, map_height)
    WorldSim:ReplaceSingleNonLandTiles()

    if not story_gen_params.keep_disconnected_tiles then
        local replace_count = WorldSim:DetectDisconnect()
        --allow at most 5% of tiles to be disconnected
        if replace_count > math.floor(map_width * map_height * 0.05) then
            print("PANIC: Too many disconnected tiles...",replace_count)
            if SKIP_GEN_CHECKS == false then
                return nil
            end
        else
            print("disconnected tiles...",replace_count)
        end
    else
        print("Not checking for disconnected tiles.")
    end

    topology_save.root:PopulateVoronoi(SpawnFunctions, entities, map_width, map_height, translated_prefabs, save.map.generated.densities)
    topology_save.root:GlobalPostPopulate(entities, map_width, map_height)

    for k, ents in pairs(entities) do
        for i=#ents, 1, -1 do
            local x = ents[i].x/TILE_SCALE + map_width/2.0
            local y = ents[i].z/TILE_SCALE + map_height/2.0

            local tiletype = WorldSim:GetVisualTileAtPosition(x,y) -- Warning: This does not quite work as expected. It thinks the ground type id is in rendering order, which it totally is not!
            if TileGroupManager:IsImpassableTile(tiletype) then
                print("Removing entity on IMPASSABLE", k, x, y, ""..ents[i].x..", 0, "..ents[i].z)
                table.remove(entities[k], i)
            end
        end
    end

    if translated_prefabs ~= nil then
        -- Filter out any etities over our overrides
        for prefab,mult in pairs(translated_prefabs) do
            if type(mult) == "number" and mult < 1 and entities[prefab] ~= nil and #entities[prefab] > 0 then
                local new_amt = math.floor(#entities[prefab]*mult)
                if new_amt == 0 then
                    entities[prefab] = nil
                else
                    entities[prefab] = shuffleArray(entities[prefab])
                    while #entities[prefab] > new_amt do
                        table.remove(entities[prefab], 1)
                    end
                end
            end
        end
    end

    BunchSpawnerInit(entities, map_width, map_height)
    BunchSpawnerRun(WorldSim)
    AncientArchivePass(entities, map_width, map_height, WorldSim)

    build_porkland(entities, topology_save, map_width, map_height, current_gen_params)

    local double_check = {}
    for i, prefab in ipairs(level.required_prefabs or {}) do
        if not translated_prefabs or translated_prefabs[prefab] ~= 0 then
            if double_check[prefab] == nil then
                double_check[prefab] = 1
            else
                double_check[prefab] = double_check[prefab] + 1
            end
        end
    end
    for prefab, count in pairs(topology_save.root:GetRequiredPrefabs()) do
        if not translated_prefabs or translated_prefabs[prefab] ~= 0 then
            if double_check[prefab] == nil then
                double_check[prefab] = count
            else
                double_check[prefab] = double_check[prefab] + count
            end
        end
    end

    for prefab, count in pairs(double_check) do
        print ("Checking Required Prefab " .. prefab .. " has at least " .. count .. " instances (" .. (entities[prefab] ~= nil and #entities[prefab] or 0) .. " found).")

        if entities[prefab] == nil or #entities[prefab] < count then
            if level.overrides[prefab] == "never" then
                print(string.format(" - missing required prefab [%s] was disabled in the world generation options!", prefab))
            else
                print(string.format("PANIC: missing required prefab [%s]! Expected %d, got %d", prefab, count, entities[prefab] == nil and 0 or #entities[prefab]))
                if SKIP_GEN_CHECKS == false then
                    return nil
                end
            end
        end
    end

    save.map.tiles, save.map.tiledata, save.map.nav, save.map.adj, save.map.nodeidtilemap = WorldSim:GetEncodedMap(join_islands)
    save.map.world_tile_map = GetWorldTileMap()

    save.map.topology.overrides = deepcopy(current_gen_params)
    save.map.topology.pl_worldgen_version = 2 -- Feel free to increase this version when making big changes

    if save.map.topology.overrides == nil then
        save.map.topology.overrides = {}
    end

    save.map.width, save.map.height = map_width, map_height

    local start_season = current_gen_params.season_start or "autumn"
    if string.find(start_season, "|", nil, true) then
        start_season = GetRandomItem(string.split(start_season, "|"))
    elseif start_season == "default" then
        start_season = forest_map.DEFAULT_SEASON
    end

    local pl_start_season = current_gen_params.porkland_season_start or "temperate"
    if string.find(pl_start_season, "|", nil, true) then
        pl_start_season = GetRandomItem(string.split(pl_start_season, "|"))
    elseif pl_start_season == "default" then
        pl_start_season = "temperate"
    end

    local componentdata = SEASONS[start_season](start_season)
    componentdata = SEASONS[pl_start_season](pl_start_season, componentdata)

    if save.world_network == nil then
        save.world_network = {persistdata = {}}
    elseif save.world_network.persistdata == nil then
        save.world_network.persistdata = {}
    end

    for k, v in pairs(componentdata) do
        save.world_network.persistdata[k] = v
    end

    if (save.ents.spawnpoint_multiplayer == nil or #save.ents.spawnpoint_multiplayer == 0)
        and (save.ents.multiplayer_portal == nil or #save.ents.multiplayer_portal == 0)
        and (save.ents.quagmire_portal == nil or #save.ents.quagmire_portal == 0)
        and (save.ents.lavaarena_portal == nil or #save.ents.lavaarena_portal == 0) then
        print("PANIC: No start location!")
        if SKIP_GEN_CHECKS == false then
            return nil
        else
            save.ents.spawnpoint = {{x = 0, y = 0, z = 0}}
        end
    end

    print("Done "..prefab.." map gen!")

    return save, topology_save
end

forest_map.Generate = function(prefab, map_width, map_height, tasks, level, level_type, ...)
    local is_porkland = level.location == "porkland"
    Node.is_porkland = is_porkland
    if not is_porkland then
        return _Generate(prefab, map_width, map_height, tasks, level, level_type, ...)
    end

    return GeneratePorkland(prefab, map_width, map_height, tasks, level, level_type, ...)
end
