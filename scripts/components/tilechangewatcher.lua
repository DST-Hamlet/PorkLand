local TileChangeWatcher = Class(function(self, inst)
    self.inst = inst

    self.last_tile_center = nil

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
    for _, listener in ipairs(self.update_listeners) do
        listener()
    end
end

return TileChangeWatcher
