GLOBAL.setfenv(1, GLOBAL)

local bit = bit
local pairs = pairs
local math = math
local table = table

local TILE_SCALE = TILE_SCALE
local WORLD_TILES = WORLD_TILES or {
    IMPASSABLE = 1,
}

local PLACE_MASK = PLACE_MASK or {
    NORMAL = 0,
    IGNORE_IMPASSABLE = 1,
    IGNORE_BARREN = 2,
    IGNORE_IMPASSABLE_BARREN = 3,
    IGNORE_RESERVED = 4,
    IGNORE_IMPASSABLE_RESERVED = 5,
    IGNORE_BARREN_RESERVED = 6,
    IGNORE_IMPASSABLE_BARREN_RESERVED = 7,
}

local LAYOUT_POSITION = LAYOUT_POSITION or {
	RANDOM = 0,
	CENTER = 1,
}

--- task->graph
--- room->node(cell)
---@class NodeData
---@field area number
---@field children table
---@field site table{ x: number, y: number }
---@field site_centroid table{ x: number, y: number }
---@field site_points table{ x: number[], y: number[], map: number[][] }
---@field polygon_vertexs table{ x: number[], y: number[] }
---@type table<string, NodeData>
local NodeDatas = {}

local WorldSim__index = getmetatable(WorldSim).__index
if WorldSim__index.hooked then
    return
end
WorldSim__index.hooked = true

---@param node_id string,
---@param data NodeData
function WorldSim__index:SetNodeData(node_id, data)
    assert(data.area)
    assert(data.site)
    assert(data.site_centroid)
    assert(data.site_points)
    assert(data.polygon_vertexs)

    data.site_points.map = {}
    for i = 1, #data.site_points.x do
        local x = data.site_points.x[i]
        local y = data.site_points.y[i]
        data.site_points.map[x] = data.site_points.map[x] or {}
        data.site_points.map[x][y] = true
    end

    NodeDatas[node_id] = data
end

function WorldSim__index:GetNodeDatas()
    return NodeDatas
end

local _ResetAll = WorldSim__index.ResetAll
function WorldSim__index:ResetAll(...)
    NodeDatas = {}
    return _ResetAll(self, ...)
end

local _GetSiteArea = WorldSim__index.GetSiteArea
---@param node_id string
---@return number
function WorldSim__index:GetSiteArea(node_id)
    local node_data = NodeDatas[node_id]
    if node_data then
        return node_data.area
    end
    return _GetSiteArea(self, node_id)
end

local _GetSite = WorldSim__index.GetSite
--- retrun room(site) center x, y
---@param node_id string
---@return number, number
function WorldSim__index:GetSite(node_id)
    local node_data = NodeDatas[node_id]
    if node_data then
        return node_data.site.x, node_data.site.y
    end
    return _GetSite(self, node_id)
end

local _GetSiteCentroid = WorldSim__index.GetSiteCentroid
---@param node_id string
---@return number, number
function WorldSim__index:GetSiteCentroid(node_id)
    local node_data = NodeDatas[node_id]
    if node_data then
        return node_data.site_centroid.x, node_data.site_centroid.y
    end
    return _GetSiteCentroid(self, node_id)
end

local _GetPointsForSite = WorldSim__index.GetPointsForSite
---@param node_id string
---@param ignore_reserved boolean
---@return number[], number[], number[]
function WorldSim__index:GetPointsForSite(node_id, ignore_reserved)
    local node_data = NodeDatas[node_id]
    if node_data then
        local posints_x = {}
        local posints_y = {}
        local tiles = {}
        for i = 1, #node_data.site_points.x do
            local x = node_data.site_points.x[i]
            local y = node_data.site_points.y[i]
            if not self:IsTileReserved(x, y) or ignore_reserved then
                table.insert(posints_x, x)
                table.insert(posints_y, y)
                table.insert(tiles, self:GetTile(x, y))
            end
        end
        return posints_x, posints_y, tiles
    end
    return _GetPointsForSite(self, node_id, ignore_reserved)
end

local _GetSitePolygon = WorldSim__index.GetSitePolygon
--- Returns the polygon vertexs x, y of the site.
---@param node_id string
---@return number[], number[]
function WorldSim__index:GetSitePolygon(node_id)
    local node_data = NodeDatas[node_id]
    if node_data then
        return node_data.polygon_vertexs.x, node_data.polygon_vertexs.y
    end
    return _GetSitePolygon(self, node_id)
end

local _GetChildrenForSite = WorldSim__index.GetChildrenForSite
---@param node_id string
function WorldSim__index:GetChildrenForSite(node_id)
    local node_data = NodeDatas[node_id]
    if node_data then
        return node_data.children
    end
    return _GetChildrenForSite(self, node_id)
end

local _PointInSite = WorldSim__index.PointInSite
---@param node_id string
---@param x number
---@param y number
---@return boolean
function WorldSim__index:PointInSite(node_id, x, y)
    local node_data = NodeDatas[node_id]
    if node_data then
        x = math.floor(x / TILE_SCALE) * TILE_SCALE
        y = math.floor(y / TILE_SCALE) * TILE_SCALE
        return node_data.site_points.map[x] and node_data.site_points.map[x][y]
    end

    return _PointInSite(self, node_id, x, y)
end

function WorldSim__index:GetSpcaePoint(start_x, start_y, size, fill_points, start_mask, fill_mask)
    local start_ignore_impassable = bit.band(start_mask, PLACE_MASK.IGNORE_IMPASSABLE) == PLACE_MASK.IGNORE_IMPASSABLE
    local start_ignore_barren = bit.band(start_mask, PLACE_MASK.IGNORE_BARREN) == PLACE_MASK.IGNORE_BARREN
    local start_ignore_reserved = bit.band(start_mask, PLACE_MASK.IGNORE_RESERVED) == PLACE_MASK.IGNORE_RESERVED

    local ignore_impassable = bit.band(fill_mask, PLACE_MASK.IGNORE_IMPASSABLE) == PLACE_MASK.IGNORE_IMPASSABLE
    local ignore_barren = bit.band(fill_mask, PLACE_MASK.IGNORE_BARREN) == PLACE_MASK.IGNORE_BARREN
    local ignore_reserved = bit.band(fill_mask, PLACE_MASK.IGNORE_RESERVED) == PLACE_MASK.IGNORE_RESERVED

    local space = { x = {}, y = {} }
    local start_tile = self:GetTile(start_x, start_y)
    local start_reserved = self:IsTileReserved(start_x, start_y)

    if (start_tile == WORLD_TILES.IMPASSABLE and not start_ignore_impassable)
        or (start_reserved and not start_ignore_reserved) then
            return
    end

    for i = 0, size - 1 do
        local x = start_x + i
        for j = 0, size - 1 do
            local y = start_y + j
            if (self:GetTile(x, y) == WORLD_TILES.IMPASSABLE and not ignore_impassable)
                or (self:IsTileReserved(x, y) and not ignore_reserved)
            then
                return
            end
            table.insert(space.x, x)
            table.insert(space.y, y)
        end
    end

    return space
end

local _ReserveSpace = WorldSim__index.ReserveSpace
function WorldSim__index:ReserveSpace(node_id, size, start_mask, fill_mask, layout_position, tiles)
    local node_data = NodeDatas[node_id]
    if node_data then
        local fill_points = node_data.site_points.map

        local spaces = {}
        if layout_position == LAYOUT_POSITION.CENTER then
            local start_x = math.floor(node_data.site.x / TILE_SCALE) * TILE_SCALE
            local start_y = math.floor(node_data.site.y / TILE_SCALE) * TILE_SCALE
            local space = self:GetSpcaePoint(start_x, start_y, size * 2, fill_points, start_mask, fill_mask)
            if space then
                table.insert(spaces, space)
            end
        else
            for start_x, cols in pairs(fill_points) do
                for start_y in pairs(cols) do
                    local space = self:GetSpcaePoint(start_x, start_y, size * 2, fill_points, start_mask, fill_mask)
                    if space then
                        table.insert(spaces, space)
                    end
                end
            end
        end

        if #spaces == 0 then
            return
        end

        local space = spaces[math.random(1, #spaces)]
        for i = 1, #space.x do
            local x = space.x[i]
            local y = space.y[i]
            if tiles[i] ~= 0 then
                self:SetTile(x, y, tiles[i])
            end
            self:ReserveTile(x, y)
        end

        return space.x[1], space.y[1]
    end

    return _ReserveSpace(self, node_id, size, start_mask, fill_mask, layout_position, tiles)
end
