local function InitializeDataGrid(inst, data)
    inst.components.clientundertile._underneath_tiles = DataGrid(data.width, data.height)
end

local function OnSerializedUnderTilesDirty(inst)
    local clientundertile = inst.components.clientundertile
    local data = DecodeAndUnzipString(clientundertile._serialized_undertiles:value())
    clientundertile._underneath_tiles:Load(data)
end

local ClientUnderTile = Class(function(self, inst)
    self.inst = inst

    self._underneath_tiles = nil
    self.inst:ListenForEvent("worldmapsetsize", InitializeDataGrid)

    self._serialized_undertiles = net_string(self.inst.GUID, "clientundertile._serialized_undertiles", "serializedundertilesdirty")
    self.inst:ListenForEvent("serializedundertilesdirty", OnSerializedUnderTilesDirty)
end)

function ClientUnderTile:GetTileUnderneath(x, y)
    if self.inst.components.undertile then
        return self.inst.components.undertile:GetTileUnderneath(x, y)
    else
        return self._underneath_tiles:GetDataAtPoint(x, y)
    end
end

function ClientUnderTile:SyncUnderTiles()
    local undertiles = self.inst.components.undertile:Get()
    -- Can be nil if we failed to get the upvalue
    if undertiles then
        self._serialized_undertiles:set(ZipAndEncodeString(undertiles:Save()))
    end
end

return ClientUnderTile
