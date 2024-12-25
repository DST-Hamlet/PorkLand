
local Pack = require("main/packer")

local RegionGap = 10

local RegionData = {}

local function RecordMap(topology_save)
    local regions_data = {
        island_accademy = { points_data = {} },
        island_royal = { points_data = {} },
        island_pugalisk = { points_data = {} },
        island_BFB = { points_data = {} },
        island_ancient = { points_data = {} },
    }

    local nodes = topology_save.root:GetNodes(true)
    for _, node in pairs(nodes) do
        for _, tag in pairs(node.data.tags) do
            local data = regions_data[tag]
            if data then
                local points_x, points_y, points_type = WorldSim:GetPointsForSite(node.id)
                for i = 1, #points_x, 1 do
                    local x, y = points_x[i], points_y[i]
                    data.x_max = math.max(data.x_max or 0, x)
                    data.x_min = math.min(data.x_min or math.huge, x)
                    data.y_max = math.max(data.y_max or 0, y)
                    data.y_min = math.min(data.y_min or math.huge, y)
                    data.points_data[x] = data.points_data[x] or {}
                    data.points_data[x][y] = {
                        tile = points_type[i],
                        node = node,
                    }
                end
                break
            end
        end
    end

    for name, region_data in pairs(regions_data) do
        local width = region_data.x_max - region_data.x_min
        local height = region_data.y_max - region_data.y_min

        local relative_points_data = {}
        for x, rows in pairs(region_data.points_data) do
            local relative_x = x - region_data.x_min + RegionGap
            relative_points_data[relative_x] = relative_points_data[relative_x] or {}

            for y, data in pairs(rows) do
                local relative_y = y - region_data.y_min + RegionGap
                relative_points_data[relative_x][relative_y] = data
            end
        end

        table.insert(RegionData, {
            name = name,
            width = width + RegionGap * 2,
            height = height + RegionGap * 2,
            relative_points_data = relative_points_data,
        })
    end
end

local function ReBuildMap(map_width, map_height)
    print("Rebuilding map...")

    for x = 0, map_width do
        for y = 0, map_height do
            WorldSim:SetTile(x, y, WORLD_TILES.IMPASSABLE)
        end
    end

    local packed_region_data = Pack(map_width, map_height, RegionData)
    if not packed_region_data  then
        return false
    end

    for _, region_data in ipairs(packed_region_data) do
        local region_name = region_data.name
        local insert_bbox = region_data.insert_bbox

        for relative_x, rows in pairs(region_data.relative_points_data) do
            for relative_y, data in pairs(rows) do
                WorldSim:SetTile(insert_bbox.x + relative_x, insert_bbox.y + relative_y, data.tile)
                -- WorldSim:SetTileNodeId(offest_x + start_x, offest_y + start_y, _data[2])
            end
        end
    end

    return true
end

return {
    RecordMap = RecordMap,
    ReBuildMap = ReBuildMap,
}
