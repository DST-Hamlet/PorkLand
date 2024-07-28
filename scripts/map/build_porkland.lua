local make_border = require("map/border_finder")
local make_cities = require("map/city_builder")
local make_bunch = require("map/make_bunch")
-- local make_bramble_sites = require("map/bramble_spawner")

local forest_map = require("map/forest_map")
local MULTIPLY = forest_map.MULTIPLY

local BATS =  -- 复制自constants
{
    EMPTY = "empty",
    CAVE = "cave",
    ATTACK = "attack",
    CAVE_NUM = 6,
}

local RUINS =
{
    SMALL = 4,
}

local function build_porkland(entities, topology_save, map_width, map_height, current_gen_params)
    if current_gen_params == nil then
        current_gen_params = {}
    end

    -- place jungle border
    local jungle_border_rate = current_gen_params["jungle_border_vine"] and MULTIPLY[current_gen_params["jungle_border_vine"]] or 1
    if jungle_border_rate > 0 then
        make_border(entities, topology_save, WorldSim, map_width, map_height, "jungle_border_vine", {WORLD_TILES.DEEPRAINFOREST, WORLD_TILES.GASJUNGLE, WORLD_TILES.PIGRUINS}, 0.40 * jungle_border_rate)
    end

    -- make the city here.
    entities = make_cities(entities, topology_save, WorldSim, map_width, map_height, current_gen_params)

    -- Process tallgrass, jungle fernnoise and other prefabs that spawn groups.
    if entities["grass_tall_bunche_patch"] then
        for i = #entities["grass_tall_bunche_patch"], 1, -1 do
            local ent = entities["grass_tall_bunche_patch"][i]
            local grass_tall_bunche_rate = current_gen_params["grass_tall_bunches"] and MULTIPLY[current_gen_params["grass_tall_bunches"]] or 1

            local chance = 0.20 * grass_tall_bunche_rate
            print("MAKE BUNCH?", chance)
            if math.random() < chance then
                print("MAKE BUNCH!!!!!!")

                make_bunch(entities, topology_save, WorldSim, map_width, map_height, "grass_tall", 12, math.random(50, 200), ent.x,
                    ent.z, {WORLD_TILES.PLAINS, WORLD_TILES.DEEPRAINFOREST, WORLD_TILES.RAINFOREST})
            else
                table.remove(entities["grass_tall_bunche_patch"], i)
            end
        end
    end

    if entities["deep_jungle_fern_noise"] then
        for _, ent in ipairs(entities["deep_jungle_fern_noise"]) do
            make_bunch(entities, topology_save, WorldSim, map_width, map_height, "deep_jungle_fern_noise_plant", 12,
                math.random(5, 15), ent.x, ent.z, {WORLD_TILES.DEEPRAINFOREST}, nil, 2)
        end
    end

    if entities["teatree_piko_nest_patch"] then
        for i, ent in ipairs(entities["teatree_piko_nest_patch"]) do
            make_bunch(entities, topology_save, WorldSim, map_width, map_height, "teatree_piko_nest", 18, math.random(4, 8),
                ent.x, ent.z, {WORLD_TILES.FIELDS})
        end
    end

    -- no asparagus_patch
    -- if entities["asparagus_patch"] then
    --     for i, ent in ipairs(entities["asparagus_patch"]) do
    --         make_bunch(entities, topology_save, WorldSim, map_width, map_height, "asparagus_planted", 2, math.random(2, 6),
    --             ent.x, ent.z, {WORLD_TILES.PLAINS, WORLD_TILES.DEEPRAINFOREST, WORLD_TILES.RAINFOREST})
    --     end
    --     entities["asparagus_patch"] = nil
    -- end


    -- filter small ruins doors
    if entities["pig_ruins_entrance_small"] then
        print("FOUND", #entities["pig_ruins_entrance_small"], "RUIN SITES")
        local newents = deepcopy(entities["pig_ruins_entrance_small"])
        entities["pig_ruins_entrance_small"] = {}
        local num = RUINS.SMALL

        -- I didn't want to use the same multiply system, so I'm translating it here.
        if current_gen_params and current_gen_params["pig_ruins_entrance_small"] then
            if current_gen_params["pig_ruins_entrance_small"] == 0 then
                num = 0
            elseif current_gen_params["pig_ruins_entrance_small"] == 2 then
                num = num * 3
            elseif current_gen_params["pig_ruins_entrance_small"] == 1.5 then
                num = num * 2
            elseif current_gen_params["pig_ruins_entrance_small"] == 0.5 then
                num = math.ceil(num / 2)
            end
        end

        for i = 1, num do
            if #newents > 0 then
                local rand = math.random(1, #newents)
                local entry = newents[rand]
                table.remove(newents, rand)
                print("INSERTING RUIN")
                table.insert(entities["pig_ruins_entrance_small"], entry)
            end
        end
    end

    -- turn potential bat caves into real bat caves.
    if entities["vampirebatcave_potential"] then
        local ents = entities["vampirebatcave_potential"]

        entities["vampirebatcave"] = {}
        local num = BATS.CAVE_NUM

        -- I didn't want to use the same multiply system, so I'm translating it here.
        if current_gen_params and current_gen_params["vampirebatcave"] then
            if current_gen_params["vampirebatcave"] == 0 then
                num = 0
            elseif current_gen_params["vampirebatcave"] == 2 then
                num = num * 3
            elseif current_gen_params["vampirebatcave"] == 1.5 then
                num = num * 2
            elseif current_gen_params["vampirebatcave"] == 0.5 then
                num = math.ceil(num / 2)
            end
        end

        for i = 1, num do
            if #ents > 0 then
                local rand = math.random(1, #ents)
                local save_data = {
                    x = ents[rand].x,
                    z = ents[rand].z
                }
                table.insert(entities["vampirebatcave"], save_data)
                table.remove(ents, rand)
            end
        end
        entities["vampirebatcave_potential"] = nil
    end

    -- if not entities["relic_1"] then
    --     entities["relic_1"] = {}
    -- end
    -- if not entities["relic_2"] then
    --     entities["relic_2"] = {}
    -- end
    -- if not entities["relic_3"] then
    --     entities["relic_3"] = {}
    -- end

    -- if not entities["pig_ruins_ant"] then
    --     entities["pig_ruins_ant"] = {}
    -- end
    -- if not entities["pig_ruins_pig"] then
    --     entities["pig_ruins_pig"] = {}
    -- end
    -- if not entities["pig_ruins_idol"] then
    --     entities["pig_ruins_idol"] = {}
    -- end
    -- if not entities["pig_ruins_plaque"] then
    --     entities["pig_ruins_plaque"] = {}
    -- end


    -- if entities["randomrelic"] then
    --     for i, ent in ipairs(entities["randomrelic"]) do
    --         local relic = "relic_" .. tostring(math.random(1, 3))
    --         -- print("ADDING RELIC",relic)
    --         local save_data = {
    --             x = ent.x,
    --             z = ent.z
    --         }
    --         table.insert(entities[relic], save_data)
    --     end
    --     entities["randomrelic"] = nil
    -- end

    -- if entities["randomruin"] then
    --     for i, ent in ipairs(entities["randomruin"]) do
    --         local save_data = {
    --             x = ent.x,
    --             z = ent.z
    --         }
    --         if math.random(1, 2) == 1 then
    --             table.insert(entities["pig_ruins_idol"], save_data)
    --         else
    --             table.insert(entities["pig_ruins_plaque"], save_data)
    --         end
    --     end
    --     entities["randomruin"] = nil
    -- end

    -- if entities["randomdust"] then
    --     for i, ent in ipairs(entities["randomdust"]) do
    --         local save_data = {
    --             x = ent.x,
    --             z = ent.z
    --         }
    --         if math.random(1, 2) == 1 then
    --             table.insert(entities["pig_ruins_pig"], save_data)
    --         else
    --             table.insert(entities["pig_ruins_ant"], save_data)
    --         end
    --     end
    --     entities["randomdust"] = nil
    -- end

    -- if entities["pig_scepter"] then
    --     while #entities["pig_scepter"] > 1 do
    --         table.remove(entities["pig_scepter"], math.random(1, #entities["pig_scepter"]))
    --     end
    -- end

    -- entities = makeBrambleSites(entities, topology_save, WorldSim, map_width, map_height)
end

return build_porkland
