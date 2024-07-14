local STATUS_CALCULATING = 0 -- 复制自components/locomotor.lua
local STATUS_FOUNDPATH = 1
local STATUS_NOPATH = 2

local Blocker_Wall = 1

local function CreateNode(x, y, g, h, parent)
    local node = {
        x = x, -- 节点坐标位置
        y = y,
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
local function get_neighbors(node, grid)
    local neighbors = {}
    local directions = {
        {1, 0}, {-1, 0}, {0, 1}, {0, -1}
    }
    for _, dir in ipairs(directions) do
        local nx, ny = node.x + dir[1], node.y + dir[2]
        if grid[nx] and grid[nx][ny] and grid[nx][ny] == 0 then
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
local function a_star(start, goal, grid) -- 亚丹：GPT写的，因为我菜
    local open_set = {start}
    local closed_set = {}

    while #open_set > 0 do
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
            return path
        end

        table.insert(closed_set, current)

        -- Get neighbors
        local neighbors = get_neighbors(current, grid)
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

-- Example usage
local grid = {
    {0, 0, 0, 0, 0},
    {0, 1, 1, 1, 0},
    {0, 0, 0, 1, 0},
    {0, 1, 0, 0, 0},
    {0, 0, 0, 0, 0}
}

local start = CreateNode(1, 1, 0, 0, nil)
local goal = CreateNode(5, 5, 0, 0, nil)

local path = a_star(start, goal, grid)
if path then
    for _, p in ipairs(path) do
        print("Path: (" .. p[1] .. ", " .. p[2] .. ")")
    end
else
    print("No path found")
end

local InteriorPathfinder = Class(function(self, inst)
    self.inst = inst
    self.interior_physicswall = {}
end, nil)

function InteriorPathfinder:GetWidth()
    return self.inst.width
end

function InteriorPathfinder:GetDepth()
    return self.inst.depth
end

function InteriorPathfinder:PopulateRoom()
    for i = 1, self.inst.depth do
        if self.interior_physicswall[i] == nil then
            self.interior_physicswall[i] = {}
        end
        for j = 1, self.inst.width do
            if self.interior_physicswall[i][j] == nil then
                self.interior_physicswall[i][j] = 0
            end
        end
    end
end

function InteriorPathfinder:WorldPositionToLocal(x, y, z)
    local ix, iy, iz = self.inst.Transform:GetWorldPosition()
    local _x = math.floor(x - ix + self:GetDepth() / 2)
    local _z = math.floor(z - iz + self:GetWidth() / 2)
    return _x, 0, _z
end

function InteriorPathfinder:LocalPositionToWorld(x, y, z)
    local ix, iy, iz = self.inst.Transform:GetWorldPosition()
    local _x = ix + x - self:GetDepth() / 2 + 0.5 -- 0.5代表墙的碰撞位置和坐标位置的差
    local _z = iz + z - self:GetWidth() / 2 + 0.5
    return _x, 0, _z
end

function InteriorPathfinder:AddWall(x, y, z) -- 并未考虑室内大小的动态变化
    local _x, _y, _z = self:WorldPositionToLocal(x, y, z)
    if self.interior_physicswall[_x] == nil then
        self.interior_physicswall[_x] = {}
    end
    self.interior_physicswall[_x][_z] = Blocker_Wall
    print("AddWall to interior",_x,_z)
end

function InteriorPathfinder:RemoveWall(x, y, z)
    local _x, _y, _z = self:WorldPositionToLocal(x, y, z)
    if self.interior_physicswall[_x] == nil then
        self.interior_physicswall[_x] = {}
    end
    self.interior_physicswall[_x][_z] = 0
    print("RemoveWall to interior",_x,_z)
end

function InteriorPathfinder:HasWall(x, y, z)
    local _x, _y, _z = self:WorldPositionToLocal(x, y, z)
    if self.interior_physicswall[_x] == nil then
        self.interior_physicswall[_x] = {}
    end
    return self.interior_physicswall[_x][_z]
end

function InteriorPathfinder:IsClear(x, y, z, tx, ty, tz, data) -- 检测两点之间的直线寻路是否有阻挡
    return false
end

function InteriorPathfinder:CalculateSearch(x, y, z, tx, ty, tz, data) -- 计算寻路
    print("CalculateSearch!!!!!")
    local _x, _y, _z = self:WorldPositionToLocal(x, y, z)
    print("start pos:",_x,_z)
    local start = CreateNode(_x, _z, 0, 0, nil)
    local _tx, _ty, _tz = self:WorldPositionToLocal(tx, ty, tz)
    local goal = CreateNode(_tx, _tz, 0, 0, nil)
    print("goal pos:",_tx,_tz)
    local calcupath = a_star(start, goal, self.interior_physicswall)
    local search = {
        isinterior = true,
        path = {steps = {}},
        status = STATUS_CALCULATING,
    }
    if calcupath then
        for i, v in ipairs(calcupath) do
            search.path.steps[i] = Vector3(self:LocalPositionToWorld(v[1],0,v[2]))
            print("node",i,"x:",v[1],"z:",v[2])
        end
        search.status = STATUS_FOUNDPATH
    else
        search.status = STATUS_NOPATH
        print("path search fail!!!!!")
    end
    return search
end

return InteriorPathfinder
