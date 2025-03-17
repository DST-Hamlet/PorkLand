local AddComponentPostInit = AddComponentPostInit
GLOBAL.setfenv(1, GLOBAL)

----------------------------------------------------------------------------------------
local UnderTile = require("components/undertile")

local _underneath_tiles

function UnderTile:Get()
    return _underneath_tiles
end

-- data: {
--      action: "update"
--      data: { [index: number]: tile }
-- } |
-- {
--      action: "remove"
--      data: { [index: number]: true }
-- }
function UnderTile:NotifyUnderTileChanged(data)
    SendModRPCToClient(GetClientModRPC("PorkLand", "update_undertile"), nil, ZipAndEncodeString(data))
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
    local set_tile_underneath = self.SetTileUnderneath
    self.SetTileUnderneath = function(self, x, y, tile, ...)
        if not self:CheckInSize(x, y) then
            return
        end
        local old_tile = self:GetTileUnderneath(x, y)
        local ret = { set_tile_underneath(self, x, y, tile, ...) }
        local current_tile = self:GetTileUnderneath(x, y)
        if current_tile ~= old_tile then
            local index = _underneath_tiles:GetIndex(x, y)
            if current_tile == nil then
                self:NotifyUnderTileChanged({
                    action = "remove",
                    data = { [index] = true },
                })
            else
                self:NotifyUnderTileChanged({
                    action = "update",
                    data = { [index] = current_tile },
                })
            end
        end
        return unpack(ret)
    end

    local clear_tile_underneath = self.ClearTileUnderneath
    self.ClearTileUnderneath = function(self, x, y, ...)
        if not self:CheckInSize(x, y) then
            return
        end
        local current_tile = self:GetTileUnderneath(x, y)
        local ret = { clear_tile_underneath(self, x, y, ...) }
        if self:GetTileUnderneath(x, y) ~= current_tile then
            local index = _underneath_tiles:GetIndex(x, y)
            self:NotifyUnderTileChanged({
                action = "remove",
                data = { [index] = true },
            })
        end
        return unpack(ret)
    end

    local get_tile_underneath = self.GetTileUnderneath
    self.GetTileUnderneath = function(self, x, y, ...)
        if not self:CheckInSize(x, y) then
            return
        end
        return get_tile_underneath(self, x, y, ...)
    end

    self.inst:DoStaticTaskInTime(0, function()
        _underneath_tiles = ToolUtil.GetUpvalue(self.OnLoad, "_underneath_tiles")
        if not _underneath_tiles then
            print("WARNING: Can't get upvalue _underneath_tiles form UnderTile.OnLoad, client side shadows and canopies will not work!")
        end
        self:NotifyUnderTileChanged(self:Get():Save())
    end)
end)
