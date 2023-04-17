GLOBAL.setfenv(1, GLOBAL)

function GetWorldPosition(x, y, z)
    if type(x) == "table" then
        if x.x then
            x, y, z = x.x, x.y, x.z
        elseif x.Transform then
            x, y, z = x.Transform:GetWorldPosition()
        end
    end

    return x, y, z
end

function CheckTileType(tile, check, ...)
    if type(tile) == "table" then
        local x, y, z = GetWorldPosition(tile)
        if type(check) == "function" then
            return check(x, y, z, ...)
        end
        tile = TheWorld.Map:GetTileAtPoint(x, y, z)
    end

    if type(check) == "function" then
        return check(tile, ...)
    elseif type(check) == "table" then
        return table.contains(check, tile)
    elseif type(check) == "string" then
        return WORLD_TILES[check] == tile
    end

    return tile == check
end

function CheckTileAtPoint(x, y, z, check, ...)
    x, y, z = GetWorldPosition(x, y, z)
    return CheckTileType({x = x, y = y, z = z}, check, ...)
end

function IsOnFlood(x, y, z)
    x, y, z = GetWorldPosition(x, y, z)
    return TheWorld.components.flooding and TheWorld.components.flooding:OnFlood(x, y, z)
end

function IsOnOcean(x, y, z, onflood, ignoreboat)
    x, y, z = GetWorldPosition(x, y, z)
    return TheWorld.Map:IsOceanAtPoint(x, y, z, ignoreboat) or (onflood and IsOnFlood(x, y, z))
end

function IsOnPLOcean(x, y, z, onflood)
    return CheckTileAtPoint(x, y, z, PL_OCEAN_TILES) or (onflood and IsOnFlood(x, y, z))
end

function IsOnLand(x, y, z, noflood)
    x, y, z = GetWorldPosition(x, y, z)
    if noflood and IsOnFlood(x, y, z) then
        return false
    end

    local tile = TheWorld.Map:GetTileAtPoint(x, y, z)
    return CheckTileType(tile, IsLandTile)
end

function IsOnPLLand(x, y, z, noflood)
    x, y, z = GetWorldPosition(x, y, z)
    if noflood and IsOnFlood(x, y, z) then
        return false
    end

    local tile = TheWorld.Map:GetTileAtPoint(x, y, z)
    return CheckTileType(tile, PL_LAND_TILES)
end

function IsSurroundedByTile(x, y, z, radius, check, ...)
    x, y, z = GetWorldPosition(x, y, z)
    radius = radius or 1
    for i = -radius, radius do
        if not CheckTileAtPoint(x - radius, y, z + i, check, ...) or not CheckTileAtPoint(x + radius, y, z + i, check, ...) then
            return false
        end
    end
    for i = -(radius - 1), radius - 1 do
        if not CheckTileAtPoint(x + i, y, z - radius, check, ...) or not CheckTileAtPoint(x + i, y, z + radius, check, ...) then
            return false
        end
    end
    return true
end

function IsSurroundedByWater(x, y, z, radius, onflood, ignoreboat)
    return IsSurroundedByTile(x, y, z, radius, IsOnOcean, onflood, ignoreboat)
end

function IsSurroundedByLand(x, y, z, radius, noflood)
    return IsSurroundedByTile(x, y, z, radius, IsOnLand, noflood)
end

function IsCloseToTile(x, y, z, radius, check, ...)
    x, y, z = GetWorldPosition(x, y, z)
    radius = radius or 1
    for i = -radius, radius do
        if CheckTileAtPoint(x - radius, y, z + i, check, ...) or CheckTileAtPoint(x + radius, y, z + i, check, ...) then
            return true
        end
    end
    for i = -(radius - 1), radius - 1 do
        if CheckTileAtPoint(x + i, y, z - radius, check, ...) or CheckTileAtPoint(x + i, y, z + radius, check, ...) then
            return true
        end
    end

    return false
end

function IsCloseToLand(x, y, z, radius, noflood)
    return IsCloseToTile(x, y, z, radius, IsOnLand, noflood)
end

function IsCloseToPLLand(x, y, z, radius, noflood)
    return IsCloseToTile(x, y, z, radius, IsOnPLLand, noflood)
end

function IsCloseToPLWater(x, y, z, radius, noflood)
    return IsCloseToTile(x, y, z, radius, IsOnPLOcean, noflood)
end
