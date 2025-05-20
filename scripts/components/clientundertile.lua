local function InitializeDataGrid(inst, data)
    inst.components.clientundertile._underneath_tiles = DataGrid(data.width, data.height)
end

local ClientUnderTile = Class(function(self, inst)
    self.inst = inst

    self._underneath_tiles = nil
    self.inst:ListenForEvent("worldmapsetsize", InitializeDataGrid)
end)

function ClientUnderTile:CheckInSize(x, y)
    local width, height = TheWorld.Map:GetSize()
    if x < 0 or x > width - 1 then
        return false
    end
    if y < 0 or y > height - 1 then
        return false
    end
    return true
end

function ClientUnderTile:GetTileUnderneath(x, y)
    if not self:CheckInSize(x, y) then
        return
    end

    if self.inst.components.undertile then
        return self.inst.components.undertile:GetTileUnderneath(x, y)
    else
        return self._underneath_tiles:GetDataAtPoint(x, y)
    end
end

-- Receiving from update_undertile client RPC
--
-- data: {
--      action: "update"
--      data: { [index: number]: tile }
-- } |
-- {
--      action: "remove"
--      data: { [index: number]: true }
-- }
function ClientUnderTile:OnUnderTilesChange(data)
    if data.action == "update" then
        for index, data in pairs(data.data) do
            self._underneath_tiles:SetDataAtIndex(index, data)
        end
    elseif data.action == "remove" then
        for index in pairs(data.data) do
            self._underneath_tiles:SetDataAtIndex(index, nil)
        end
    end
end

return ClientUnderTile
