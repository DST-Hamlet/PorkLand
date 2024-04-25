GLOBAL.setfenv(1, GLOBAL)

require("map/graphnode")

local SpawnUtil = require("map/spawnutil")

local obj_layout = require("map/object_layout")
local water_layout = require("map/water_layout")

local water_prefabs = {
}

local land_prefabs = {
    "grass_tall"
}

local common_spawnfn = {
    grass_tall_bunche_patch = function(x, y, ents)
        return not SpawnUtil.IsCloseToWaterTile(x, y, 3)
    end,
}

local function SurroundedByWater(x, y, ents)
    return SpawnUtil.IsSurroundedByWaterTile(x, y, 1)
end

local function NotCloseToWater(x, y, ents)
    return not SpawnUtil.IsCloseToWaterTile(x, y, 1)
end

-- Mod support
function SpawnUtil.AddCommonSpawnTestFn(prefab, fn)
    common_spawnfn[prefab] = fn
end

function SpawnUtil.AddWaterPrefabSpawnTest(prefab)
    assert(common_spawnfn[prefab] == nil)  -- don't replace an existing one
    SpawnUtil.AddCommonSpawnTestFn(prefab, SurroundedByWater)
end

function SpawnUtil.AddLandPrefabSpawnTest(prefab)
    assert(common_spawnfn[prefab] == nil)  -- don't replace an existing one
    SpawnUtil.AddCommonSpawnTestFn(prefab, NotCloseToWater)
end

for i = 1, #water_prefabs do
    SpawnUtil.AddWaterPrefabSpawnTest(water_prefabs[i])
end

for i = 1, #land_prefabs do
    SpawnUtil.AddLandPrefabSpawnTest(land_prefabs[i])
end

local function SpawntestFn(prefab, x, y, ents)
    return prefab ~= nil and (common_spawnfn[prefab] == nil or common_spawnfn[prefab](x, y, ents))
end

local _AddEntity = Node.AddEntity
Node.AddEntity = function(self, prefab, points_x, points_y, current_pos_idx, entitiesOut, ...)
    if not self.is_porkland then
        return _AddEntity(self, prefab, points_x, points_y, current_pos_idx, entitiesOut, ...)
    end

    local tile = WorldSim:GetTile(points_x[current_pos_idx], points_y[current_pos_idx])
    return PopulateWorld_AddEntity(prefab, points_x[current_pos_idx], points_y[current_pos_idx], tile, entitiesOut, ...)
end

local function Pl_PopulateVoronoi_AddEntity(self, prefab, points_x, points_y, current_pos_idx, entitiesOut, ...)
    local tile = WorldSim:GetTile(points_x[current_pos_idx], points_y[current_pos_idx])
    if SpawntestFn(prefab, points_x[current_pos_idx], points_y[current_pos_idx], entitiesOut) then
        return PopulateWorld_AddEntity(prefab, points_x[current_pos_idx], points_y[current_pos_idx], tile, entitiesOut, ...)
    end
end

local _PopulateVoronoi = Node.PopulateVoronoi
function Node:PopulateVoronoi(...)
    if not self.is_porkland then
        return _PopulateVoronoi(self, ...)
    end

    local _AddEntity = self.AddEntity
    self.AddEntity = Pl_PopulateVoronoi_AddEntity
    _PopulateVoronoi(self, ...)
    self.AddEntity = _AddEntity
end

local _ConvertGround = Node.ConvertGround
function Node:ConvertGround(...)
    local checkFn = function(ground) return IsOceanTile(ground) end
    local no_water = self.data.type == nil or self.data.type ~= "water"

    local _Convert = obj_layout.Convert
    function obj_layout.Convert(node_id, item, addEntity, ...)
        local layout = obj_layout.LayoutForDefinition(item)
        if layout.water and no_water then
            local prefabs = obj_layout.ConvertLayoutToEntitylist(layout)
            water_layout.PlaceWaterLayout(layout, prefabs, addEntity, checkFn)
        else
            -- layout.border = layout.border or 1  -- dst no this
            _Convert(node_id, item, addEntity, ...)
        end
    end

    _ConvertGround(self, ...)

    obj_layout.Convert = _Convert
end
