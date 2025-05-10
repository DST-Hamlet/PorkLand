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
    if not IsInBounds(start_x, start_y, map, width, depth) then
        return false, true
    end
    if not IsInBounds(start_x, start_y, map, width, depth) then
        return false, true
    end
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

        if not IsInBounds(ix, iy, map, width, depth) or ((not ignorewalls) and map[ix] and map[ix][iy] and map[ix][iy] == Blockers.Wall) then
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

local function create_min_heap()
    return {
        data = {},
        size = 0,
        push = function(self, item)
            self.size = self.size + 1
            self.data[self.size] = item
            self:bubble_up(self.size)
        end,
        pop = function(self)
            if self.size == 0 then return nil end
            local result = self.data[1]
            self.data[1] = self.data[self.size]
            self.data[self.size] = nil
            self.size = self.size - 1
            if self.size > 0 then
                self:bubble_down(1)
            end
            return result
        end,
        bubble_up = function(self, index)
            local parent = math.floor(index / 2)
            while index > 1 and self.data[parent].f > self.data[index].f do
                self.data[parent], self.data[index] = self.data[index], self.data[parent]
                index = parent
                parent = math.floor(index / 2)
            end
        end,
        bubble_down = function(self, index)
            local smallest = index
            while true do
                local left = 2 * index
                local right = 2 * index + 1
                if left <= self.size and self.data[left].f < self.data[smallest].f then
                    smallest = left
                end
                if right <= self.size and self.data[right].f < self.data[smallest].f then
                    smallest = right
                end
                if smallest == index then break end
                self.data[index], self.data[smallest] = self.data[smallest], self.data[index]
                index = smallest
            end
        end
    }
end

-- 优化2: 使用哈希表来加速节点查找
local function create_node_set()
    return {
        data = {},
        add = function(self, node)
            local key = node.x .. "," .. node.y
            self.data[key] = node
        end,
        contains = function(self, node)
            local key = node.x .. "," .. node.y
            return self.data[key] ~= nil
        end,
        get = function(self, node)
            local key = node.x .. "," .. node.y
            return self.data[key]
        end
    }
end

-- 优化后的A*算法
local function a_star(start, goal, grid, width, depth, ignorewalls)
    local open_set = create_min_heap()
    local closed_set = create_node_set()
    local open_set_hash = create_node_set()

    open_set:push(start)
    open_set_hash:add(start)

    local max_search_times = 512

    while open_set.size > 0 and max_search_times > 0 do
        max_search_times = max_search_times - 1

        local current = open_set:pop()
        open_set_hash.data[current.x .. "," .. current.y] = nil

        if current.x == goal.x and current.y == goal.y then
            local path = {}
            while current do
                table.insert(path, 1, {current.x, current.y})
                current = current.parent
            end
            return path
        end

        closed_set:add(current)

        local neighbors = get_neighbors(current, grid, width, depth, ignorewalls)
        for _, neighbor in ipairs(neighbors) do
            if not closed_set:contains(neighbor) then
                local tentative_g = current.g + 1

                local neighbor_in_open = open_set_hash:get(neighbor)
                if neighbor_in_open then
                    if tentative_g < neighbor_in_open.g then
                        neighbor_in_open.g = tentative_g
                        neighbor_in_open.f = tentative_g + neighbor_in_open.h
                        neighbor_in_open.parent = current
                    end
                else
                    neighbor.g = tentative_g
                    neighbor.h = GetGridDist(neighbor, goal)
                    neighbor.f = neighbor.g + neighbor.h
                    neighbor.parent = current
                    open_set:push(neighbor)
                    open_set_hash:add(neighbor)
                end
            end
        end
    end

    return nil
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

local function _distsq(x, y, z, x1, y1, z1)
    local dx = x1 - x
    local dy = y1 - y
    local dz = z1 - z
    --Note: Currently, this is 3D including y-component
    return dx * dx + dy * dy + dz * dz
end

function InteriorPathfinder:CalculateSearch(x, y, z, tx, ty, tz, data) -- 计算寻路
    if _distsq(x, y, z, tx, ty, tz) <= 1 then
        return {
            isinterior = true,
            path = {steps = {}},
            status = STATUS_NOPATH,
        }
    end

    local isclear, cantfindpath = self:IsClear(x, y, z, tx, ty, tz, data)
    if isclear or cantfindpath then
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
