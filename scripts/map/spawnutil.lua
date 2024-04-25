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

function SpawnUtil.IsSurroundedByTile(x, y, z, radius, tile, ...)
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

function SpawnUtil.GetLayoutRadius(layout, prefabs)
    assert(layout ~= nil)
    assert(prefabs ~= nil)

    local extents = {xmin = 1000000, ymin = 1000000, xmax = -1000000, ymax = -1000000}
    for i = 1, #prefabs do
        -- print(string.format("Prefab %s (%4.2f, %4.2f)", tostring(prefabs[i].prefab), prefabs[i].x, prefabs[i].y))
        if prefabs[i].x < extents.xmin then extents.xmin = prefabs[i].x end
        if prefabs[i].x > extents.xmax then extents.xmax = prefabs[i].x end
        if prefabs[i].y < extents.ymin then extents.ymin = prefabs[i].y end
        if prefabs[i].y > extents.ymax then extents.ymax = prefabs[i].y end
    end

    local e_width, e_height = extents.xmax - extents.xmin, extents.ymax - extents.ymin
    local size = math.ceil(layout.scale * math.max(e_width, e_height))

    if layout.ground then
        size = math.max(size, #layout.ground)
    end

    -- print(string.format("Layout %s dims (%4.2f x %4.2f), size %4.2f", layout.name, e_width, e_height, size))
    return size
end

return SpawnUtil
