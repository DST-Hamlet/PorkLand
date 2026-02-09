local TileChangeWatcher = Class(function(self, inst)
    self.inst = inst

    self.last_tile_center = nil
    local width, height = TheWorld.Map:GetSize()
    self.tile_cache = DataGrid(width, height)

    self.update_listeners = {}
    self.tilechanged_listeners = {}

    self.inst.components.updatelooper:AddPostUpdateFn(function()
        self:OnPostUpdate()
    end)
end)

function TileChangeWatcher:ListenToUpdate(listener)
    table.insert(self.update_listeners, listener)
end

function TileChangeWatcher:UnlistenToUpdate(listener)
    table.removearrayvalue(self.update_listeners, listener)
    if #self.update_listeners == 0 then
    end
end

function TileChangeWatcher:NotifyUpdate()
    for _, listener in ipairs(self.update_listeners) do
        listener()
    end
end

function TileChangeWatcher:ListenToTileChanged(listener)
    table.insert(self.tilechanged_listeners, listener)
end

function TileChangeWatcher:UnlistenToTileChanged(listener)
    table.removearrayvalue(self.tilechanged_listeners, listener)
end

function TileChangeWatcher:OnTileChanged(data)
    if data and data.x and data.y and data.tile then
        self.tile_cache:SetDataAtPoint(data.x, data.y, data.tile)
    end
    for _, listener in ipairs(self.tilechanged_listeners) do -- 标记需要重新计算的数据, 在这一帧的结尾时再重新计算
        listener(data)
    end
    self.shouldpostupdate = true
end

function TileChangeWatcher:OnPostUpdate()
    local current_tile_center = Vector3(TheWorld.Map:GetTileCenterPoint(self.inst.Transform:GetWorldPosition()))
    if current_tile_center and current_tile_center ~= self.last_tile_center then
        self.last_tile_center = current_tile_center
        self:NotifyUpdate()
    elseif self.shouldpostupdate then
        self:NotifyUpdate()
    end

    self.shouldpostupdate = nil
    local width, height = TheWorld.Map:GetSize()
    self.tile_cache = DataGrid(width, height)
end

function TileChangeWatcher:GetCachedTile(grid_x, grid_z) -- 请确保在NotifyUpdate内部被调用
    local cache = self.tile_cache:GetDataAtPoint(grid_x, grid_z)
    if cache then
        return cache
    end
    local tile = TheWorld.Map:GetTile(grid_x, grid_z)
    self.tile_cache:SetDataAtPoint(grid_x, grid_z, tile)
    return tile
end

-- You can use this in the listeners to replace TheWorld.Map:GetTileAtPoint calls with a cache
function TileChangeWatcher:GetCachedTileAtPoint(x, y, z)
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
