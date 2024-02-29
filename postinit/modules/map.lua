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

function Map:ReverseIsVisualGroundAtPoint(x, y, z)
    if not self:IsLandTileAtPoint(x, y, z) then
        return false
    end

    local center_x, _, center_z = self:GetTileCenterPoint(x, y, z)

    local offset_x = x - center_x
    local abs_offset_x = math.abs(offset_x)
    local near_x
    if abs_offset_x >= 1 then
        near_x = center_x + (offset_x > 0 and 1 or -1) * TILE_SCALE
        if self:IsOceanTileAtPoint(near_x, 0, center_z) then
            return false
        end
    end

    local offset_z = z - center_z
    local abs_offset_z = math.abs(offset_z)
    local near_z
    if abs_offset_z >= 1 then
        near_z = center_z + (offset_z > 0 and 1 or -1) * TILE_SCALE
        if self:IsOceanTileAtPoint(center_x, 0, near_z) then
            return false
        end
    end

    if near_x and near_z and abs_offset_z + abs_offset_x >= 3 then
        return not self:IsOceanTileAtPoint(near_x, 0, near_z)
    end

    return true
end

function Map:ReverseIsVisualWaterAtPoint(x, y, z)
    if self:IsOceanTileAtPoint(x, y, z) then
        return true
    end

    local center_x, _, center_z = self:GetTileCenterPoint(x, y, z)

    local offset_x = x - center_x
    local abs_offset_x = math.abs(offset_x)
    local near_x
    if abs_offset_x >= 1.5 then
        near_x = center_x + (offset_x > 0 and 1 or -1) * TILE_SCALE
        if self:IsOceanTileAtPoint(near_x, 0, center_z) then
            return true
        end
    end

    local offset_z = z - center_z
    local abs_offset_z = math.abs(offset_z)
    local near_z
    if abs_offset_z >= 1.5 then
        near_z = center_z + (offset_z > 0 and 1 or -1) * TILE_SCALE
        if self:IsOceanTileAtPoint(center_x, 0, near_z) then
            return true
        end
    end

    if near_x and near_z and abs_offset_z + abs_offset_x >= 3 then
        return self:IsOceanTileAtPoint(near_x, 0, near_z)
    end

    return false
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

-- local _CanDeployRecipeAtPoint = Map.CanDeployRecipeAtPoint
-- function Map:CanDeployRecipeAtPoint(pt, recipe, rot, ...)
--     if recipe.build_mode == BUILDMODE.AQUATIC then
--         local pt_x, pt_y, pt_z = pt:Get()
--         local is_valid_ground = self:ReverseIsVisualWaterAtPoint(pt_x, pt_y, pt_z)
--         return is_valid_ground and (recipe.testfn == nil or recipe.testfn(pt, rot))
--     end

--     return _CanDeployRecipeAtPoint(self, pt, recipe, rot, ...)
-- end
