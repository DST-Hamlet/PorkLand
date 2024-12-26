GLOBAL.setfenv(1, GLOBAL)

-- ResetAll	function
-- GetPointsForSite	function
-- GetChildrenForSite	function
-- GetRandomPointsForSite	function

-- GetPointsForMetaMaze	function
-- SetSiteFlags	function

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
    if NodeDatas[node_id] then
        return NodeDatas[node_id].area
    end
    return _GetSiteArea(self, node_id)
end

local _GetSite = WorldSim__index.GetSite
--- retrun room(site) center x, y
---@param node_id string
---@return number, number
function WorldSim__index:GetSite(node_id)
    if NodeDatas[node_id] then
        return NodeDatas[node_id].site.x, NodeDatas[node_id].site.y
    end
    return _GetSite(self, node_id)
end

local _GetSiteCentroid = WorldSim__index.GetSiteCentroid
---@param node_id string
---@return number[], number[]
function WorldSim__index:GetSiteCentroid(node_id)
    if NodeDatas[node_id] then
        return NodeDatas[node_id].site_centroid.x, NodeDatas[node_id].site_centroid.y
    end
    return _GetSiteCentroid(self, node_id)
end

local _GetPointsForSite = WorldSim__index.GetPointsForSite
---@param node_id string
---@return number[], number[], number[]
function WorldSim__index:GetPointsForSite(node_id)
    if NodeDatas[node_id] then
        return NodeDatas[node_id].site_points.x, NodeDatas[node_id].site_points.y, NodeDatas[node_id].site_points.tiles
    end
    return _GetPointsForSite(self, node_id)
end

local _GetSitePolygon = WorldSim__index.GetSitePolygon
--- Returns the polygon vertexs x, y of the site.
---@param node_id string
---@return number[], number[]
function WorldSim__index:GetSitePolygon(node_id)
    if NodeDatas[node_id] then
        return NodeDatas[node_id].polygon_vertexs.x, NodeDatas[node_id].polygon_vertexs.y
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

local _ReserveTile = WorldSim__index.ReserveTile
---@param x number
---@param y number
---@return boolean
function WorldSim__index:ReserveTile(x, y)
    return _ReserveTile(self, x, y)
end
