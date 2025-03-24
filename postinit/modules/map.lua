GLOBAL.setfenv(1, GLOBAL)

local worldtiledefs = require("worldtiledefs")

local TILE_SCALE = TILE_SCALE

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

    if has_x_overhang and has_z_overhang and abs_offset_x + abs_offset_z >= 3 then
        local corner_tile = self:GetTileAtPoint(near_x, 0, near_z)
        tile = GetMaxRenderOrderTile(tile, corner_tile)
    end

    return tile
end

local _IsPassableAtPoint = Map.IsPassableAtPoint
function Map:IsPassableAtPoint(x, y, z, allow_water, ...)
    if TheWorld.components.interiorspawner and TheWorld.components.interiorspawner:IsInInteriorRegion(x, z) then
        return TheWorld.components.interiorspawner:IsInInteriorRoom(x, z)
    end
    if not allow_water and self:ReverseIsVisualWaterAtPoint(x, y, z) then
        return false
    end
    return _IsPassableAtPoint(self, x, y, z, allow_water, ...)
end

function Map:IsImpassableAtPoint(x, y, z, ...)
    if TheWorld.components.interiorspawner and TheWorld.components.interiorspawner:IsInInteriorRegion(x, z) then
        return not TheWorld.components.interiorspawner:IsInInteriorRoom(x, z)
    end
    return not self:_IsVisualGroundAtPoint(x, y, z, ...) and not self:ReverseIsVisualWaterAtPoint(x, y, z)
end

function Map:ReverseIsVisualGroundAtPoint(x, y, z)
    if TheWorld.components.interiorspawner and TheWorld.components.interiorspawner:IsInInteriorRegion(x, z) then
        return TheWorld.components.interiorspawner:IsInInteriorRoom(x, z)
    end
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

local _IsSurroundedByLand = Map.IsSurroundedByLand
function Map:IsSurroundedByLand(x, y, z, radius, ...)
    if TheWorld.has_pl_ocean then
        -- subtract 1 to radius for map overhang, way cheaper than doing an IsVisualGround test
        -- if the radius is less than 2(1 after the -1), We only need to check if the current point is an ocean tile
        return self:IsSurroundedByTile(x, y, z, radius - 1, function(_x, _y, _z, map)
            return not map:IsOceanTileAtPoint(_x, _y, _z) and map:_IsVisualGroundAtPoint(_x, _y, _z)
        end, self)
    end
    return _IsSurroundedByLand(self, x, y, z, radius, ...)
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

Map._IsVisualGroundAtPoint = Map.IsVisualGroundAtPoint  --用于判断一个点是否属于陆地范围，主要在游戏本体的代码中调用
function Map:IsVisualGroundAtPoint(x, y, z, ...)
    if TheWorld.components.interiorspawner and TheWorld.components.interiorspawner:IsInInteriorRegion(x, z) then
        return TheWorld.components.interiorspawner:IsInInteriorRoom(x, z)
    end
    if TheWorld.has_pl_ocean then
        return self:ReverseIsVisualGroundAtPoint(x, y, z)
    end
    return self:_IsVisualGroundAtPoint(x, y, z, ...)
end

local _IsAboveGroundAtPoint = Map.IsAboveGroundAtPoint
function Map:IsAboveGroundAtPoint(x, y, z, allow_water, ...)
    if TheWorld.components.interiorspawner and TheWorld.components.interiorspawner:IsInInteriorRegion(x, z) then
        return TheWorld.components.interiorspawner:IsInInteriorRoom(x, z)
    end
    if TheWorld.has_pl_ocean then
        local valid_water_tile = (allow_water == true) and self:ReverseIsVisualWaterAtPoint(x, y, z)
        return valid_water_tile or _IsAboveGroundAtPoint(self, x, y, z, ...)
    end
    return _IsAboveGroundAtPoint(self, x, y, z, ...)
end

local _CanDeployRecipeAtPoint = Map.CanDeployRecipeAtPoint
function Map:CanDeployRecipeAtPoint(pt, recipe, rot, player, ...)
    if recipe.aquatic and recipe.build_mode == BUILDMODE.WATER then
        local is_valid_ground = self:CanDeployAquaticAtPointInWater(pt, recipe.aquatic, player)
        return is_valid_ground and (recipe.testfn == nil or recipe.testfn(pt, rot)) and self:IsDeployPointClear(pt, nil, recipe.min_spacing or 3.2)
    end

    if recipe and pt and TheWorld.components.interiorspawner:IsInInteriorRegion(pt.x, pt.z) then
        if recipe.build_mode == BUILDMODE.HOME_DECOR then
            return true
        elseif not TheWorld.components.interiorspawner:IsInInteriorRoom(pt.x, pt.z, -1) then
            return false
        end
    end

    local x, y, z = pt:Get()
    if not self:ReverseIsVisualGroundAtPoint(x, y, z) or self:IsCloseToWater(x, y, z, 2.99) then
        return false
    end

    return _CanDeployRecipeAtPoint(self, pt, recipe, rot, player, ...)
end

local _CanPlantAtPoint = Map.CanPlantAtPoint
function Map:CanPlantAtPoint(x, y, z, ...)
    if not self:ReverseIsVisualGroundAtPoint(x, y, z) then
        return false
    end

    return _CanPlantAtPoint(self, x, y, z, ...)
end

local _CanDeployWallAtPoint = Map.CanDeployWallAtPoint
function Map:CanDeployWallAtPoint(pt, ...)
    local x, y, z = pt:Get()
    if not self:ReverseIsVisualGroundAtPoint(x, y, z) then
        return false
    end

    return _CanDeployWallAtPoint(self, pt, ...)
end

local _CanDeployAtPoint = Map.CanDeployAtPoint
function Map:CanDeployAtPoint(pt, ...)
    local x, y, z = pt:Get()
    if not self:ReverseIsVisualGroundAtPoint(x, y, z) then
        return false
    end

    return _CanDeployAtPoint(self, pt, ...)
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

local CANOPY_TILES = {
    [WORLD_TILES.GASJUNGLE] = true,
    [WORLD_TILES.DEEPRAINFOREST] = true,
}

function Map:IsVisualCanopyAtPoint(x, y, z, radius)
    local testradius = radius or 1.5
    local isclosetocanopy = TheWorld.Map:IsCloseToTile(x, y, z, testradius, function(_x, _y, _z)
        local tile = TheWorld.Map:GetTileAtPoint(_x, _y, _z)

        local clientundertile = TheWorld.components.clientundertile

        local coords_x, coords_y = TheWorld.Map:GetTileCoordsAtPoint(_x, _y, _z)

        if clientundertile then
            local old_tile = clientundertile:GetTileUnderneath(coords_x, coords_y)
            if old_tile then
                tile = old_tile
            end
        end

        return CANOPY_TILES[tile]
    end)

    return isclosetocanopy
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
        if TheWorld.components.interiorspawner:IsInInteriorRoom(x, z) then
            return WORLD_TILES.INTERIOR
        else
            return WORLD_TILES.IMPASSABLE
        end
    else
        return _GetTileAtPoint(self, x, y, z, ...)
    end
end

function Map:GetPointAtTile(x, y)
    local w, h = TheWorld.Map:GetSize()
    local tx = (x - w / 2) * TILE_SCALE
    local tz = (y - h / 2) * TILE_SCALE
    return tx, 0, tz
end

local _GetTile = Map.GetTile
function Map:GetTile(x, y, ...)
    local tx, _, tz = self:GetPointAtTile(x, y)
    if x and y and TheWorld.components.interiorspawner and TheWorld.components.interiorspawner:IsInInteriorRegion(tx, tz) then
        if TheWorld.components.interiorspawner:IsInInteriorRoom(tx, tz) then
            return WORLD_TILES.INTERIOR
        else
            return WORLD_TILES.IMPASSABLE
        end
    else
        return _GetTile(self, x, y, ...)
    end
end

local node_id_index_map
local _GetNodeIdAtPoint = Map.GetNodeIdAtPoint
function Map:GetNodeIdAtPoint(x, y, z, ...)
    if not TheWorld.topology.node_datas then
        return _GetNodeIdAtPoint(self, x, y, z, ...)
    end

    if not node_id_index_map then
        node_id_index_map = {}
        for i, node in pairs(TheWorld.topology.nodes) do
            node_id_index_map[TheWorld.topology.ids[i]] = i
        end
    end

    local coords_x, coords_y = self:GetTileCoordsAtPoint(x, y, z)
    for node_id, node_data in pairs(TheWorld.topology.node_datas) do
        if node_data.site_points.map[coords_x] and node_data.site_points.map[coords_x][coords_y] then
            return node_id_index_map[node_id] or 0
        end
    end

    return 0
end

function Map:GetIslandTagAtPoint(x, y, z)
    local on_land = self:IsLandTileAtPoint(x, 0, z)
    if not on_land then
        local pt = Vector3(x, y, z)
        local dest = FindNearbyLand(pt, 1)
        if dest then
            x, y, z = dest:Get()
        end
    end
    local node_index = self:GetNodeIdAtPoint(x, y, z)
    local node = TheWorld.topology.nodes[node_index]
    if node == nil or node.tags == nil then
        return nil
    end

    local island_tag = nil

    for _, v in ipairs(ISLAND_TAGS) do
        if table.contains(node.tags, v) then
            if island_tag == nil then
                island_tag = v
            else
                print("WARNING!!! There is overlap between two islands!!! (maybe more)")
            end
        end
    end

    return island_tag
end

function Map:FindPointByIslandTag(island_tag, num_tries, allow_water)
    num_tries = num_tries or 10000

    local found_island = false
    for _, v in pairs(ISLAND_TAGS) do
        if island_tag == v then
            found_island = true
            break
        end
    end

    if not found_island then
        print("WARNING!!! Cant find island with tag: ", island_tag)
        return nil
    end

    local topology = TheWorld.topology
    for i = 1, num_tries do
        local area = GetRandomItem(topology.nodes)
        if table.contains(area.tags, island_tag) then
            local points_x, points_y = TheWorld.Map:GetRandomPointsForSite(area.x, area.y, area.poly, 1)
            if #points_x == 1 and #points_y == 1
                and (allow_water or self:ReverseIsVisualGroundAtPoint(points_x[1], 0, points_y[1]))
                and not self:IsImpassableAtPoint(points_x[1], 0, points_y[1]) then
                return Vector3(points_x[1], 0, points_y[1])
            end
        end
    end

    print("WARNING!!! Cant find island after max trytimes!!!")

    return nil
end

function Map:IsWater(tile) -- 给几何mod用的
    return TileGroupManager:IsOceanTile(tile)
end

function Map:CalcPercentTilesAtPoint(x, y, z, radius, typefn)
    local coord_radius = (math.floor(radius / TILE_SCALE) + 1) * TILE_SCALE
    local num_tiles = 0
    local num_typetiles = 0
    for i = - coord_radius, coord_radius, TILE_SCALE do
        for j = - coord_radius, coord_radius, TILE_SCALE do
            if i * i + j * j < radius * radius then
                num_tiles = num_tiles + 1
                if typefn(x + i, 0, z + j) then
                    num_typetiles = num_typetiles + 1
                end
            end
        end
    end

    if num_tiles > 0 then
        return num_typetiles / num_tiles
    else
        return 0
    end
end

function Map:IsPhysicsClearAtPoint(pt, inst)
    local CANT_TAGS = {"INLIMBO", "NOCLICK", "FX"}
    local x, y, z = pt:Get()
    local ents = TheSim:FindEntities(x, y, z, MAX_PHYSICS_RADIUS, nil, CANT_TAGS)
    for _, ent in ipairs(ents) do
        if not (inst and ent == inst) then
            local radius = ent:GetPhysicsRadius(0)
            if ent:GetDistanceSqToPoint(x, y, z) < radius * radius then
                return false
            end
        end
    end
    return true
end
