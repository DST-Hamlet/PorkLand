local ClientUnderTile = Class(function(self, inst)
    self.inst = inst

end)

function ClientUnderTile:GetTileUnderneath(x, y)
    if TheWorld.components.undertile and false then
        return TheWorld.components.undertile:GetTileUnderneath(x, y)
    else
        local tile_under = nil
        local tx, _, tz = TheWorld.Map:GetPointAtTile(x, y)
        for _, v in ipairs(TheSim:FindEntities(tx, 0, tz, 0.1, {"tilemarker"})) do
            tile_under = v._tile:value()
            break
        end
        return tile_under
    end
end

return ClientUnderTile
