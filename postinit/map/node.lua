GLOBAL.setfenv(1, GLOBAL)

require("map/graphnode")

local SpawnUtil = require("map/spawnutil")

local obj_layout = require("map/object_layout")
local water_layout = require("map/water_layout")

local _AddEntity = Node.AddEntity
Node.AddEntity = function(self, prefab, points_x, points_y, current_pos_idx, entitiesOut, ...)
    if not self.is_porkland then
        return _AddEntity(self, prefab, points_x, points_y, current_pos_idx, entitiesOut, ...)
    end

    local tile = WorldSim:GetTile(points_x[current_pos_idx], points_y[current_pos_idx])

    if not self.pl_voronoi_entity_check or SpawnUtil.SpawntestFn(prefab, points_x[current_pos_idx], points_y[current_pos_idx], entitiesOut) then
        return PopulateWorld_AddEntity(prefab, points_x[current_pos_idx], points_y[current_pos_idx], tile, entitiesOut, ...)  -- thanks for tony
    end
end

local _PopulateVoronoi = Node.PopulateVoronoi
function Node:PopulateVoronoi(...)
    self.pl_voronoi_entity_check = true
    local ret = {_PopulateVoronoi(self, ...)}
    self.pl_voronoi_entity_check = false

    return unpack(ret)
end


local checkFn = function(ground) return IsOceanTile(ground) end
local _ConvertGround = Node.ConvertGround
function Node:ConvertGround(...)
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
