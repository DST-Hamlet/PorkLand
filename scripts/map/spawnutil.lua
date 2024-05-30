-- this file function only for worldgen, in game use main/util.lua functions
local SpawnUtil = {}

function SpawnUtil.IsCloseToWater(x, y, radius)
    radius = radius or 1
    for i = -radius, radius do
        if IsOceanTile(WorldSim:GetTile(x - radius, y + i)) or IsOceanTile(WorldSim:GetTile(x + radius, y + i)) then
            return true
        end
    end
    for i = -(radius - 1), radius - 1, 1 do
        if IsOceanTile(WorldSim:GetTile(x + i, y - radius)) or IsOceanTile(WorldSim:GetTile(x + i, y + radius)) then
            return true
        end
    end
    return false
end

function SpawnUtil.IsSurroundedByTile(x, y, radius, tile, ...)
    radius = radius or 1

    local num_edge_points = math.ceil((radius*2) / 4) - 1

    -- test the corners first
    if not CheckTileType(WorldSim:GetTile(x + radius, y + radius), tile) then return false end
    if not CheckTileType(WorldSim:GetTile(x - radius, y + radius), tile) then return false end
    if not CheckTileType(WorldSim:GetTile(x + radius, y - radius), tile) then return false end
    if not CheckTileType(WorldSim:GetTile(x - radius, y - radius), tile) then return false end

    -- if the radius is less than 1(2 after the +1), it won't have any edges to test and we can end the testing here.
    if num_edge_points == 0 then return true end

    local dist = (radius * 2) / (num_edge_points + 1)
    -- test the edges next
    for i = 1, num_edge_points do
        local idist = dist * i
        if not CheckTileType(WorldSim:GetTile(x - radius + idist, y + radius), tile) then return false end
        if not CheckTileType(WorldSim:GetTile(x - radius + idist, y - radius), tile) then return false end
        if not CheckTileType(WorldSim:GetTile(x - radius, y - radius + idist), tile) then return false end
        if not CheckTileType(WorldSim:GetTile(x + radius, y - radius + idist), tile) then return false end
    end

    -- test interior points last
    for i = 1, num_edge_points do
        local idist = dist * i
        for j = 1, num_edge_points do
            local jdist = dist * j
            if not CheckTileType(WorldSim:GetTile(x - radius + idist, y - radius + jdist), tile) then return false end
        end
    end
    return true
end

function SpawnUtil.IsSurroundedByWaterTile(x, y, radius)
    return SpawnUtil.IsSurroundedByTile(x, y, radius, IsOceanTile)
end

function SpawnUtil.IsSurroundedByLandTile(x, y, radius)
    return SpawnUtil.IsSurroundedByTile(x, y, radius, IsLandTile)
end

function SpawnUtil.IsCloseToTile(x, y, radius, check)
    radius = radius or 1
    for i = -radius, radius do
        if CheckTileType(WorldSim:GetTile(x - radius, y + i), check) or CheckTileType(WorldSim:GetTile(x + radius, y + i), check) then
            return true
        end
    end
    for i = -(radius - 1), radius - 1, 1 do
        if CheckTileType(WorldSim:GetTile(x + i, y - radius), check) or CheckTileType(WorldSim:GetTile(x + i, y + radius), check) then
            return true
        end
    end
    return false
end

function SpawnUtil.IsCloseToWaterTile(x, y, radius)
    return SpawnUtil.IsCloseToTile(x, y, radius, IsOceanTile)
end

function SpawnUtil.IsCloseToLandTile(x, y, radius)
    return SpawnUtil.IsCloseToTile(x, y, radius, IsLandTile)
end

return SpawnUtil
