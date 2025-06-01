
local Pack = require("main/packer")

local RegionGap = 10

local RegionDatas = {}

local function RemoveNode(parent, node)
    local removed = false
    if parent.nodes then
        for id, v in pairs(parent.nodes) do
            if node == v then
                parent.nodes[id] = nil
                removed = true
            end
            if RemoveNode(v, node) then
                removed = true
            end
        end
    end

    if parent.children then
        for id, child in pairs(parent.children) do
            if node == child then
                parent:RemoveChild(id)
                removed = true
            end
            if RemoveNode(child, node) then
                removed = true
            end
        end
    end

    return removed
end

local function RecordMap(topology_save)
    RegionDatas = {}

    local region_datas = {
        island_accademy = { node_datas = {} },
        island_royal = { node_datas = {} },
        island_pugalisk = { node_datas = {} },
        island_BFB = { node_datas = {} },
        island_ancient = { node_datas = {} },
    }

    local nodes = topology_save.root:GetNodes(true)
    for _, node in pairs(nodes) do
        for _, tag in pairs(node.data.tags) do
            local region_data = region_datas[tag]
            if region_data then
                node.region = tag
                local points_x, points_y, points_type = WorldSim:GetPointsForSite(node.id)
                for i = 1, #points_x do
                    local x, y = points_x[i], points_y[i]
                    region_data.x_max = math.max(region_data.x_max or 0, x)
                    region_data.x_min = math.min(region_data.x_min or math.huge, x)
                    region_data.y_max = math.max(region_data.y_max or 0, y)
                    region_data.y_min = math.min(region_data.y_min or math.huge, y)
                end
                table.insert(region_data.node_datas, {
                    node = node,
                    points = { x = points_x, y = points_y, type = points_type },
                })
                break
            end
        end

        if not node.region then
            local removed = RemoveNode(topology_save.root, node)
            assert(removed, "Node not found in topology")
        end
    end

    for name, region_data in pairs(region_datas) do
        local width = region_data.x_max - region_data.x_min + RegionGap * 2
        local height = region_data.y_max - region_data.y_min + RegionGap * 2
        local region_x = region_data.x_min - math.floor(RegionGap / 2)
        local region_y = region_data.y_min - math.floor(RegionGap / 2)

        for _, node_data in ipairs(region_data.node_datas) do
            local node = node_data.node
            local area = WorldSim:GetSiteArea(node.id)
            local site_x, site_y = WorldSim:GetSite(node.id)
            local centroid_x, centroid_y = WorldSim:GetSiteCentroid(node.id)
            local polygon_vertexs_x, polygon_vertexs_y = WorldSim:GetSitePolygon(node.id)

            node_data.area = area
            node_data.relative_site = { x = site_x - region_x, y = site_y - region_y }
            node_data.relative_centroid = { x = centroid_x - region_x, y = centroid_y - region_y }
            node_data.relative_polygon_vertexs = {}
            node_data.relative_points = {}

            for i = 1, #polygon_vertexs_x do
                table.insert(node_data.relative_polygon_vertexs, {
                    x = polygon_vertexs_x[i] - region_x,
                    y = polygon_vertexs_y[i] - region_y,
                })
            end

            for i = 1, #node_data.points.x do
                table.insert(node_data.relative_points, {
                    x = node_data.points.x[i] - region_x,
                    y = node_data.points.y[i] - region_y,
                    tile = node_data.points.type[i],
                })
            end
        end

        table.insert(RegionDatas, {
            name = name,
            width = width,
            height = height,
            node_datas = region_data.node_datas,
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

    local packed_region_datas = Pack(map_width, map_height, RegionDatas)
    if not packed_region_datas then
        print("PANIC: Failed to pack regions")
        return false
    end

    for _, region_data in ipairs(packed_region_datas) do
        local region_name = region_data.name
        local insert_bbox = {
            x = math.floor(region_data.insert_bbox.x),
            y = math.floor(region_data.insert_bbox.y),
        }

        for _, node_data in ipairs(region_data.node_datas) do
            local node = node_data.node
            local site_x = node_data.relative_site.x + insert_bbox.x
            local site_y = node_data.relative_site.y + insert_bbox.y
            local centroid_x = node_data.relative_centroid.x + insert_bbox.x
            local centroid_y = node_data.relative_centroid.y + insert_bbox.y

            local data = {
                area = node_data.area,
                site = { x = site_x, y = site_y } ,
                site_centroid = { x = centroid_x, y = centroid_y },
                site_points = { x = {}, y = {} },
                polygon_vertexs = { x = {}, y = {} },
                children = WorldSim:GetChildrenForSite(node.id)
            }

            for _, relative_vertex in ipairs(node_data.relative_polygon_vertexs) do
                table.insert(data.polygon_vertexs.x, relative_vertex.x + insert_bbox.x)
                table.insert(data.polygon_vertexs.y, relative_vertex.y + insert_bbox.y)
            end

            for _, relative_point in ipairs(node_data.relative_points) do
                local x = insert_bbox.x + relative_point.x
                local y = insert_bbox.y + relative_point.y
                WorldSim:SetTile(x, y, relative_point.tile)
                table.insert(data.site_points.x, x)
                table.insert(data.site_points.y, y)
            end
            WorldSim:SetNodeData(node.id, data)
        end
    end

    return true
end

return {
    RecordMap = RecordMap,
    ReBuildMap = ReBuildMap,
}
