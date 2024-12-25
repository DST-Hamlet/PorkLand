local AddComponentPostInit = AddComponentPostInit
GLOBAL.setfenv(1, GLOBAL)

----------------------------------------------------------------------------------------
local UnderTile = require("components/undertile")

local _underneath_tiles

function UnderTile:Get()
    return _underneath_tiles
end

function UnderTile:NotifyUnderTileChanged()
    self.inst.components.clientundertile:SyncUnderTiles()
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
        self:NotifyUnderTileChanged()
        return _SetTileUnderneath(self, x, y, tile, ...)
    end

    local _ClearTileUnderneath = self.ClearTileUnderneath
    self.ClearTileUnderneath = function(self, x, y, ...)
        if not self:CheckInSize(x, y) then
            return
        end
        self:NotifyUnderTileChanged()
        return _ClearTileUnderneath(self, x, y, ...)
    end

    local _GetTileUnderneath = self.GetTileUnderneath
    self.GetTileUnderneath = function(self, x, y, ...)
        if not self:CheckInSize(x, y) then
            return
        end
        return _GetTileUnderneath(self, x, y, ...)
    end

    self.inst:DoStaticTaskInTime(0, function()
        _underneath_tiles = ToolUtil.GetUpvalue(self.OnLoad, "_underneath_tiles")
        if not _underneath_tiles then
            print("WARNING: Can't get upvalue _underneath_tiles form UnderTile.OnLoad, client side shadows and canopies will not work!")
        end
        self.inst.components.clientundertile:SyncUnderTiles()
    end)
end)
