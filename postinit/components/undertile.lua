local AddComponentPostInit = AddComponentPostInit
GLOBAL.setfenv(1, GLOBAL)

----------------------------------------------------------------------------------------
local UnderTile = require("components/undertile")

function UnderTile:SpawnMarkAtTile(x, y, tile)
    self:ClearMarkAtTile(x, y)
    if tile then
        local mark = SpawnPrefab("undertile_marker")
        mark.Transform:SetPosition(TheWorld.Map:GetPointAtTile(x, y))
        mark._tile:set(tile)
    end
end

function UnderTile:ClearMarkAtTile(x, y)
    local tx, _, tz = TheWorld.Map:GetPointAtTile(x, y)
    for _, v in ipairs(TheSim:FindEntities(tx, 0, tz, 0.1, {"tilemarker"})) do
        v:Remove()
    end
end

function UnderTile:CheckInSize(x, y)
    local width, height = TheWorld.Map:GetSize()
    if x < 0 or x > width - 1 then
        return false
    end
    if y < 0 or y > height - 1 then
        return false
    end
    return true
end

AddComponentPostInit("undertile", function(self, inst)

    local _SetTileUnderneath = self.SetTileUnderneath
    self.SetTileUnderneath = function(self, x, y, tile, ...)
        if not self:CheckInSize(x, y) then
            return
        end
        self:SpawnMarkAtTile(x, y, tile)
        return _SetTileUnderneath(self, x, y, tile, ...)
    end

    local _ClearTileUnderneath = self.ClearTileUnderneath
    self.ClearTileUnderneath = function(self, x, y, ...)
        if not self:CheckInSize(x, y) then
            return
        end
        self:ClearMarkAtTile(x, y)
        return _ClearTileUnderneath(self, x, y, ...)
    end

    local _GetTileUnderneath = self.GetTileUnderneath
    self.GetTileUnderneath = function(self, x, y, ...)
        if not self:CheckInSize(x, y) then
            return
        end
        return _GetTileUnderneath(self, x, y, ...)
    end

    local _OnLoad = self.OnLoad
    self.OnLoad = function(self, data, ...)
        local decode_data = DecodeAndUnzipSaveData(data)
        local rets = {_OnLoad(self, data, ...)}
        local tile_id_conversion_map = TheWorld.tile_id_conversion_map
        for k, v in pairs(decode_data.underneath_tiles) do
            local tile = tile_id_conversion_map[v] or v
            local width, height = TheWorld.Map:GetSize()
            local _x = k % width
            local _y = math.floor(k / width)
            self:SpawnMarkAtTile(_x, _y, tile)
        end
        return unpack(rets)
    end
end)
