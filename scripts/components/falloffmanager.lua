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
    --["test"] =
    --{
    --    testfn = function(tile, adjacent_tile)
    --        if TileGroupManager:IsOceanTile(tile) and TileGroupManager:IsImpassableTile(adjacent_tile) then
    --            return true
    --        end
    --    end,
--
    --    id = 1,
--
    --    texture = "levels/tiles/dock_falloff.tex",
    --},
}

local falloff_id = 0
for name, data in pairs(FALLOFF_TYPES) do
    FALLOFF_TYPES[name].id = falloff_id
    falloff_id = falloff_id + 1
end

local offset_x = 0

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

-- PLAYER_CAMERA_SEE_DISTANCE (40) / TILE_SCALE (4) + 5 = 15
local REFRESH_RADIUS = (PLAYER_CAMERA_SEE_DISTANCE / TILE_SCALE) + 5

local function InitializeDataGrid(inst, data)
    inst.components.falloffmanager.cached_visual = DataGrid(data.width, data.height)
end

local FalloffManager = Class(function(self, inst)
    self.inst = inst

    self.falloffs = {}
    for i = 1, GetTableSize(FALLOFF_TYPES) do
        local id = i - 1
        self.falloffs[id] = {}
    end

    self.falloff_fx = SpawnPrefab("falloff_fx")

    self.falloff_fx:InitVFX(FALLOFF_TYPES)

    local w, h = TheWorld.Map:GetSize()
    self.cached_visual = DataGrid(w, h)
    self.inst:ListenForEvent("worldmapsetsize", InitializeDataGrid, TheWorld)

    self.inst.components.tilechangewatcher:ListenToUpdate(function()
        self:UpdateFalloffs()
    end)
end)

function FalloffManager:ClearFalloffs()
    for name, typedata in pairs(FALLOFF_TYPES) do
        self.falloff_fx:ClearFalloff(typedata.id)
    end
    self.falloffs = {}
    for i = 1, GetTableSize(FALLOFF_TYPES) do
        local id = i - 1
        self.falloffs[id] = {}
    end
end

function FalloffManager:SpawnFalloffs()
    for i = 1, GetTableSize(FALLOFF_TYPES) do
        local id = i - 1
        local datas = self.falloffs[id]
        if datas then
            for _, data in ipairs(datas) do
                self.falloff_fx:SpawnFalloff(id, data.position, data.angle, data.variant)
            end
        end
    end
end

function FalloffManager:OnRemoveEntity()
    self:ClearFalloffs()
    self.falloff_fx:Remove()
end

FalloffManager.OnRemoveFromEntity = FalloffManager.OnRemoveEntity

local function GetFalloffVariant(x, z)
    -- 将 x 和 y 组合成一个种子
    local seed = x * 127.1 + z * 311.7

    -- 使用简单的哈希算法生成伪随机值
    local random = math.sin(seed) * 43758.5453
    random = random - math.floor(random) -- 取小数部分

    -- 将随机值映射到 1 到 6 之间的整数
    return math.floor(random * 6) + 1
end

function FalloffManager:UpdateFalloffs()
    local use_cache = 0
    self:ClearFalloffs()
    if self.inst:GetIsInInterior() then
        return
    end
    local tilechangewatcher = self.inst.components.tilechangewatcher
    local current_tile_center = tilechangewatcher.last_tile_center
    for x = -REFRESH_RADIUS, REFRESH_RADIUS do
        for z = -REFRESH_RADIUS, REFRESH_RADIUS do
            local center = current_tile_center + Vector3(x * TILE_SCALE, 0, z * TILE_SCALE)
            local grid_x, grid_z = TheWorld.Map:GetTileCoordsAtPoint(center.x, center.y, center.z)
            if not TheWorld.Map:CheckInSize(grid_x, grid_z) then -- 在地图边界外

            elseif self.cached_visual:GetDataAtPoint(grid_x, grid_z) then -- 使用缓存的数据
                use_cache = use_cache + 1
                for i, v in ipairs(self.cached_visual:GetDataAtPoint(grid_x, grid_z)) do
                    table.insert(self.falloffs[v.id], v.data)
                end
            else
                local visual_datas = {}
                local tile = tilechangewatcher:CachedTileAtPoint(center.x, center.y, center.z)
                if tile then
                    for _, v in ipairs(adjacent) do
                        local adjacent_tile = tilechangewatcher:CachedTileAtPoint(center.x + v.x, center.y, center.z + v.z)
                        if adjacent then
                            for falloff_name, falloff_data in pairs(FALLOFF_TYPES) do
                                if falloff_data.testfn(tile, adjacent_tile) then
                                    local data = {
                                        position = Vector3(center.x + v.x / 2, center.y, center.z + v.z / 2),
                                        angle = v.angle,
                                        variant = GetFalloffVariant(center.x + v.x / 2, center.z + v.z / 2),
                                        name = falloff_name,
                                    }
                                    table.insert(self.falloffs[falloff_data.id], data)

                                    table.insert(visual_datas, {id = falloff_data.id,data = data})
                                end
                            end
                        end
                    end
                end
                self.cached_visual:SetDataAtPoint(grid_x, grid_z, visual_datas)
            end
        end
    end
    self:SpawnFalloffs()
    print("使用的缓存falloff数据：", use_cache)
end

return FalloffManager
