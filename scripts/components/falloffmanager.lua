local FALLOFF_TYPES =
{
    ["mud"] =
    {
        testfn = function(tile, adjacent_tile)
            if TileGroupManager:IsLandTile(tile) and not TileGroupManager:IsLandTile(adjacent_tile) then
                return true
            end
        end,

        texture = "levels/tiles/falloff.tex",
    },
    -- ["test"] =
    -- {
        -- testfn = function(tile, adjacent_tile)
            -- if TileGroupManager:IsOceanTile(tile) and TileGroupManager:IsImpassableTile(adjacent_tile) then
                -- return true
            -- end
        -- end,

        -- texture = "levels/tiles/dock_falloff.tex",
    -- },
}

-- PLAYER_CAMERA_SEE_DISTANCE (40) / TILE_SCALE (4) = 10
local REFRESH_RADIUS = (PLAYER_CAMERA_SEE_DISTANCE / TILE_SCALE) + 5

local FalloffManager = Class(function(self, inst)
    self.inst = inst

    self.falloffs = {}

    self.falloff_fxs = {}

    for name, data in pairs(FALLOFF_TYPES) do
        self.falloff_fxs[name] = SpawnPrefab("falloff_fx")
        self.falloff_fxs[name]:SetTexture(data.texture)
    end

    self.inst.components.tilechangewatcher:ListenToUpdate(function()
        self:UpdateFalloffs()
    end)
end)

function FalloffManager:ClearFalloffs()
    for _, fx_inst in pairs(self.falloff_fxs) do
        fx_inst:ClearVFX()
    end
    self.falloffs = {}
end

function FalloffManager:SpawnFalloffs()
    for _, data in ipairs(self.falloffs) do
        self.falloff_fxs[data.name]:SpawnFalloff(data.position, data.angle, data.variant)
    end
end

function FalloffManager:OnRemoveEntity()
    self:ClearFalloffs()
end

FalloffManager.OnRemoveFromEntity = FalloffManager.OnRemoveEntity

local offset_x = 0.01

local adjacent = {
    {
        x = TILE_SCALE + offset_x,
        z = 0,
        angle = 0,
    },
    {
        x = -(TILE_SCALE + offset_x),
        z = 0,
        angle = 180,
    },
    {
        x = 0,
        z = TILE_SCALE + offset_x,
        angle = 270,
    },
    {
        x = 0,
        z = -(TILE_SCALE + offset_x),
        angle = 90,
    },
}

local function GetFalloffVariant(x, z)
    return math.floor(((x * 73856093 + bit.bxor(z, 19349663)) % 6) + 1)
end

function FalloffManager:UpdateFalloffs()
    self:ClearFalloffs()
    local current_tile_center = self.last_tile_center
    for x = -REFRESH_RADIUS, REFRESH_RADIUS do
        for z = -REFRESH_RADIUS, REFRESH_RADIUS do
            local center = current_tile_center + Vector3(x * TILE_SCALE, 0, z * TILE_SCALE)
            local tile = TheWorld.Map:GetTileAtPoint(center.x, center.y, center.z)
            if tile then
                for _, v in ipairs(adjacent) do
                    local adjacent_tile = TheWorld.Map:GetTileAtPoint(center.x + v.x, center.y, center.z + v.z)
                    if adjacent then
                        for falloff_name, falloff_data in pairs(FALLOFF_TYPES) do
                            if falloff_data.testfn(tile, adjacent_tile) then
                                table.insert(self.falloffs, {
                                    position = Vector3(center.x + v.x / 2, center.y, center.z + v.z / 2),
                                    angle = v.angle,
                                    variant = GetFalloffVariant(center.x + v.x / 2, center.z + v.z / 2),
                                    name = falloff_name,
                                })
                            end
                        end
                    end
                end
            end
        end
    end
    self:SpawnFalloffs()
end

return FalloffManager
