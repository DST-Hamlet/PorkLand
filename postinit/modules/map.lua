GLOBAL.setfenv(1, GLOBAL)

local worldtiledefs = require("worldtiledefs")

local TILE_SCALE = TILE_SCALE
local TileGroupManager = TileGroupManager

local NEARBY_TILE =  --用于检测直接相邻的地皮
{
    {x = 1, z = 0},--左
    {x = 0, z = 1},--上
    {x = -1, z = 0},--右
    {x = 0, z = -1},--下
}

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

function Map:GetVisualTileAtPoint(x, y, z) --这个函数没有考虑到物理斜线
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

function Map:ReverseIsVisualGroundAtPoint(x, y, z)--用于精确判断一个点是否位于陆地碰撞体积内
    if self:ReverseIsVisualWaterAtPoint(x, y, z) then--如果位于水上，那么就不可能位于陆地上。优先级：水>陆地>虚空
        return false
    end

    local cx, cy, cz = self:GetTileCenterPoint(x, y, z)
    if not cx or not cy or not cz then
        return false
    end
    local _x = x - cx --点和点所在地皮中心的相对位置
    local _z = z - cz

    if self:IsLandTileAtPoint(cx, cy, cz) then --这个点直接位于陆地地皮上
        return true
    else --如果这个点没有直接位于陆地地皮上...
        if self:IsCloseToLand(x, y, z, 1) then --检测陆地物理区域外延部分，以及因为斜线减少的外延部分
            if math.abs(_x) >= 1 and math.abs(_z) >= 1 then --是否属于四周的角落，用于检测因为斜碰撞线导致陆地碰撞范围减小的情况

                if self:IsAboveGroundAtPoint(cx + _x/math.abs(_x) * TILE_SCALE, cy, cz) then--该角落的x方向是否相邻非虚空地皮？
                    return true
                end

                if self:IsAboveGroundAtPoint(cx, cy, cz + _z/math.abs(_z) * TILE_SCALE) then--该角落的z方向是否相邻非虚空地皮？
                    return true
                end

                if math.abs(_x) + math.abs(_z) >= 3 and --如果在x,z方向上都未能相邻非虚空地皮，那么是否属于角落斜线靠外部分？
                    self:IsAboveGroundAtPoint(cx + _x/math.abs(_x) * TILE_SCALE, cy, cz + _z/math.abs(_z) * TILE_SCALE) then --检测该角落对应斜方向的地皮
                    return true
                end
            else --如果不属于四周的角落
                return true
            end
        else --如果这个点离陆地的距离超过1，那么也有可能属于斜线导致的陆地物理额外外延部分
            if self:IsCloseToLand(x, y, z, 1.5) then --额外外延部分离陆地的最远理论距离
                if math.abs(_x) + math.abs(_z) >= 1 and --是否属于角落斜线靠外部分？
                    self:IsAboveGroundAtPoint(cx + _x/math.abs(_x) * TILE_SCALE, cy, cz) and --该角落的x方向是否相邻陆地地皮？
                    self:IsAboveGroundAtPoint(cx, cy, cz + _z/math.abs(_z) * TILE_SCALE) then --该角落的z方向是否也相邻陆地地皮？
                    return true
                end
            end
        end
    end

    return false
end

function Map:ReverseIsVisualWaterAtPoint(x, y, z)--用于精确判断一个点是否位于水体碰撞体积内
    local cx, cy, cz = self:GetTileCenterPoint(x, y, z)
    if not cx or not cy or not cz then
        return false
    end
    local _x = x - cx --点和点所在地皮中心的相对位置
    local _z = z - cz

    if self:IsOceanTileAtPoint(cx, cy, cz) then --这个点直接位于水地皮上
        return true
    else --如果这个点没有直接位于水地皮上...
        if self:IsCloseToWater(x, y, z, 1) then --检测水体物理区域外延部分，以及因为斜线减少的外延部分
            if math.abs(_x) >= 1 and math.abs(_z) >= 1 then --是否属于四周的角落，用于检测因为斜碰撞线导致水体碰撞范围减小的情况

                if self:IsOceanTileAtPoint(cx + _x/math.abs(_x) * TILE_SCALE, cy, cz) then--该角落的x方向是否相邻水地皮？
                    return true
                end

                if self:IsOceanTileAtPoint(cx, cy, cz + _z/math.abs(_z) * TILE_SCALE) then--该角落的z方向是否相邻水地皮？
                    return true
                end

                if math.abs(_x) + math.abs(_z) >= 3 and --如果在x,z方向上都未能相邻水地皮，那么是否属于角落斜线靠外部分？
                    self:IsOceanTileAtPoint(cx + _x/math.abs(_x) * TILE_SCALE, cy, cz + _z/math.abs(_z) * TILE_SCALE) then --检测该角落对应斜方向的地皮
                    return true
                end
            else --如果不属于四周的角落
                return true
            end
        else --如果这个点离水体的距离超过1，那么也有可能属于斜线导致的水体物理额外外延部分
            if self:IsCloseToWater(x, y, z, 1.5) then --额外外延部分离水体的最远理论距离
                if math.abs(_x) + math.abs(_z) >= 1 and --是否属于角落斜线靠外部分？
                    self:IsOceanTileAtPoint(cx + _x/math.abs(_x) * TILE_SCALE, cy, cz) and --该角落的x方向是否相邻水地皮？
                    self:IsOceanTileAtPoint(cx, cy, cz + _z/math.abs(_z) * TILE_SCALE) then --该角落的z方向是否也相邻水地皮？
                    return true
                end
            end
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

local _IsVisualGroundAtPoint = Map.IsVisualGroundAtPoint
function Map:IsVisualGroundAtPoint(x, y, z, ...)
    if TheWorld.has_pl_ocean then
        return self:ReverseIsVisualGroundAtPoint(x, y, z)
    end
    return _IsVisualGroundAtPoint(self, x, y, z, ...)
end

local _IsAboveGroundAtPoint = Map.IsAboveGroundAtPoint
function Map:IsAboveGroundAtPoint(x, y, z, allow_water, ...)
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
