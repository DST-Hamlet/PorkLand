GLOBAL.setfenv(1, GLOBAL)

require("constants")
require("mathutil")

local separate_region = require("map/separate_region")
local makecities = require("map/city_builder")
local makeborder = require("map/border_finder")
local makebunch = require("map/pl_bunch_spawner")
local makeBrambleSites = require("map/bramble_spawner")
local startlocations = require("map/startlocations")
local forest_map = require("map/forest_map")
local MULTIPLY = forest_map.MULTIPLY
local TRANSLATE_TO_PREFABS = forest_map.TRANSLATE_TO_PREFABS
local TRANSLATE_AND_OVERRIDE = forest_map.TRANSLATE_AND_OVERRIDE

TRANSLATE_TO_PREFABS["asparagus"] = {"asparagus_planted"}
TRANSLATE_TO_PREFABS["peagawk_spawner"] = {"peagawk_spawner"}
TRANSLATE_TO_PREFABS["grass_tall_patch"] = {"grass_tall_patch"}
TRANSLATE_TO_PREFABS["grass_tall"] = {"grass_tall"}
TRANSLATE_TO_PREFABS["lilypad"] = {"lilypad"}
TRANSLATE_TO_PREFABS["lotus"] = {"lotus"}
TRANSLATE_TO_PREFABS["hippopotamoose"] = {"hippopotamoose"}
TRANSLATE_AND_OVERRIDE["frog_poison"] = {"frog_poison"}
TRANSLATE_AND_OVERRIDE["bill"] = {"bill"}

TRANSLATE_AND_OVERRIDE["deep_jungle_fern_noise"] = {"deep_jungle_fern_noise", "deep_jungle_fern_noise_plant"}
TRANSLATE_AND_OVERRIDE["jungle_border_vine"] ={"jungle_border_vine"}
--TRANSLATE_TO_PREFABS["bermudatriangle"] =    {"bermudatriangle_MARKER"}

local function seasonfn(friendly)
    return function(season, data)
        local seasons = data.seasons
        seasons.seasonplateau = season
        seasons.elapseddaysinseason = 0
        seasons.totaldaysinseasonplateau = friendly and TUNING.SEASON_VERYHARSH_DEFAULT * 2 or TUNING.SEASON_VERYHARSH_DEFAULT
        seasons.remainingdaysinseasonplateau = TUNING.SEASON_VERYHARSH_DEFAULT

        return data
    end
end

local SEASONS = forest_map.SEASONS
SEASONS["temperate"] = seasonfn(true)
SEASONS["humid"] = seasonfn(false)
SEASONS["lush"] = seasonfn(false)

local function ValidateGroundTile_PorkLand(tile)
    return WORLD_TILES.IMPASSABLE
end

local SKIP_GEN_CHECKS = false
local _Generate = forest_map.Generate
local GetTileForNoiseTile = Pl_Util.GetUpvalue(_Generate, "GetTileForNoiseTile")
local pickspawnprefab = Pl_Util.GetUpvalue(_Generate, "pickspawnprefab")
local pickspawngroup = Pl_Util.GetUpvalue(_Generate, "pickspawngroup")
local pickspawncountprefabforground = Pl_Util.GetUpvalue(_Generate, "pickspawncountprefabforground")
local TranslateWorldGenChoices = Pl_Util.GetUpvalue(_Generate, "TranslateWorldGenChoices")

forest_map.Generate = function(prefab, map_width, map_height, tasks, level, level_type, ...)
    assert(level.overrides ~= nil, "Level must have overrides specified.")

    local IsPorkLand = level.overrides.isporkland

    if not IsPorkLand then
        return _Generate(prefab, map_width, map_height, tasks, level, level_type, ...)
    end

    TRANSLATE_TO_PREFABS["grass"] = {"grass", "grass_tall", "grass_tall_patch"}

    WorldSim:SetPointsBarrenOrReservedTile(WORLD_TILES.ROAD)
    WorldSim:SetResolveNoiseFunction(GetTileForNoiseTile)

    WorldSim:SetValidateGroundTileFunction(ValidateGroundTile_PorkLand)

    local SpawnFunctions = {
        pickspawnprefab = pickspawnprefab,
        pickspawngroup = pickspawngroup,
        pickspawncountprefabforground = pickspawncountprefabforground,
    }

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

    if  current_gen_params.islands ~= nil then
        local percent = {always = 1, never = 0, default = 0.2, sometimes = 0.1, often = 0.8}
        story_gen_params.island_percent = percent[current_gen_params.islands]
    end

    if  current_gen_params.branching ~= nil then
        story_gen_params.branching = current_gen_params.branching
    end

    if  current_gen_params.loop ~= nil then
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

    local min_size = 350
    if current_gen_params.world_size ~= nil then
        local sizes
        if PLATFORM == "PS4" then
            sizes = {
                ["default"] = 350,
                ["medium"] = 400,
                ["large"] = 425,
            }
        else
            sizes = {
                ["tiny"] = 250,
                ["small"] = 350,
                ["medium"] = 400,
                ["default"] = 425, -- default == large, at the moment...
                ["large"] = 425,
                ["huge"] = 450,
            }
        end

        if sizes[current_gen_params.world_size] then
            min_size = sizes[current_gen_params.world_size]
            print("New size:", min_size, current_gen_params.world_size)
        else
            print("ERROR: Worldgen preset had an invalid size: "..current_gen_params.world_size)
        end
    end
    map_width = min_size
    map_height = min_size
    WorldSim:SetWorldSize(map_width, map_height)

    print("Creating story...")
    require("map/storygen")
    local topology_save, storygen = BuildPorkLandStory(tasks, story_gen_params, level)

    WorldSim:WorldGen_InitializeNodePoints();

    WorldSim:WorldGen_VoronoiPass(100)

    print("... story created")

    print("Baking map...", min_size)

    if not WorldSim:WorldGen_Commit() then
        return nil
    end

    if WorldSim:GenerateVoronoiMap(math.random(), 0, 20) == false then--math.random(0,100)) -- AM: Dont use the tend
        return nil
    end

    topology_save.root:ApplyPoisonTag()
    WorldSim:ConvertToTileMap(min_size)

    -- WorldSim:SeparateIslands()

    print("Map Baked!")
    map_width, map_height = WorldSim:GetWorldSize()

    local join_islands = not current_gen_params.no_joining_islands

    -- Note: This also generates land tiles
    local ground_fill = WORLD_TILES.DIRT
    WorldSim:ForceConnectivity(join_islands, false, ground_fill)

    local entities = {}

    -- Run Node specific functions here
    local nodes = topology_save.root:GetNodes(true)
    for _, node in pairs(nodes) do
        node:SetTilesViaFunction(entities, map_width, map_height)
    end
    separate_region(nodes, 2) -- ensure at least two tiles at intervals between islands

    print("Encoding...")

    local save = {}
    save.ents = {}
    save.map = {
        tiles = "",
        topology = {},
        prefab = prefab,
        has_ocean = current_gen_params.has_ocean,
    }
    topology_save.root:SaveEncode({width = map_width, height = map_height}, save.map.topology)
    WorldSim:CreateNodeIdTileMap(save.map.topology.ids)
    print("Encoding... DONE")

    -- TODO: Double check that each of the rooms has enough space (minimimum # tiles generated) - maybe countprefabs + %
    -- For each item in the topology list
    -- Get number of tiles for that node
    -- if any are less than minumum - restart the generation

    for idx, val in ipairs(save.map.topology.nodes) do
        if string.find(save.map.topology.ids[idx], "LOOP_BLANK_SUB") == nil  then
             local area = WorldSim:GetSiteArea(save.map.topology.ids[idx])
            if area < 8 then
                print ("ERROR: Site "..save.map.topology.ids[idx].." area < 8: "..area)
                if SKIP_GEN_CHECKS == false then
                    return nil
                end
               end
           end
    end

    local translated_prefabs, runtime_overrides = TranslateWorldGenChoices(current_gen_params)

    print("Populating voronoi...")

    topology_save.root:GlobalPrePopulate(entities, map_width, map_height)
    topology_save.root:PorkLandConvertGround(SpawnFunctions, entities, map_width, map_height)
    WorldSim:ReplaceSingleNonLandTiles()

    if not story_gen_params.keep_disconnected_tiles then
        local replace_count = WorldSim:DetectDisconnect()
        --allow at most 5% of tiles to be disconnected
        if replace_count > math.floor(map_width * map_height * 0.05) then
            print("PANIC: Too many disconnected tiles...", replace_count)
            if SKIP_GEN_CHECKS == false then
                return nil
            end
        else
            print("disconnected tiles...", replace_count)
        end
    else
        print("Not checking for disconnected tiles.")
    end

    save.map.generated = {}
    save.map.generated.densities = {}

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
        for prefab, mult in pairs(translated_prefabs) do
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

    -- place jungle border
    local jungle_border_rate = current_gen_params["jungle_border_vine"] and MULTIPLY[current_gen_params["jungle_border_vine"]] or 1
    if jungle_border_rate > 0 then
        makeborder(entities, topology_save, WorldSim, map_width, map_height, "jungle_border_vine", {WORLD_TILES.DEEPRAINFOREST, WORLD_TILES.GASJUNGLE, WORLD_TILES.PIGRUINS}, 0.40 * jungle_border_rate)
    end

    -- make the city here.
    -- print("BUILDING PIG CULTURE")

    --     entities = makecities(entities, topology_save, WorldSim, map_width, map_height, current_gen_params)

    --     --Process tallgrass, jungle fernnoise and other prefabs that spawn groups.
    --     if entities["grass_tall_patch"] then
    --         for i= #entities["grass_tall_patch"], 1, -1 do
    --             local ent = entities["grass_tall_patch"][i]
    --             local grass_tall_patch = 1
    --             if current_gen_params and current_gen_params["grass_tall_patch_rate"] then
    --                 grass_tall_patch = current_gen_params["grass_tall_patch_rate"]
    --             end

    --             local chance = 0.20
    --             if grass_tall_patch == 0 then
    --                 chance = 0
    --             elseif grass_tall_patch == 0.5 then
    --                 chance = 0.10
    --             elseif grass_tall_patch == 1.5 then
    --                 chance = 0.40
    --             elseif grass_tall_patch == 2 then
    --                 chance = 0.60
    --             end
    --             print("MAKE BUNCH?", chance)
    --             if math.random()< chance then
    --                 print("MAKE BUNCH!!!!!!")
    --                 print("")
    --                 makebunch(entities, topology_save, WorldSim, map_width, map_height, "grass_tall", 12, math.random(50,200),ent.x,ent.z,{WORLD_TILES.PLAINS,WORLD_TILES.DEEPRAINFOREST,WORLD_TILES.RAINFOREST})
    --             else
    --                 table.remove( entities["grass_tall_patch"], i)
    --             end
    --         end
    --     end

    if entities["deep_jungle_fern_noise"] then
        for _, ent in ipairs(entities["deep_jungle_fern_noise"]) do
            makebunch(entities, topology_save, WorldSim, map_width, map_height, "deep_jungle_fern_noise_plant", 12, math.random(5, 15), ent.x, ent.z, {WORLD_TILES.DEEPRAINFOREST})
        end
    end

    --     if entities["teatree_piko_nest_patch"] then
    --         for i,ent in ipairs(entities["teatree_piko_nest_patch"]) do
    --             makebunch(entities, topology_save, WorldSim, map_width, map_height, "teatree_piko_nest", 18, math.random(4,8),ent.x,ent.z)
    --         end
    --     end

    --     if entities["asparagus_patch"] then
    --         for i,ent in ipairs(entities["asparagus_patch"]) do
    --             makebunch(entities, topology_save, WorldSim, map_width, map_height, "asparagus_planted", 2, math.random(2,6),ent.x,ent.z,{WORLD_TILES.PLAINS,WORLD_TILES.DEEPRAINFOREST,WORLD_TILES.RAINFOREST})
    --         end
    --         entities["asparagus_patch"] = nil
    --     end

    --     -- filter small ruins doors
    --     if entities["pig_ruins_entrance_small"] then
    --         print("FOUND",#entities["pig_ruins_entrance_small"], "RUIN SITES")
    --         local newents = deepcopy(entities["pig_ruins_entrance_small"])
    --         entities["pig_ruins_entrance_small"] = {}
    --         local num = RUINS.SMALL

    --         -- I didn't want to use the same multiply system, so I'm translating it here.
    --         if current_gen_params and current_gen_params["pig_ruins_entrance_small"] then
    --             if current_gen_params["pig_ruins_entrance_small"] == 0 then
    --                 num = 0
    --             elseif current_gen_params["pig_ruins_entrance_small"] == 2 then
    --                 num = num * 3
    --             elseif current_gen_params["pig_ruins_entrance_small"] == 1.5 then
    --                 num = num * 2
    --             elseif current_gen_params["pig_ruins_entrance_small"] == 0.5 then
    --                 num = math.ceil(num/2)
    --             end
    --         end

    --         for i=1, num do
    --             if #newents>0 then
    --                 local rand = math.random(1,#newents)
    --                 local entry = newents[rand]
    --                 table.remove(newents,rand)
    --                 print("INSERTING RUIN")
    --                 table.insert(entities["pig_ruins_entrance_small"],entry)
    --             end
    --         end
    --     end

    --     -- turn potential bat caves into real bat caves.
    --     if entities["vampirebatcave_potential"] then
    --         local ents = entities["vampirebatcave_potential"]

    --         entities["vampirebatcave"] = {}
    --         local num = BATS.CAVE_NUM

    --         -- I didn't want to use the same multiply system, so I'm translating it here.
    --         if current_gen_params and current_gen_params["vampirebatcave"] then
    --             if current_gen_params["vampirebatcave"] == 0 then
    --                 num = 0
    --             elseif current_gen_params["vampirebatcave"] == 2 then
    --                 num = num * 3
    --             elseif current_gen_params["vampirebatcave"] == 1.5 then
    --                 num = num * 2
    --             elseif current_gen_params["vampirebatcave"] == 0.5 then
    --                 num = math.ceil(num/2)
    --             end
    --         end

    --         for i=1, num do
    --             if #ents > 0 then
    --                 local rand =  math.random(1, #ents)
    --                 local save_data = { x=ents[rand].x, z=ents[rand].z }
    --                 table.insert(entities["vampirebatcave"], save_data)
    --                 table.remove(ents,rand)
    --             end
    --         end
    --         entities["vampirebatcave_potential"] = nil
    --     end


    --     if not entities["relic_1"] then
    --         entities["relic_1"] = {}
    --     end
    --     if not entities["relic_2"] then
    --         entities["relic_2"] = {}
    --     end
    --     if not entities["relic_3"] then
    --         entities["relic_3"] = {}
    --     end

    --     if not entities["pig_ruins_ant"] then
    --         entities["pig_ruins_ant"] = {}
    --     end
    --     if not entities["pig_ruins_pig"] then
    --         entities["pig_ruins_pig"] = {}
    --     end
    --     if not entities["pig_ruins_idol"] then
    --         entities["pig_ruins_idol"] = {}
    --     end
    --     if not entities["pig_ruins_plaque"] then
    --         entities["pig_ruins_plaque"] = {}
    --     end

    --     if entities["randomrelic"] then
    --         for i,ent in ipairs(entities["randomrelic"]) do
    --             local relic = "relic_" .. tostring(math.random(1,3))
    --             --print("ADDING RELIC",relic)
    --             local save_data = { x=ent.x, z=ent.z }
    --             table.insert(entities[relic],save_data)
    --         end
    --         entities["randomrelic"] = nil
    --     end

    --     if entities["randomruin"] then
    --         for i,ent in ipairs(entities["randomruin"]) do
    --             local save_data = { x=ent.x, z=ent.z }
    --             if math.random(1,2) == 1 then
    --                 table.insert(entities["pig_ruins_idol"],save_data)
    --             else
    --                 table.insert(entities["pig_ruins_plaque"],save_data)
    --             end
    --         end
    --         entities["randomruin"] = nil
    --     end

    --     if entities["randomdust"] then
    --         for i,ent in ipairs(entities["randomdust"]) do
    --             local save_data = { x=ent.x, z=ent.z }
    --             if math.random(1,2) == 1 then
    --                 table.insert(entities["pig_ruins_pig"],save_data)
    --             else
    --                 table.insert(entities["pig_ruins_ant"],save_data)
    --             end
    --         end
    --         entities["randomdust"] = nil
    --     end
    --     --entities = makeinteriorspawner(entities,topology_save, WorldSim, map_width, map_height)

    --     if entities["pig_scepter"] then
    --         while #entities["pig_scepter"] > 1 do
    --             table.remove(entities["pig_scepter"],math.random(1,#entities["pig_scepter"]))
    --         end
    --     end

    --     entities = makeBrambleSites(entities,topology_save, WorldSim, map_width, map_height)

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

    save.ents = entities

    save.map.tiles, save.map.tiledata, save.map.nav, save.map.adj, save.map.nodeidtilemap = WorldSim:GetEncodedMap(join_islands)
    save.map.world_tile_map = GetWorldTileMap()

    save.map.topology.overrides = deepcopy(current_gen_params)
    save.map.topology.pl_worldgen_version = 1  -- Feel free to increase this version when making big changes

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

    save.map.roads = {}

    print("Done "..prefab.." map gen!")

    return save
end
