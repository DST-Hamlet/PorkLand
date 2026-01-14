local task_region_mapping = {}
local function SetTaskRegion(task_name, region)
    task_region_mapping[task_name] = region
end

local Island_Accademy =
{
    -- 起点区
    "START",                            
    "Edge_of_the_unknown",             
    "Edge_of_civilization",            

    -- 基础区
    "painted_sands",                    
    "plains",                          
    "rainforests",                     
    "rainforest_ruins",                
    "plains_ruins",                    

    -- 过度区，在基础区之后
    "Deep_rainforest",                  
    "Deep_rainforest_2",               

    -- 终端区，在过渡区之后
    "Lost_Ruins_1",                     
    "Deep_lost_ruins_gas",             

    -- 城市区
    "Pigtopia",                         
    "Pigtopia_capital",                
    "Edge_of_the_unknown_2",           

    -- 莲花区，连在基础区后
    "Lilypond_land",                    
    "Lilypond_land_2",                 

    -- 蚁人区，在莲花区、过度区之后，可能在终端区之前
    "this_is_how_you_get_ants",         
}


SetTaskRegion("START",                           "A")
SetTaskRegion("Edge_of_the_unknown",             "A")
SetTaskRegion("painted_sands",                   "A")
SetTaskRegion("plains",                          "A")
SetTaskRegion("rainforests",                     "A")
SetTaskRegion("rainforest_ruins",                "A")
SetTaskRegion("plains_ruins",                    "A")
SetTaskRegion("Edge_of_civilization",            "A")
SetTaskRegion("Deep_rainforest",                 "A")
SetTaskRegion("Pigtopia",                        "A")
SetTaskRegion("Pigtopia_capital",                "A")
SetTaskRegion("Deep_lost_ruins_gas",             "A")
SetTaskRegion("Edge_of_the_unknown_2",           "A")
SetTaskRegion("Lilypond_land",                   "A")
SetTaskRegion("Lilypond_land_2",                 "A")
SetTaskRegion("this_is_how_you_get_ants",        "A")
SetTaskRegion("Deep_rainforest_2",               "A")
SetTaskRegion("Lost_Ruins_1",                    "A")
SetTaskRegion("Lost_Ruins_4",                    "A")

SetTaskRegion("Deep_rainforest_3",              "B")
SetTaskRegion("Deep_rainforest_mandrake",       "B")
SetTaskRegion("Path_to_the_others",             "B")
SetTaskRegion("Other_edge_of_civilization",     "B")
SetTaskRegion("Other_pigtopia",                 "B")
SetTaskRegion("Other_pigtopia_capital",         "B")

SetTaskRegion("Deep_lost_ruins4",               "C")
SetTaskRegion("lost_rainforest",                "C")

SetTaskRegion("pincale",                        "E")

SetTaskRegion("Deep_wild_ruins4",               "F")
SetTaskRegion("wild_rainforest",                "F")
SetTaskRegion("wild_ancient_ruins",             "F")

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
                point_region[x][y] = task_region_mapping[task]
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
