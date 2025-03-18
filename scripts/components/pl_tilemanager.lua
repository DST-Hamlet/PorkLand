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

function PL_TileManager:UpdateTiles()
    self:ClearTiles()
    local current_tile_center = self.inst.components.tilechangewatcher.last_tile_center
    for x = -REFRESH_RADIUS, REFRESH_RADIUS do
        for z = -REFRESH_RADIUS, REFRESH_RADIUS do
            local center = current_tile_center + Vector3(x * TILE_SCALE, 0, z * TILE_SCALE)
            local tile = TheWorld.Map:GetTileAtPoint(center.x, center.y, center.z)
            if tile then
                -- local adjacent_tiles = {
                --     {false, false, false},
                --     {false, false, false},
                --     {false, false, false},
                -- }
                local value = 0
                local bitmask_values = {
                    { 1,   2,   4   },
                    { 8,   16,  32  },
                    { 64,  128, 256 },
                }
                local tile_map = {
                    [0] = 17,
                    [1] = 18,
                    [16] = 1,
                }
                for x = -1, 1 do
                    for z = -1, 1 do
                        local adjacent_tile = TheWorld.Map:GetTileAtPoint(center.x + x * TILE_SCALE, center.y, center.z + z * TILE_SCALE)
                        -- adjacent_tiles[x + 2][z + 2] = adjacent_tile == WORLD_TILES.LILYPOND
                        if adjacent_tile == WORLD_TILES.LILYPOND then
                            value = value + bitmask_values[z + 2][x + 2]
                        end
                    end
                end

                self.tiletest:SpawnTile(center, tile_map[value] or 17)
            end
        end
    end
    self:SpawnTiles()
end

return PL_TileManager
