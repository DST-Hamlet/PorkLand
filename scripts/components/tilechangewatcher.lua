-- 40 / 4 = 10
local REFRESH_RADIUS = PLAYER_CAMERA_SEE_DISTANCE / TILE_SCALE

local TileChangeWatcher = Class(function(self, inst)
    self.inst = inst

    self.falloffs = {}
    self.last_tile_center = nil

    self.effects = {}
    self.effects[1] = SpawnPrefab("falloff_fx_new")

    inst:StartWallUpdatingComponent(self)
end)

function TileChangeWatcher:ClearFalloffs()
    self.falloffs = {}
    -- TODO: Actually remove the falloffs
end

function TileChangeWatcher:SpawnFalloffs()
    for _, effect in ipairs(self.effects) do
        effect.VFXEffect:ClearAllParticles(0)
    end
    for _, data in ipairs(self.falloffs) do
        print("SpawnFallOff",data.position)
        for _, effect in ipairs(self.effects) do
            effect:emit_fn(data.position)
        end
    end
end

function TileChangeWatcher:OnRemoveEntity()
    self:ClearFalloffs()
end

TileChangeWatcher.OnRemoveFromEntity = TileChangeWatcher.OnRemoveEntity

local adjacent = {
    {
        x = TILE_SCALE,
        z = 0,
        angle = 0,
    },
    {
        x = -TILE_SCALE,
        z = 0,
        angle = 180,
    },
    {
        x = 0,
        z = TILE_SCALE,
        angle = 270,
    },
    {
        x = 0,
        z = -TILE_SCALE,
        angle = 90,
    },
}

function TileChangeWatcher:OnWallUpdate(dt)
    local current_tile_center = Vector3(TheWorld.Map:GetTileCenterPoint(self.inst.Transform:GetWorldPosition()))
    if current_tile_center == self.last_tile_center then
        return
    end
    self.last_tile_center = current_tile_center
    self:UpdateFalloffs()
end

function TileChangeWatcher:UpdateFalloffs()
    self:ClearFalloffs()
    local current_tile_center = self.last_tile_center
    for x = -REFRESH_RADIUS, REFRESH_RADIUS do
        for z = -REFRESH_RADIUS, REFRESH_RADIUS do
            local center = current_tile_center + Vector3(x * TILE_SCALE, 0, z * TILE_SCALE)
            local tile = TheWorld.Map:GetTileAtPoint(center.x, center.y, center.z)
            if TileGroupManager:IsLandTile(tile) then
                for _, v in ipairs(adjacent) do
                    local adjacent_tile = TheWorld.Map:GetTileAtPoint(center.x + v.x, center.y, center.z + v.z)
                    if adjacent_tile and not TileGroupManager:IsLandTile(adjacent_tile) then
                        table.insert(self.falloffs, {
                            position = Vector3(center.x + v.x / 2, center.y, center.z + v.z / 2),
                            angle = -v.angle + 90,
                        })
                    end
                end
            end
        end
    end
    self:SpawnFalloffs()
end

return TileChangeWatcher
