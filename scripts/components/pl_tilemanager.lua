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

PL_TileManager.OnRemoveFromEntity = PL_TileManager.OnRemoveEntity

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

                    if tile_map[key] then
                        self.tiletest:SpawnTile(center, tile_map[key] or 17)
                    end
                end
            end
        end
    end
    self:SpawnTiles()
end

return PL_TileManager
