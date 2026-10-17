
local WEST = 1
local NORTH_WEST = 2
local NORTH = 4
local NORTH_EAST = 8
local EAST = 16
local SOUTH_EAST = 32
local SOUTH = 64
local SOUTH_WEST = 128

local function GetKeyForNeighbors(data)
    local neighbors = {}
    for i, dir in ipairs(data) do
        neighbors[dir] = true
    end

    if neighbors[WEST] then
        neighbors[NORTH_WEST] = true
        neighbors[SOUTH_WEST] = true
    end
    if neighbors[NORTH] then
        neighbors[NORTH_WEST] = true
        neighbors[NORTH_EAST] = true
    end
    if neighbors[EAST] then
        neighbors[NORTH_EAST] = true
        neighbors[SOUTH_EAST] = true
    end
    if neighbors[SOUTH] then
        neighbors[SOUTH_WEST] = true
        neighbors[SOUTH_EAST] = true
    end

    local key = 0
    for k, v in pairs(neighbors) do
        key = key + k
    end

    return key
end

local tile_map = {}

local function AddToTileMap(val, data)
    local key = GetKeyForNeighbors(data)
    tile_map[key] = val
end

-- 序号1为完整的地皮

-- 仅有边相邻
AddToTileMap(2, {WEST})
AddToTileMap(3, {NORTH})
AddToTileMap(4, {NORTH, WEST})
AddToTileMap(5, {EAST})
AddToTileMap(6, {EAST, WEST})
AddToTileMap(7, {EAST, NORTH})
AddToTileMap(8, {EAST, NORTH, WEST})
AddToTileMap(9, {SOUTH})
AddToTileMap(10, {SOUTH, WEST})
AddToTileMap(11, {SOUTH, NORTH})
AddToTileMap(12, {SOUTH, NORTH, WEST})
AddToTileMap(13, {SOUTH, EAST})
AddToTileMap(14, {SOUTH, EAST, WEST})
AddToTileMap(15, {SOUTH, EAST, NORTH})
AddToTileMap(16, {SOUTH, EAST, NORTH, WEST})

-- 序号17为完全不相邻
AddToTileMap(17, {})

-- 仅有角相邻
AddToTileMap(18, {NORTH_WEST})
AddToTileMap(19, {NORTH_EAST})
AddToTileMap(20, {NORTH_EAST, NORTH_WEST})
AddToTileMap(21, {SOUTH_EAST})
AddToTileMap(22, {SOUTH_EAST, NORTH_WEST})
AddToTileMap(23, {SOUTH_EAST, NORTH_EAST})
AddToTileMap(24, {SOUTH_EAST, NORTH_EAST, NORTH_WEST})
AddToTileMap(25, {SOUTH_WEST})
AddToTileMap(26, {SOUTH_WEST, NORTH_WEST})
AddToTileMap(27, {SOUTH_WEST, NORTH_EAST})
AddToTileMap(28, {SOUTH_WEST, NORTH_EAST, NORTH_WEST})
AddToTileMap(29, {SOUTH_WEST, SOUTH_EAST})
AddToTileMap(30, {SOUTH_WEST, SOUTH_EAST, NORTH_WEST})
AddToTileMap(31, {SOUTH_WEST, SOUTH_EAST, NORTH_EAST})
AddToTileMap(32, {SOUTH_WEST, SOUTH_EAST, NORTH_EAST, NORTH_WEST})

-- 有1条边和不为0个角相邻
AddToTileMap(33, {NORTH, SOUTH_EAST})
AddToTileMap(34, {EAST, SOUTH_WEST})
AddToTileMap(35, {SOUTH, NORTH_WEST})
AddToTileMap(36, {WEST, NORTH_EAST})
AddToTileMap(37, {NORTH, SOUTH_EAST, SOUTH_WEST})
AddToTileMap(38, {EAST, SOUTH_WEST, NORTH_WEST})
AddToTileMap(39, {SOUTH, NORTH_WEST, NORTH_EAST})
AddToTileMap(40, {WEST, NORTH_EAST, SOUTH_EAST})
AddToTileMap(41, {NORTH, SOUTH_WEST})
AddToTileMap(42, {EAST, NORTH_WEST})
AddToTileMap(43, {SOUTH, NORTH_EAST})
AddToTileMap(44, {WEST, SOUTH_EAST})

-- 有2条边和1个角相邻
AddToTileMap(45, {WEST, NORTH, SOUTH_EAST})
AddToTileMap(46, {NORTH, EAST, SOUTH_WEST})
AddToTileMap(47, {SOUTH, WEST, NORTH_EAST})
AddToTileMap(48, {EAST, SOUTH, NORTH_WEST})

local REGION_RADIUS = 3

local PL_TileSpawner = Class(function(self, inst)
    self.inst = inst
    self.tile_fx = inst

    self.tiles = {}
end)

function PL_TileSpawner:ClearTiles()
    for name, data in pairs(PL_TILE_TYPES) do
        self.tile_fx:ClearTile(data.id)
    end
    self.tiles = {}
    for name, data in pairs(PL_TILE_TYPES) do
        local id = data.id
        self.tiles[id] = {}
    end
end

function PL_TileSpawner:SpawnTiles()
    for i = 1, GetTableSize(PL_TILE_TYPES) do
        local id = i - 1
        local datas = self.tiles[id]
        if datas then
            for _, data in ipairs(datas) do
                self.tile_fx:SpawnTile(data.position, data.overhang_type, id)
            end
        end
        self.tile_fx.VFXEffect:FastForward(id, GetTime())
    end
end

function PL_TileSpawner:OnRemoveEntity()
    self:ClearTiles()
end

PL_TileSpawner.OnRemoveFromEntity = PL_TileSpawner.OnRemoveEntity

local function GetTileVariant(x, z)
    -- 将 x 和 y 组合成一个种子
    local seed = x * 127.1 + z * 311.7

    -- 使用简单的哈希算法生成伪随机值
    local random = math.sin(seed) * 43758.5453
    random = random - math.floor(random) -- 取小数部分

    -- 返回 0 或 1
    if random < 0.5 then
        return 0
    else
        return 1
    end
end

function PL_TileSpawner:UpdateTiles(pt)
    self:ClearTiles()
    if ThePlayer:GetIsInInterior() then
        return
    end
    local tilemanager = ThePlayer.components.pl_tilemanager
    local tilechangewatcher = ThePlayer.components.tilechangewatcher
    local current_tile_center = pt
    for x = -REGION_RADIUS, REGION_RADIUS do
        for z = -REGION_RADIUS, REGION_RADIUS do
            local center = current_tile_center + Vector3(x * TILE_SCALE, 0, z * TILE_SCALE)
            local grid_x, grid_z = TheWorld.Map:GetTileCoordsAtPoint(center.x, center.y, center.z)
            if not TheWorld.Map:CheckInSize(grid_x, grid_z) then -- 在地图边界外

            elseif tilemanager.cached_visual:GetDataAtPoint(grid_x, grid_z) then -- 使用缓存的数据
                for i, v in ipairs(tilemanager.cached_visual:GetDataAtPoint(grid_x, grid_z)) do
                    table.insert(self.tiles[v.id], v.data)
                end
            else
                local visual_datas = {}
                local tile = tilechangewatcher:GetCachedTile(grid_x, grid_z)
                if tile then
                    if PL_TILE_TYPES[tile] then
                        if self.tiles[PL_TILE_TYPES[tile].id] == nil then
                            self.tiles[PL_TILE_TYPES[tile].id] = {}
                        end
                        local data = {
                            position = Vector3(center.x, center.y, center.z),
                            overhang_type = 1,
                        }
                        table.insert(self.tiles[PL_TILE_TYPES[tile].id], data)

                        table.insert(visual_datas, {id = PL_TILE_TYPES[tile].id, data = data})
                        -- self.tile_fx:SpawnTile(center, 1, PL_TILE_TYPES[tile].id)
                    end

                    local neighbor_datas = {}
                    for dir, v in pairs(PL_NEIGHBOR_TILES) do
                        if TheWorld.Map:CheckInSize(grid_x + v.x, grid_z + v.z) then
                            local adjacent_tile = tilechangewatcher:GetCachedTile(grid_x + v.x, grid_z + v.z)
                            if PL_TILE_TYPES[adjacent_tile] then
                                if neighbor_datas[adjacent_tile] == nil then
                                    neighbor_datas[adjacent_tile] = {}
                                end
                                table.insert(neighbor_datas[adjacent_tile], dir)
                            end
                        end
                    end

                    for tile_type, data in pairs(neighbor_datas) do
                        if tile ~= tile_type then
                            local key = GetKeyForNeighbors(data)

                            if key > 0 then
                                local value = tile_map[key]
                                if value < 17 then
                                    value = value + GetTileVariant(center.x, center.z) * 48 -- 随机变体
                                end
                                if self.tiles[PL_TILE_TYPES[tile_type].id] == nil then
                                    self.tiles[PL_TILE_TYPES[tile_type].id] = {}
                                end

                                local data = {
                                    position = Vector3(center.x, center.y, center.z),
                                    overhang_type = value,
                                }
                                table.insert(self.tiles[PL_TILE_TYPES[tile_type].id], data)

                                table.insert(visual_datas, {id = PL_TILE_TYPES[tile_type].id, data = data})

                                -- self.tile_fx:SpawnTile(center, value or 1, PL_TILE_TYPES[tile_type].id)
                            end
                        end
                    end
                end
                tilemanager.cached_visual:SetDataAtPoint(grid_x, grid_z, visual_datas)
            end
        end
    end
    self:SpawnTiles()
end

return PL_TileSpawner
