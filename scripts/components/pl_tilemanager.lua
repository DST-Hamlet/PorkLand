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

local offset_x = 0.01

local adjacent = {
    {
        x = TILE_SCALE + offset_x,
        z = 0,
    },
    {
        x = -(TILE_SCALE + offset_x),
        z = 0,
    },
    {
        x = 0,
        z = TILE_SCALE + offset_x,
    },
    {
        x = 0,
        z = -(TILE_SCALE + offset_x),
    },
}

function PL_TileManager:UpdateTiles()
    self:ClearTiles()
    local current_tile_center = self.last_tile_center
    for x = -REFRESH_RADIUS, REFRESH_RADIUS do
        for z = -REFRESH_RADIUS, REFRESH_RADIUS do
            local center = current_tile_center + Vector3(x * TILE_SCALE, 0, z * TILE_SCALE)
            local tile = TheWorld.Map:GetTileAtPoint(center.x, center.y, center.z)
            if tile then
                for _, v in ipairs(adjacent) do
                    local adjacent_tile = TheWorld.Map:GetTileAtPoint(center.x + v.x, center.y, center.z + v.z)
                    if adjacent then

                    end
                end

                if tile == WORLD_TILES.LILYPOND then
                    self.tiletest:SpawnTile(center, 3)
                end
            end
        end
    end
    self:SpawnTiles()
end

return PL_TileManager
