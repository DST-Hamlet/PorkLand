local REGION_SIZE = 7
local MIN_REGION_SEE_DIST = 2.4
local MAX_REGION_SEE_DIST = 3
local MAX_CAMERA_SEE_DIST_SQ = (REGION_SIZE * MAX_REGION_SEE_DIST * TILE_SCALE) * (REGION_SIZE * MAX_REGION_SEE_DIST * TILE_SCALE)
local MIN_CAMERA_SEE_DIST_SQ = (REGION_SIZE * MIN_REGION_SEE_DIST * TILE_SCALE) * (REGION_SIZE * MIN_REGION_SEE_DIST * TILE_SCALE)

local function InitializeDataGrid(inst, data)
    inst.components.falloffmanager.cached_visual = DataGrid(data.width, data.height)
    inst.components.falloffmanager.cached_fxs = DataGrid(math.floor(data.width / REGION_SIZE), math.floor(data.height / REGION_SIZE))
end

local PL_TileManager = Class(function(self, inst)
    self.inst = inst

    local w, h = TheWorld.Map:GetSize()
    self.cached_visual = DataGrid(w, h)
    self.cached_fxs = DataGrid(math.floor(w / REGION_SIZE), math.floor(h / REGION_SIZE))
    self.inst:ListenForEvent("worldmapsetsize", InitializeDataGrid, TheWorld)

    self.tile_fxs = {}

    self.inst.components.tilechangewatcher:ListenToUpdate(function()
        self:UpdateTiles()
    end)
    self.inst.components.tilechangewatcher:ListenToTileChanged(function(data)
        self:OnTileChanged(data)
    end)
end)

function PL_TileManager:OnRemoveEntity()

end

PL_TileManager.OnRemoveFromEntity = PL_TileManager.OnRemoveEntity

function PL_TileManager:GetNewTileFx()
    for fx, data in pairs(self.tile_fxs) do
        if data.canreuse == true then
            return fx
        end
    end
    local fx = SpawnPrefab("tile_fx")
    self.tile_fxs[fx] = {canreuse = true}
    return fx
end

function PL_TileManager:UpdateTiles()
    if self.inst:GetIsInInterior() then
        return
    end
    local tilechangewatcher = self.inst.components.tilechangewatcher
    local current_tile_center = tilechangewatcher.last_tile_center

    for fx, data in pairs(self.tile_fxs) do
        if data.x then
            local pt = Vector3(TheWorld.Map:GetPointAtTile(data.x * REGION_SIZE, data.z * REGION_SIZE))
            if self.inst:GetDistanceSqToPoint(pt) > MAX_CAMERA_SEE_DIST_SQ then
                fx.components.pl_tilespawner:ClearTiles()
                self.cached_fxs:SetDataAtPoint(self.tile_fxs[fx].x, self.tile_fxs[fx].z, nil)
                self.tile_fxs[fx] = {canreuse = true}
            end
        end
    end

    TheSim:ProfilerPush("PL_TileManager:Calculate TileFx")
    for x = -MAX_REGION_SEE_DIST, MAX_REGION_SEE_DIST do
        for z = -MAX_REGION_SEE_DIST, MAX_REGION_SEE_DIST do
            local center = current_tile_center + Vector3(x * REGION_SIZE * TILE_SCALE, 0, z * REGION_SIZE * TILE_SCALE)
            local grid_x, grid_z = TheWorld.Map:GetTileCoordsAtPoint(center.x, center.y, center.z)
            if TheWorld.Map:CheckInSize(grid_x, grid_z) then

                grid_x, grid_z = math.floor(grid_x / REGION_SIZE), math.floor(grid_z / REGION_SIZE)
                center = Vector3(TheWorld.Map:GetPointAtTile(grid_x * REGION_SIZE, grid_z * REGION_SIZE))

                if self.inst:GetDistanceSqToPoint(center) < MIN_CAMERA_SEE_DIST_SQ then
                    local fx = self.cached_fxs:GetDataAtPoint(grid_x, grid_z) 
                    if fx == nil then
                        fx = self:GetNewTileFx()
                        self.cached_fxs:SetDataAtPoint(grid_x, grid_z, fx)
                        self.tile_fxs[fx] = {x = grid_x, z = grid_z, need_update = true}
                    end
                end
            end
        end
    end
    TheSim:ProfilerPop()

    TheSim:ProfilerPush("PL_TileSpawner:SpawnVFX")
    for tile_fx, data in pairs(self.tile_fxs) do
        if data.need_update and not data.canreuse then
            local pt = Vector3(TheWorld.Map:GetPointAtTile(data.x * REGION_SIZE, data.z * REGION_SIZE))
            tile_fx.components.pl_tilespawner:UpdateTiles(pt)
            data.need_update = false
        end
    end
    TheSim:ProfilerPop()
end

function PL_TileManager:OnTileChanged(data)
    if data and data.x and data.y then
        self.cached_visual:SetDataAtPoint(data.x, data.y, nil)
        for dir, v in pairs(PL_NEIGHBOR_TILES) do
            if TheWorld.Map:CheckInSize(data.x + v.x, data.y + v.z) then
                self.cached_visual:SetDataAtPoint(data.x + v.x, data.y + v.z, nil)
            end
        end
    end
end

return PL_TileManager
