local task_regison_mapping = {}
local function SetTaskRegison(task_name, region)
    task_regison_mapping[task_name] = region
end

SetTaskRegison("START",                           "A")
SetTaskRegison("Edge_of_the_unknown",             "A")
SetTaskRegison("painted_sands",                   "A")
SetTaskRegison("plains",                          "A")
SetTaskRegison("rainforests",                     "A")
SetTaskRegison("rainforest_ruins",                "A")
SetTaskRegison("plains_ruins",                    "A")
SetTaskRegison("Edge_of_civilization",            "A")
SetTaskRegison("Deep_rainforest",                 "A")
SetTaskRegison("Pigtopia",                        "A")
SetTaskRegison("Pigtopia_capital",                "A")
SetTaskRegison("Deep_lost_ruins_gas",             "A")
SetTaskRegison("Edge_of_the_unknown_2",           "A")
SetTaskRegison("Lilypond_land",                   "A")
SetTaskRegison("Lilypond_land_2",                 "A")
SetTaskRegison("this_is_how_you_get_ants",        "A")
SetTaskRegison("Deep_rainforest_2",               "A")
SetTaskRegison("Lost_Ruins_1",                    "A")
SetTaskRegison("Lost_Ruins_4",                    "A")

SetTaskRegison("Deep_rainforest_3",              "B")
SetTaskRegison("Deep_rainforest_mandrake",       "B")
SetTaskRegison("Path_to_the_others",             "B")
SetTaskRegison("Other_edge_of_civilization",     "B")
SetTaskRegison("Other_pigtopia",                 "B")
SetTaskRegison("Other_pigtopia_capital",         "B")

SetTaskRegison("Deep_lost_ruins4",               "C")
SetTaskRegison("lost_rainforest",                "C")

SetTaskRegison("pincale",                        "E")

SetTaskRegison("Deep_wild_ruins4",               "F")
SetTaskRegison("wild_rainforest",                "F")
SetTaskRegison("wild_ancient_ruins",             "F")

---@param nodes table<string, node>
---@param dist number
local function separate_region(nodes, dist)
    ---@type table<number, table<number, string>>
    local point_region = {}
    for node_id, node in pairs(nodes) do
        local pos = string.find(node_id, ":")
        local task = pos and string.sub(node_id, 0, pos - 1) or node_id
        local points_x, points_y, points_type = WorldSim:GetPointsForSite(node.id)
        if #points_x ~= 0 then
            for i = 1, #points_x, 1 do
                local x, y = points_x[i], points_y[i]
                point_region[x] = point_region[x] or {}
                point_region[x][y] = task_regison_mapping[task]
                -- WorldSim:SetTile(x, y, WORLD_TILES.GASJUNGLE)
            end
        end
    end

    for x, y_data in pairs(point_region) do
        for y, region in pairs(y_data) do
            for i = -dist, dist do
                for j = -dist, dist do
                    local near_x, near_y = x + i, y + j
                    if point_region[near_x] and point_region[near_x][near_y] and point_region[near_x][near_y] ~= point_region[x][y] and WorldSim:GetTile(near_x, near_y) ~= WORLD_TILES.IMPASSABLE then
                        WorldSim:SetTile(near_x, near_y, WORLD_TILES.IMPASSABLE)
                        point_region[near_x][near_y] = nil
                    end
                end
            end

            point_region[x][y] = nil
        end
    end
end

return separate_region
