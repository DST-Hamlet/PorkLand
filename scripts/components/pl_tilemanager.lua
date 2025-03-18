-- PLAYER_CAMERA_SEE_DISTANCE (40) / TILE_SCALE (4) = 10
local REFRESH_RADIUS = (PLAYER_CAMERA_SEE_DISTANCE / TILE_SCALE) + 5

local PL_TileManager = Class(function(self, inst)
    self.inst = inst

    self.tiletest = SpawnPrefab("tile_fx")

    self.inst.components.tilechangewatcher:ListenToUpdate(function()
        self:UpdateTiles()
    end)
end)

function PL_TileManager:ClearTiles()
    self.tiletest.VFXEffect:ClearAllParticles(0)
end

function PL_TileManager:SpawnTiles()

end

function PL_TileManager:OnRemoveEntity()
    self:ClearTiles()
end

PL_TileManager.OnRemoveFromEntity = PL_TileManager.OnRemoveEntity

local WEST = 1
local NORTH_WEST = 2
local NORTH = 4
local NORTH_EAST = 8
local EAST = 16
local SOUTH_EAST = 32
local SOUTH = 64
local SOUTH_WEST = 128

local NEIGHBOR_TILES = {
    [WEST]       = {x = -1, z =  0},
    [NORTH_WEST] = {x = -1, z =  1},
    [NORTH]      = {x =  0, z =  1},
    [NORTH_EAST] = {x =  1, z =  1},
    [EAST]       = {x =  1, z =  0},
    [SOUTH_EAST] = {x =  1, z = -1},
    [SOUTH]      = {x =  0, z = -1},
    [SOUTH_WEST] = {x = -1, z = -1},
}

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

tile_map = {}

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

-- 有1条边和1个角相邻
AddToTileMap(45, {WEST, NORTH, SOUTH_EAST})
AddToTileMap(46, {NORTH, EAST, SOUTH_WEST})
AddToTileMap(47, {EAST, SOUTH, NORTH_WEST})
AddToTileMap(48, {SOUTH, WEST, NORTH_EAST})

local function GetTileVariant(x, z) -- TODO:减少连续性
    local hash = x * 73856093
    hash = bit.bxor(hash, z * 19349663)
    hash = bit.bxor(hash, (x + z) * 83492791)
    hash = bit.bxor(hash, bit.lshift(hash, 13))
    hash = bit.bxor(hash, bit.rshift(hash, 7))
    hash = hash > 0 and hash or -hash
    return (hash % 2)
end

function PL_TileManager:UpdateTiles()
    self:ClearTiles()
    local current_tile_center = self.inst.components.tilechangewatcher.last_tile_center
    for x = -REFRESH_RADIUS, REFRESH_RADIUS do
        for z = -REFRESH_RADIUS, REFRESH_RADIUS do
            local center = current_tile_center + Vector3(x * TILE_SCALE, 0, z * TILE_SCALE)
            local tile = TheWorld.Map:GetTileAtPoint(center.x, center.y, center.z)
            if tile then
                if tile == WORLD_TILES.LILYPOND then
                    self.tiletest:SpawnTile(center, 1)
                else
                    local neighbor_data = {}
                    for dir, v in pairs(NEIGHBOR_TILES) do
                        local adjacent_tile = TheWorld.Map:GetTileAtPoint(center.x + v.x * TILE_SCALE, center.y, center.z + v.z * TILE_SCALE)
                        if adjacent_tile == WORLD_TILES.LILYPOND then
                            table.insert(neighbor_data, dir)
                        end
                    end

                    local key = GetKeyForNeighbors(neighbor_data)

                    if key > 0 then
                        local value = tile_map[key]
                        if value < 17 then
                            value = value + GetTileVariant(center.x, center.z) * 48 -- 随机变体
                        end
                        self.tiletest:SpawnTile(center, value or 1)
                    end
                end
            end
        end
    end
    self:SpawnTiles()
end

return PL_TileManager
