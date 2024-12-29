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


-- ResetAll    function
-- GetPointsForSite    function
-- GetChildrenForSite    function
-- GetRandomPointsForSite    function

-- GetPointsForMetaMaze    function
-- SetSiteFlags    function

--- task->graph
--- room->node(cell)
---@class NodeData
---@field area number
---@field site table{ x: number, y: number }
---@field site_centroid table{ x: number, y: number }
---@field site_points table{ x: number[], y: number[] }
---@field polygon_vertexs table{ x: number[], y: number[], tiles: number[] }
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
    NodeDatas[node_id] = data
end

function WorldSim__index:ClearNodeData()
    NodeDatas = {}
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
---@return number[], number[]
function WorldSim__index:GetSiteCentroid(node_id)
    local node_data = NodeDatas[node_id]
    if node_data then
        return node_data.site_centroid.x, node_data.site_centroid.y
    end
    return _GetSiteCentroid(self, node_id)
end

local _GetPointsForSite = WorldSim__index.GetPointsForSite
---@param node_id string
---@return number[], number[], number[]
function WorldSim__index:GetPointsForSite(node_id)
    local node_data = NodeDatas[node_id]
    if node_data then
        local tiles = {}
        for i = 1, #node_data.site_points.x do
            table.insert(tiles, self:GetTile(node_data.site_points.x[i], node_data.site_points.y[i]))
        end
        return node_data.site_points.x, node_data.site_points.y, tiles
    end
    return _GetPointsForSite(self, node_id)
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

local _PointInSite = WorldSim__index.PointInSite
---@param node_id string
---@param x number
---@param y number
---@return boolean
function WorldSim__index:PointInSite(node_id, x, y)
    return _PointInSite(self, node_id, x, y)
end

local function GetSpcae(x, y, size, site_points)
    local space = { x = {}, y = {} }
    for i = 0, size - 1 do
        for j = 0, size - 1 do
            if not site_points[x + i] or not site_points[x + i][y + j] then
                return
            end
            table.insert(space.x, x + i)
            table.insert(space.y, y + j)
        end
    end

    return space
end

local _ReserveSpace = WorldSim__index.ReserveSpace
---@param node_id string
---@param size number
---@return boolean
function WorldSim__index:ReserveSpace(node_id, size, start_mask, fill_mask, layout_position, tiles)
    local node_data = NodeDatas[node_id]
    if node_data then
        local start_ignore_impassable = bit.band(start_mask, PLACE_MASK.IGNORE_IMPASSABLE) == PLACE_MASK.IGNORE_IMPASSABLE
        local start_ignore_barren = bit.band(start_mask, PLACE_MASK.IGNORE_BARREN) == PLACE_MASK.IGNORE_BARREN
        local start_ignore_reserved = bit.band(start_mask, PLACE_MASK.IGNORE_RESERVED) == PLACE_MASK.IGNORE_RESERVED

        local ignore_impassable = bit.band(fill_mask, PLACE_MASK.IGNORE_IMPASSABLE) == PLACE_MASK.IGNORE_IMPASSABLE
        local ignore_barren = bit.band(fill_mask, PLACE_MASK.IGNORE_BARREN) == PLACE_MASK.IGNORE_BARREN
        local ignore_reserved = bit.band(fill_mask, PLACE_MASK.IGNORE_RESERVED) == PLACE_MASK.IGNORE_RESERVED

        local site_points = {}

        -- if layout_position == LAYOUT_POSITION.CENTER then
        -- else
            for i = 1, #node_data.site_points.x do
                local x = node_data.site_points.x[i]
                local y = node_data.site_points.y[i]
                local tile = self:GetTile(x, y)
                local reserved = self:IsTileReserved(x, y)

                if (tile ~= WORLD_TILES.IMPASSABLE or ignore_impassable)
                    and (not reserved or ignore_reserved)
                then
                    site_points[x] = site_points[x] or {}
                    site_points[x][y] = { tile = tile, reserved = reserved }
                end
            end
        -- end

        local spaces = {}
        for x, cols in pairs(site_points) do
            for y, data in pairs(cols) do
                local tile = data.tile
                if (tile ~= WORLD_TILES.IMPASSABLE or start_ignore_impassable)
                    and (data.reserved or start_ignore_reserved)
                then
                    local space = GetSpcae(x, y, size, site_points)
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
