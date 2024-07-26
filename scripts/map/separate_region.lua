local task_region_mapping = {}
local function SetTaskRegion(task_name, region)
    task_region_mapping[task_name] = region
end

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

local offest_map = {}

-- local _WorldSim = getmetatable(WorldSim).__index
-- local _GetPointsForSite = _WorldSim.GetPointsForSite
-- function _WorldSim.GetPointsForSite(worldsim, node_id)
--     local points_x, points_y, points_type = _GetPointsForSite(worldsim, node_id)
--     if #points_x ~= 0 then
--         for i = 1, #points_x, 1 do
--             local x, y = points_x[i], points_y[i]
--             if offest_map[x] and offest_map[x][y] then
--                 points_x[i] = offest_map[x][y][1]
--                 points_y[i] = offest_map[x][y][2]
--                 points_type[i] = offest_map[x][y][3]
--             end
--         end
--     end

--     return points_x, points_y, points_type
-- end

-- local _GetSitePolygon = _WorldSim.GetSitePolygon
-- function _WorldSim.GetSitePolygon(worldsim, node_id)
--     local points_x, points_y = _GetPointsForSite(worldsim, node_id)
--     if #points_x ~= 0 then
--         for i = 1, #points_x, 1 do
--             local x, y = points_x[i], points_y[i]
--             if offest_map[x] and offest_map[x][y] then
--                 points_x[i] = offest_map[x][y][1]
--                 points_y[i] = offest_map[x][y][2]
--             end
--         end
--     end

--     return points_x, points_y
-- end

-- local _GetVisualTileAtPosition = _WorldSim.GetVisualTileAtPosition
-- function _WorldSim.GetVisualTileAtPosition(worldsim, x, y)
--     if offest_map[x] and offest_map[x][y] then
--         return offest_map[x][y][3]
--     end

--     return _GetVisualTileAtPosition(worldsim, x, y)
-- end

---@param nodes table<string, node>
---@param dist number
local function separate_region(nodes, dist)
    ---@type table<number, table<number, string>>
    -- local point_region_map = {}
    -- local region_points_map = {}
    -- local region_data = {}
    -- local i = 1
    -- for node_id, node in ipairs(nodes) do
    --     local node_id = node.id
    --     if node_id then
    --         local pos = string.find(node_id, ":")
    --         local task = pos and string.sub(node_id, 0, pos - 1) or node_id
    --         local points_x, points_y, points_type = WorldSim:GetPointsForSite(node.id)
    --         if #points_x ~= 0 then
    --             for i = 1, #points_x, 1 do
    --                 local x, y = points_x[i], points_y[i]
    --                 local region = task_region_mapping[task]
    --                 point_region_map[x] = point_region_map[x] or {}
    --                 point_region_map[x][y] = region

    --                 if region then
    --                     region_points_map[region] = region_points_map[region] or {}
    --                     region_points_map[region][x] = region_points_map[region][x] or {}
    --                     region_points_map[region][x][y] = {WorldSim:GetTile(x, y), node_id}
    --                     region_data[region] = region_data[region] or {}
    --                     region_data[region].x_max = math.max(region_data[region].x_max or 0, x)
    --                     region_data[region].x_min = math.min(region_data[region].x_min or math.huge, x)
    --                     region_data[region].y_max = math.max(region_data[region].y_max or 0, y)
    --                     region_data[region].y_min = math.min(region_data[region].y_min or math.huge, y)
    --                     -- WorldSim:SetTile(x, y, WORLD_TILES.GASJUNGLE)
    --                 end
    --             end
    --         end
    --     end
    --     i = i + 1
    -- end

    -- local region_area_map = {}
    -- for region, data in pairs(region_data) do
    --     local width = data.x_max - data.x_min
    --     local heihgt = data.y_max - data.y_min
    --     table.insert(region_area_map, {
    --         region = region,
    --         area = width * heihgt
    --     })
    -- end

    -- table.sort(region_area_map, function(a, b)
    --     return a.area > b.area
    -- end)

    -- local mark = {}

    -- local start_x = 10
    -- local start_y = 10
    -- local last = start_y
    -- for _, data in ipairs(region_area_map) do
    --     local width = region_data[data.region].x_max - region_data[data.region].x_min
    --     local height = region_data[data.region].y_max - region_data[data.region].y_min

    --     if start_x + 10 + width >= 425 then
    --         start_x = 10
    --         start_y = start_y + last + 10
    --     end

    --     print(start_x, start_y)

    --     for x, y_data in pairs(region_points_map[data.region]) do
    --         local offest_x = x - region_data[data.region].x_min

    --         for y, _data in pairs(y_data) do
    --             local offest_y = y - region_data[data.region].y_min

    --             if not mark[x] or not mark[x][y] then
    --                 WorldSim:SetTile(x, y, WORLD_TILES.IMPASSABLE)
    --             end

    --             offest_map[x] = offest_map[x] or {}
    --             offest_map[x][y] = offest_map[x][y] or {
    --                 offest_x + start_x,
    --                 offest_y + start_y,
    --                 _data[1]
    --             }

    --             WorldSim:SetTile(offest_x + start_x, offest_y + start_y, _data[1])
    --             mark[offest_x + start_x] = mark[offest_x + start_x] or {}
    --             mark[offest_x + start_x][offest_y + start_y] = true
    --             -- WorldSim:SetTileNodeId(offest_x + start_x, offest_y + start_y, _data[2])
    --         end
    --     end
    --     last = math.max(last, height)
    --     start_x = start_x + width + 20
    -- end

    -- for x, y_data in pairs(point_region_map) do
    --     for y, region in pairs(y_data) do
    --         for i = -dist, dist do
    --             for j = -dist, dist do
    --                 local near_x, near_y = x + i, y + j
    --                 if point_region_map[near_x] and point_region_map[near_x][near_y] and point_region_map[near_x][near_y] ~= point_region_map[x][y] and WorldSim:GetTile(near_x, near_y) ~= WORLD_TILES.IMPASSABLE then
    --                     WorldSim:SetTile(near_x, near_y, WORLD_TILES.IMPASSABLE)
    --                     point_region_map[near_x][near_y] = nil
    --                 end
    --             end
    --         end

    --         point_region_map[x][y] = nil
    --     end
    -- end
end

return separate_region
