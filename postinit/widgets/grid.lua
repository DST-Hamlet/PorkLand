local PLENV = env
GLOBAL.setfenv(1, GLOBAL)

local Grid = require ("widgets/grid")

function Grid:RebuildLayout(num_columns, coffset, roffset, items)
    self.items_by_coords = {}
    self:FillGrid(num_columns, coffset, roffset, items)
end
