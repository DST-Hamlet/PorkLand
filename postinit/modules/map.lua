GLOBAL.setfenv(1, GLOBAL)

local worldtiledefs = require("worldtiledefs")

local TILE_SCALE = TILE_SCALE
local TileGroupManager = TileGroupManager

local TileRenderOrder = {}
for i, v in ipairs(worldtiledefs.ground) do
    TileRenderOrder[v[1]] = i
end

local function GetMaxRenderOrderTile(tile1, tile2)
    if (TileRenderOrder[tile2] or 0) > (TileRenderOrder[tile1] or 0) then
        return tile2
    end
    return tile1
end

function Map:GetVisualTileAtPoint(x, y, z)
    -- TODO interior tile
    local tile = self:GetTileAtPoint(x, y, z)
    local center_x, _, center_z = self:GetTileCenterPoint(x, y, z)
    local offset_x = x - center_x
    local offset_z = z - center_z
    local abs_offset_x = math.abs(offset_x)
    local abs_offset_z = math.abs(offset_z)
    local has_x_overhang = abs_offset_x >= 1
    local has_z_overhang = abs_offset_z >= 1

    if not has_x_overhang and not has_z_overhang then
        return tile
    end

    local near_x = center_x + (offset_x > 0 and 1 or -1) * TILE_SCALE
    local near_z = center_z + (offset_z > 0 and 1 or -1) * TILE_SCALE

    if has_x_overhang then
        local near_x_tile = self:GetTileAtPoint(near_x, 0, center_z)
        tile = GetMaxRenderOrderTile(tile, near_x_tile)
    end

    if has_z_overhang then
        local near_z_tile = self:GetTileAtPoint(center_x, 0, near_z)
        tile = GetMaxRenderOrderTile(tile, near_z_tile)
    end

    if has_z_overhang and has_z_overhang and abs_offset_x + abs_offset_z >= 3 then
        local corner_tile = self:GetTileAtPoint(near_x, 0, near_z)
        tile = GetMaxRenderOrderTile(tile, corner_tile)
    end

    return tile
end

local _IsPassableAtPoint = Map.IsPassableAtPoint
function Map:IsPassableAtPoint(x, y, z, ...)
    if TheWorld.components.interiorspawner and TheWorld.components.interiorspawner:IsInInteriorRegion(x, z) then
        return true
    end
    return _IsPassableAtPoint(self, x, y, z, ...)
end

function Map:IsImpassableAtPoint(x, y, z, ...)
    return not self:_IsVisualGroundAtPoint(x, y, z, ...) and not self:ReverseIsVisualWaterAtPoint(x, y, z)
end

function Map:ReverseIsVisualGroundAtPoint(x, y, z)
    return self:_IsVisualGroundAtPoint(x, y, z) and not self:ReverseIsVisualWaterAtPoint(x, y, z)
end

function Map:ReverseIsVisualWaterAtPoint(x, y, z)
    if self:IsOceanTileAtPoint(x, y, z) then
        return true
    end
    if TheWorld.components.interiorspawner and TheWorld.components.interiorspawner:IsInInteriorRegion(x, z) then
        return false
    end

    local center_x, _, center_z = self:GetTileCenterPoint(x, y, z)

    if center_x == nil then
        return false
    end

    local offset_x = x - center_x
    local abs_offset_x = math.abs(offset_x)
    local near_x
    if abs_offset_x >= 1 then
        near_x = center_x + (offset_x > 0 and 1 or -1) * TILE_SCALE
        if self:IsOceanTileAtPoint(near_x, 0, center_z) then
            return true
        end
    end

    local offset_z = z - center_z
    local abs_offset_z = math.abs(offset_z)
    local near_z
    if abs_offset_z >= 1 then
        near_z = center_z + (offset_z > 0 and 1 or -1) * TILE_SCALE
        if self:IsOceanTileAtPoint(center_x, 0, near_z) then
            return true
        end
    end

    if near_x and near_z and abs_offset_z + abs_offset_x >= 3 then
        if self:IsOceanTileAtPoint(near_x, 0, near_z) then
            return true
        end
    end

    if not near_x and not near_z and abs_offset_z + abs_offset_x >= 1 then
        near_x = center_x + (offset_x > 0 and 1 or -1) * TILE_SCALE
        near_z = center_z + (offset_z > 0 and 1 or -1) * TILE_SCALE
        if self:IsOceanTileAtPoint(near_x, 0, center_z)
            and self:IsOceanTileAtPoint(center_x, 0, near_z)
            and self:IsOceanTileAtPoint(near_x, 0, near_z) then
            return true
        end
    end

    return false
end

function Map:IsCloseToTile(x, y, z, radius, typefn, ...)
    if radius == 0 then return typefn(x, y, z, ...) end
    -- Correct improper radiuses caused by changes to the radius based on overhang
    if radius < 0 then return self:IsSurroundedByTile(x, y, z, radius * -1, typefn, ...) end

    local num_edge_points = math.ceil((radius * 2) / TILE_SCALE) - 1

    -- test the corners first
    if typefn(x + radius, y, z + radius, ...) then return true end
    if typefn(x - radius, y, z + radius, ...) then return true end
    if typefn(x + radius, y, z - radius, ...) then return true end
    if typefn(x - radius, y, z - radius, ...) then return true end

    -- if the radius is less than 2(1 after the -1), it won't have any edges to test and we can end the testing here.
    if num_edge_points == 0 then return false end

    local dist = (radius * 2) / (num_edge_points + 1)
    -- test the edges next
    for i = 1, num_edge_points do
        local idist = dist * i
        if typefn(x - radius + idist, y, z + radius, ...) then return true end
        if typefn(x - radius + idist, y, z - radius, ...) then return true end
        if typefn(x - radius, y, z - radius + idist, ...) then return true end
        if typefn(x + radius, y, z - radius + idist, ...) then return true end
    end

    -- test interior points last
    for i = 1, num_edge_points do
        local idist = dist * i
        for j = 1, num_edge_points do
            local jdist = dist * j
            if typefn(x - radius + idist, y, z - radius + jdist, ...) then return true end
        end
    end
    return false
end

function Map:IsCloseToLand(x, y, z, radius)
    return self:IsCloseToTile(x, y, z, radius, function(_x, _y, _z, map)
        return map:IsLandTileAtPoint(_x, _y, _z)
    end, self)
end

function Map:IsCloseToWater(x, y, z, radius)
    return self:IsCloseToTile(x, y, z, radius, function(_x, _y, _z, map)
        return map:IsOceanTileAtPoint(_x, _y, _z)
    end, self)
end

function Map:IsSurroundedByTile(x, y, z, radius, typefn, ...)
    if radius == 0 then return typefn(x, y, z, ...) end
    -- Correct improper radiuses caused by changes to the radius based on overhang
    if radius < 0 then return self:IsCloseToTile(x, y, z, radius * -1, typefn, ...) end

    local num_edge_points = math.ceil((radius*2) / TILE_SCALE) - 1

    -- test the corners first
    if not typefn(x + radius, y, z + radius, ...) then return false end
    if not typefn(x - radius, y, z + radius, ...) then return false end
    if not typefn(x + radius, y, z - radius, ...) then return false end
    if not typefn(x - radius, y, z - radius, ...) then return false end

    -- if the radius is less than 2(1 after the -1), it won't have any edges to test and we can end the testing here.
    if num_edge_points == 0 then return true end

    local dist = (radius*2) / (num_edge_points + 1)
    -- test the edges next
    for i = 1, num_edge_points do
        local idist = dist * i
        if not typefn(x - radius + idist, y, z + radius, ...) then return false end
        if not typefn(x - radius + idist, y, z - radius, ...) then return false end
        if not typefn(x - radius, y, z - radius + idist, ...) then return false end
        if not typefn(x + radius, y, z - radius + idist, ...) then return false end
    end

    -- test interior points last
    for i = 1, num_edge_points do
        local idist = dist * i
        for j = 1, num_edge_points do
            local jdist = dist * j
            if not typefn(x - radius + idist, y, z - radius + jdist, ...) then return false end
        end
    end
    return true
end

local _IsSurroundedByWater = Map.IsSurroundedByWater
function Map:IsSurroundedByWater(x, y, z, radius, ...)
    if TheWorld.has_pl_ocean then
        -- subtract 1 to radius for map overhang, way cheaper than doing an IsVisualGround test
        -- if the radius is less than 2(1 after the -1), We only need to check if the current point is an ocean tile
        return self:IsSurroundedByTile(x, y, z, radius - 1, function(_x, _y, _z, map)
            return map:IsOceanTileAtPoint(_x, _y, _z)
        end, self)
    end
    return _IsSurroundedByWater(self, x, y, z, radius, ...)
end

function Map:CanDeployAquaticAtPointInWater(pt, data, player)
    if data.boat and not TheWorld.has_pl_ocean then
        return false
    end

    local x, y, z = pt:Get()
    if self:GetNearbyPlatformAtPoint(x, y, z, data.platform_buffer_min or TUNING.BOAT.NO_BUILD_BORDER_RADIUS) ~= nil then
        return false
    end

    local boating = true
    local platform = false
    if player ~= nil then
        local px, py, pz = player.Transform:GetWorldPosition()
        boating = self:IsOceanAtPoint(px, py, pz)
        platform = self:GetPlatformAtPoint(px, py, pz)
    end

    if boating or platform then
        if platform and platform.components.walkableplatform and math.sqrt(platform:GetDistanceSqToPoint(x, 0, z)) > platform.components.walkableplatform.platform_radius + (data.platform_buffer_max or 0.5) + 1.3 then --1.5 is closer but some distance should be cut for ease of use
            return false
        end
        local min_buffer = data.aquatic_buffer_min or 2
        return self:IsSurroundedByWater(x, y, z, min_buffer + 1) -- Add 1 for overhang
    else
        if data.noshore then -- used by the ballphinhouse
            return false
        end

        if not self:ReverseIsVisualWaterAtPoint(x, y, z) then
            return false
        end

        local min_buffer = data.shore_buffer_min or 0.5

        if not self:IsSurroundedByWater(x, y, z, min_buffer) then
            return false
        end

        local max_buffer = data.shore_buffer_max or 2

        if not self:IsCloseToLand(x, y, z, max_buffer) then
            return false
        end

        return true
    end
end

Map._IsVisualGroundAtPoint = Map.IsVisualGroundAtPoint  --用于判断一个点是否属于陆地范围
function Map:IsVisualGroundAtPoint(x, y, z, ...)
    if TheWorld.components.interiorspawner and TheWorld.components.interiorspawner:IsInInteriorRegion(x, z) then
        return true
    end
    if TheWorld.has_pl_ocean then
        return self:ReverseIsVisualGroundAtPoint(x, y, z)
    end
    return self:_IsVisualGroundAtPoint(x, y, z, ...)
end

local _IsAboveGroundAtPoint = Map.IsAboveGroundAtPoint
function Map:IsAboveGroundAtPoint(x, y, z, allow_water, ...)
    if TheWorld.components.interiorspawner and TheWorld.components.interiorspawner:IsInInteriorRegion(x, z) then
        if ThePlayer and ThePlayer.components.playercontroller and ThePlayer.components.playercontroller.deployplacer then
            return TheWorld.components.interiorspawner:IsInInteriorRoom(x, z, -1)
        else
            return TheWorld.components.interiorspawner:IsInInteriorRoom(x, z, 1)
        end
    end
    if TheWorld.has_pl_ocean then
        local valid_water_tile = (allow_water == true) and self:ReverseIsVisualWaterAtPoint(x, y, z)
        return valid_water_tile or self:IsVisualGroundAtPoint(x, y, z)
    end
    return _IsAboveGroundAtPoint(self, x, y, z, ...)
end

local _CanDeployRecipeAtPoint = Map.CanDeployRecipeAtPoint
function Map:CanDeployRecipeAtPoint(pt, recipe, rot, player, ...)
    if recipe.aquatic and recipe.build_mode == BUILDMODE.WATER then
        local pt_x, pt_y, pt_z = pt:Get()
        local is_valid_ground = self:CanDeployAquaticAtPointInWater(pt, recipe.aquatic, player)
        return is_valid_ground and (recipe.testfn == nil or recipe.testfn(pt, rot)) and self:IsDeployPointClear(pt, nil, recipe.min_spacing or 3.2)
    end

    -- TODO: 目前只判定了一般建筑物，还需要额外考虑房间装饰物
    if recipe and pt then
        local interior = TheWorld.components.interiorspawner and TheWorld.components.interiorspawner:IsInInteriorRegion(pt.x, pt.z)
        if recipe.pl_is_house and interior then -- recipe types
            return false
        elseif interior and not TheWorld.components.interiorspawner:IsInInteriorRoom(pt.x, pt.z, -1) then
            return false
        end
    end

    return _CanDeployRecipeAtPoint(self, pt, recipe, rot, player, ...)
end

-- Copy of IsPassableAtPointWithPlatformRadiusBias that only checks the platform
local WALKABLE_PLATFORM_TAGS = {"walkableplatform"}
function Map:GetNearbyPlatformAtPoint(pos_x, pos_y, pos_z, extra_radius)
    if pos_z == nil then -- to support passing in (x, z) instead of (x, y, x)
        pos_z = pos_y
        pos_y = 0
    end
    local entities = TheSim:FindEntities(pos_x, pos_y, pos_z, math.max(TUNING.MAX_WALKABLE_PLATFORM_RADIUS + (extra_radius or 0), 0), WALKABLE_PLATFORM_TAGS) -- DST allows negitives but I dont want to risk it -Half
    for i, v in ipairs(entities) do
        if v.components.walkableplatform and math.sqrt(v:GetDistanceSqToPoint(pos_x, 0, pos_z)) <= v.components.walkableplatform.platform_radius + (extra_radius or 0) then
            return v
        end
    end
    return nil
end

local _GetTileCenterPoint = Map.GetTileCenterPoint
function Map:GetTileCenterPoint(x, y, z, ...)
    if x and z and TheWorld.components.interiorspawner and TheWorld.components.interiorspawner:IsInInteriorRegion(x, z) then
        return math.floor(x / 4) * 4 + 2, 0, math.floor(z / 4) * 4 + 2
    else
        return _GetTileCenterPoint(self, x, y, z, ...)
    end
end

local _GetTileAtPoint = Map.GetTileAtPoint
function Map:GetTileAtPoint(x, y, z, ...)
    if x and z and TheWorld.components.interiorspawner and TheWorld.components.interiorspawner:IsInInteriorRegion(x, z) then
        return WORLD_TILES.INTERIOR
    else
        return _GetTileAtPoint(self, x, y, z, ...)
    end
end
