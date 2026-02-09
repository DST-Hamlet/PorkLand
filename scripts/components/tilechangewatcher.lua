local TileChangeWatcher = Class(function(self, inst)
    self.inst = inst

    self.last_tile_center = nil
    self.tile_cache = DataGrid(1, 1)

    self.update_listeners = {}
end)

function TileChangeWatcher:OnWallUpdate(dt)
    local current_tile_center = Vector3(TheWorld.Map:GetTileCenterPoint(self.inst.Transform:GetWorldPosition()))
    if current_tile_center == self.last_tile_center then
        return
    end
    self.last_tile_center = current_tile_center
    self:NotifyUpdate()
end

function TileChangeWatcher:ListenToUpdate(listener)
    table.insert(self.update_listeners, listener)
    self.inst:StartWallUpdatingComponent(self)
end

function TileChangeWatcher:UnlistenToUpdate(listener)
    table.removearrayvalue(self.update_listeners, listener)
    if #self.update_listeners == 0 then
        self.inst:StopWallUpdatingComponent(self)
    end
end

function TileChangeWatcher:NotifyUpdate()
    local width, height = TheWorld.Map:GetSize()
    self.tile_cache = DataGrid(width, height)
    for _, listener in ipairs(self.update_listeners) do
        listener()
    end
    self.tile_cache = DataGrid(width, height)
end

function TileChangeWatcher:CachedTile(grid_x, grid_z)
    local cache = self.tile_cache:GetDataAtPoint(grid_x, grid_z)
    if cache then
        return cache
    end
    local tile = TheWorld.Map:GetTile(grid_x, grid_z)
    self.tile_cache:SetDataAtPoint(grid_x, grid_z, tile)
    return tile
end

-- You can use this in the listeners to replace TheWorld.Map:GetTileAtPoint calls with a cache
function TileChangeWatcher:CachedTileAtPoint(x, y, z)
    local grid_x, grid_z = TheWorld.Map:GetTileCoordsAtPoint(x, y, z)
    local cache = self.tile_cache:GetDataAtPoint(grid_x, grid_z)
    if cache then
        return cache
    end
    local tile = TheWorld.Map:GetTileAtPoint(x, y, z)
    self.tile_cache:SetDataAtPoint(grid_x, grid_z, tile)
    return tile
end

return TileChangeWatcher
