GLOBAL.setfenv(1, GLOBAL)

---@param tile number | nil
---@param check function | table | string
---@param ... any
function CheckTileType(tile, check, ...)
    if type(check) == "function" then
        return check(tile, ...)
    elseif type(check) == "table" then
        return table.contains(check, tile)
    elseif type(check) == "string" then
        return WORLD_TILES[check] == tile
    end

    return tile == check
end

---@param x number
---@param y number
---@param z number
---@param check function | table | string
---@param ... any
function CheckTileAtPoint(x, y, z, check, ...)
    if type(check) == "function" then
        return check(x, y, z, ...)
    end
    local tile = TheWorld.Map:GetTileAtPoint(x, y, z)
    return CheckTileType(tile, check, ...)
end

---@param x number
---@param y number
---@param z number
function IsOnPlOcean(x, y, z)
    return CheckTileAtPoint(x, y, z, PL_OCEAN_TILES)
end

---@param x number
---@param y number
---@param z number
function IsOnPlLand(x, y, z)
    return CheckTileType(x, y, z, PL_LAND_TILES)
end

---@param x number
---@param y number
---@param z number
---@param radius number default 1
---@param check function | table | string
function IsSurroundedByTile(x, y, z, radius, check, ...)
    radius = radius or 1

    local num_edge_points = math.ceil((radius*2) / 4) - 1

    -- test the corners first
    if not CheckTileAtPoint(x + radius, y, z + radius, check, ...) then return false end
    if not CheckTileAtPoint(x - radius, y, z + radius, check, ...) then return false end
    if not CheckTileAtPoint(x + radius, y, z - radius, check, ...) then return false end
    if not CheckTileAtPoint(x - radius, y, z - radius, check, ...) then return false end

    -- if the radius is less than 1(2 after the +1), it won't have any edges to test and we can end the testing here.
    if num_edge_points == 0 then return true end

    local dist = (radius * 2) / (num_edge_points + 1)
    -- test the edges next
    for i = 1, num_edge_points do
        local idist = dist * i
        if not CheckTileAtPoint(x - radius + idist, y, z + radius, check, ...) then return false end
        if not CheckTileAtPoint(x - radius + idist, y, z - radius, check, ...) then return false end
        if not CheckTileAtPoint(x - radius, y, z - radius + idist, check, ...) then return false end
        if not CheckTileAtPoint(x + radius, y, z - radius + idist, check, ...) then return false end
    end

    -- test interior points last
    for i = 1, num_edge_points do
        local idist = dist * i
        for j = 1, num_edge_points do
            local jdist = dist * j
            if not CheckTileAtPoint(x - radius + idist, y, z - radius + jdist, check, ...) then return false end
        end
    end
    return true
end

---@param x number
---@param y number
---@param z number
---@param radius number default 1
---@param ignoreboat boolean
function IsSurroundedByWater(x, y, z, radius, ignoreboat)
    return IsSurroundedByTile(x, y, z, radius, function(_x, _y, _z)
        return TheWorld.Map:IsOceanTileAtPoint(_x, _y, _z, ignoreboat)
    end)
end

---@param x number
---@param y number
---@param z number
---@param radius number default 1
function IsSurroundedByLand(x, y, z, radius)
    return IsSurroundedByTile(x, y, z, radius, function(_x, _y, _z)
        return TheWorld.Map:IsLandTileAtPoint(_x, _y, _z)
    end)
end

---@param x number
---@param y number
---@param z number
---@param radius number default 1
---@param check function | table | string
function IsCloseToTile(x, y, z, radius, check, ...)
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

---@param x number
---@param y number
---@param z number
---@param radius number default 1
---@param ignoreboat boolean
function IsCloseToWater(x, y, z, radius, ignoreboat)
    return IsCloseToTile(x, y, z, radius, function (_x, _y, _z)
        return TheWorld.Map:IsOceanTileAtPoint(_x, _y, _z, ignoreboat)
    end)
end

---@param x number
---@param y number
---@param z number
---@param radius number default 1
function IsCloseToLand(x, y, z, radius)
    return IsCloseToTile(x, y, z, radius, function(_x, _y, _z)
        return TheWorld.Map:IsLandTileAtPoint(_x, _y, _z)
    end)
end
