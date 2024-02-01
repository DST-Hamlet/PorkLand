GLOBAL.setfenv(1, GLOBAL)
require("map/graphnode")

-- local NodeAddEntity = Node.AddEntity
-- Node.AddEntity = function(self, prefab, points_x, points_y, current_pos_idx, entitiesOut, ...)
-- if SpawntestFn(prefab, points_x[current_pos_idx], points_y[current_pos_idx], entitiesOut) then  -- thanks for tony
--         return NodeAddEntity(self, prefab, points_x, points_y, current_pos_idx, entitiesOut, ...)
--     end
-- end

local checkFn = function(ground) return IsOceanTile(ground) end
local _ConvertGround = Node.ConvertGround
function Node:ConvertGround(...)
    local no_water = self.data.type == nil or self.data.type ~= "water"

    local obj_layout = require("map/object_layout")
    local _Convert = obj_layout.Convert
    function obj_layout.Convert(node_id, item, addEntity, ...)
        local layout = obj_layout.LayoutForDefinition(item)
        if layout.water and no_water then
            PlaceWaterLayout(layout, prefabs, addEntity, checkFn)
        else
            -- layout.border = layout.border or 1  -- dst no this
            _Convert(node_id, item, addEntity, ...)
        end
    end

    _ConvertGround(self, ...)

    obj_layout.Convert = _Convert
end
