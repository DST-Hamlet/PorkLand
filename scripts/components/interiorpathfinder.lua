local STATUS_CALCULATING = 0 -- 复制自components/locomotor.lua
local STATUS_FOUNDPATH = 1
local STATUS_NOPATH = 2

local Blockers = {
    Wall = 1,
}



-- 检查坐标是否在室内地图范围内
local function IsInBounds(x, y, map, width, depth)
    return x >= 1 and x <= depth and y >= 1 and y <= width
end

-- 检查路径是否没有障碍
local function IsClearPath(start_x, start_y, end_x, end_y, map, width, depth, ignorewalls)
    -- 使用简单的直线插值检查路径上的每个点
    local dx = end_x - start_x
    local dy = end_y - start_y
    local steps = math.max(math.abs(dx), math.abs(dy))

    local x_step = dx / steps
    local y_step = dy / steps

    local x = start_x
    local y = start_y

    for i = 0, steps do
        local ix = math.floor(x + 0.5)
        local iy = math.floor(y + 0.5)

        if not IsInBounds(ix, iy, map, width, depth) or (not ignorewalls and map[ix] and map[ix][iy] and map[ix][iy] == Blockers.Wall) then
            -- print("point is not clear!!!!!", ix, iy)
            return false
        end

        -- 检查对角线方向的阻挡
        if i > 0 then
            local prev_ix = math.floor(x - x_step + 0.5)
            local prev_iy = math.floor(y - y_step + 0.5)
            if (ix ~= prev_ix and iy ~= prev_iy) and
               ((map[ix] and map[ix][prev_iy] and map[ix][prev_iy] == Blockers.Wall) or
                (map[prev_ix] and map[prev_ix][iy] and map[prev_ix][iy] == Blockers.Wall)) then
                -- print("diagonal point is not clear!!!!!", ix, iy)
                return false
            end
        end

        x = x + x_step
        y = y + y_step
    end
    -- print("clear!!!!!", start_x, start_y)
    return true
end

local function CreateNode(x, y, g, h, parent)
    local node = {
        x = tonumber(x), -- 节点坐标位置, 加tonumber是为了避免一个曾经发生过的罕见的报错
        y = tonumber(y),
        g = 0, -- 节点离开始节点的网格路程距离
        h = 0, -- 节点离开始节点的最短网格距离
        f = g + h, -- 整条寻路的估计长度
        parent = parent -- 上一个节点的坐标位置
    }
    return node
end

local function GetGridDist(node, goal) -- 计算两个网格之间的距离
    return math.abs(node.x - goal.x) + math.abs(node.y - goal.y)
end

-- Get neighbors of a node
local function get_neighbors(node, grid, width, depth, ignorewalls)
    local neighbors = {}
    local directions = {
        {1, 0}, {-1, 0}, {0, 1}, {0, -1}
    }
    for _, dir in ipairs(directions) do
        local nx, ny = node.x + dir[1], node.y + dir[2]
        if not ignorewalls and IsInBounds(nx, ny, grid, width, depth) and not (grid[nx] and grid[nx][ny] and grid[nx][ny] == Blockers.Wall) then
            table.insert(neighbors, CreateNode(nx, ny, 0, 0, node))
        end
    end
    return neighbors
end

-- Check if a node is in a set
local function is_in_set(set, node)
    for _, n in ipairs(set) do
        if n.x == node.x and n.y == node.y then
            return true
        end
    end
    return false
end

-- A* algorithm
local function a_star(start, goal, grid, width, depth, ignorewalls) -- 亚丹：A星寻路算法
    local open_set = {start}
    local closed_set = {}

    local max_search_times = 512

    while #open_set > 0 and max_search_times > 0 do
        max_search_times = max_search_times - 1
        -- Find the node with the lowest f score
        table.sort(open_set, function(a, b) return a.f < b.f end)
        local current = table.remove(open_set, 1)

        -- If the goal is reached, reconstruct the path
        if current.x == goal.x and current.y == goal.y then
            local path = {}
            while current do
                table.insert(path, 1, {current.x, current.y})
                current = current.parent
            end
            -- print("searchtimes", 512 - max_search_times)
            return path
        end

        table.insert(closed_set, current)

        -- Get neighbors
        local neighbors = get_neighbors(current, grid, width, depth, ignorewalls)
        for _, neighbor in ipairs(neighbors) do
            -- If the neighbor is in the closed set, skip it
            if not is_in_set(closed_set, neighbor) then

                -- Calculate g, h, and f scores
                neighbor.g = current.g + 1
                neighbor.h = GetGridDist(neighbor, goal)
                neighbor.f = neighbor.g + neighbor.h

                -- If the neighbor is in the open set with a higher g score, skip it
                if not is_in_set(open_set, neighbor) then
                    table.insert(open_set, neighbor)
                end
            end
        end
    end

    return nil -- No path found
end

-- Smooth the path by removing unnecessary nodes
local function smooth_path(path, grid, width, depth, ignorewalls) -- 用于简化A星算法生成的寻路节点
    if #path <= 2 then
        return path
    end

    local smoothed_path = {path[1]}
    local last_point = path[1]

    for i = 2, #path do
        local current_point = path[i]
        if not IsClearPath(last_point[1], last_point[2], current_point[1], current_point[2], grid, width, depth, ignorewalls) then
            table.insert(smoothed_path, path[i - 1])
            last_point = path[i - 1]
        end
    end

    table.insert(smoothed_path, path[#path])
    return smoothed_path
end





local InteriorPathfinder = Class(function(self, inst)
    self.inst = inst
    self.interior_physicswall = {}
end, nil)

-- TODO: Remove this
function InteriorPathfinder:GetWidth()
    return self.inst:GetWidth()
end

-- TODO: Remove this
function InteriorPathfinder:GetDepth()
    return self.inst:GetDepth()
end

function InteriorPathfinder:PopulateRoom()
    --[[
    for i = 1, self:GetDepth() do
        if self.interior_physicswall[i] == nil then
            self.interior_physicswall[i] = {}
        end
        for j = 1, self:GetWidth() do
            if self.interior_physicswall[i][j] == nil then
                self.interior_physicswall[i][j] = nil
            end
        end
    end
    --]]
end

function InteriorPathfinder:WorldPositionToLocal(x, y, z)
    local ix, _, iz = self.inst.Transform:GetWorldPosition()
    local _x = math.floor(x - ix + self:GetDepth() / 2 + 1)
    local _z = math.floor(z - iz + self:GetWidth() / 2 + 1)
    return _x, 0, _z
end

function InteriorPathfinder:LocalPositionToWorld(x, y, z)
    local ix, _, iz = self.inst.Transform:GetWorldPosition()
    local _x = ix + x - 1 - self:GetDepth() / 2 + 0.5 -- 0.5代表墙的碰撞位置和坐标位置的差
    local _z = iz + z - 1 - self:GetWidth() / 2 + 0.5
    return _x, 0, _z
end

function InteriorPathfinder:AddWall(x, y, z) -- 并未考虑室内大小的动态变化
    local _x, _, _z = self:WorldPositionToLocal(x, y, z)
    if self.interior_physicswall[_x] == nil then
        self.interior_physicswall[_x] = {}
    end
    self.interior_physicswall[_x][_z] = Blockers.Wall
    -- print("AddWall to interior",_x,_z)
end

function InteriorPathfinder:RemoveWall(x, y, z)
    local _x, _, _z = self:WorldPositionToLocal(x, y, z)
    if self.interior_physicswall[_x] == nil then
        self.interior_physicswall[_x] = {}
    end
    self.interior_physicswall[_x][_z] = 0
    -- print("RemoveWall to interior",_x,_z)
end

function InteriorPathfinder:HasWall(x, y, z)
    local _x, _, _z = self:WorldPositionToLocal(x, y, z)
    if self.interior_physicswall[_x] == nil then
        self.interior_physicswall[_x] = {}
    end
    return self.interior_physicswall[_x][_z]
end

function InteriorPathfinder:IsClear(x, y, z, tx, ty, tz, data) -- 检测两点之间的直线寻路是否有阻挡
    local _x, _, _z = self:WorldPositionToLocal(x, y, z)
    local _tx, _, _tz = self:WorldPositionToLocal(tx, ty, tz)
    local ignorewalls = data and data.ignorewalls
    return IsClearPath(_x, _z, _tx, _tz, self.interior_physicswall, self:GetWidth(), self:GetDepth(), ignorewalls)
end

function InteriorPathfinder:CalculateSearch(x, y, z, tx, ty, tz, data) -- 计算寻路
    local isclear = self:IsClear(x, y, z, tx, ty, tz, data)
    if isclear then
        return {
            isinterior = true,
            path = {steps = {}},
            status = STATUS_NOPATH,
        }
    end
    local _x, _, _z = self:WorldPositionToLocal(x, y, z)
    local start = CreateNode(_x, _z, 0, 0, nil) -- 开始位置
    local _tx, _, _tz = self:WorldPositionToLocal(tx, ty, tz)
    local goal = CreateNode(_tx, _tz, 0, 0, nil) -- 目标位置
    local ignorewalls = data and data.ignorewalls
    local calcupath = a_star(start, goal, self.interior_physicswall, self:GetWidth(), self:GetDepth(), ignorewalls)
    local search = {
        isinterior = true,
        path = {steps = {}},
        status = STATUS_CALCULATING,
    }
    if calcupath then
        local smoothed_path = smooth_path(calcupath, self.interior_physicswall, self:GetWidth(), self:GetDepth(), ignorewalls)
        for i, v in ipairs(smoothed_path) do
            search.path.steps[i] = Vector3(self:LocalPositionToWorld(v[1],0,v[2])) -- 记录寻路路径上的所有节点
        end
        search.status = STATUS_FOUNDPATH
    else
        search.status = STATUS_NOPATH -- 寻路失败
    end
    return search
end

return InteriorPathfinder
