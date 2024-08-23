local PLENV = env
GLOBAL.setfenv(1, GLOBAL)

local Grid = require ("widgets/grid")

function Grid:RebuildLayout(num_columns, coffset, roffset, items)
    self.items_by_coords = {}
    self.num_rows = math.ceil(#items / num_columns)
    self:UseNaturalLayout()
    self:InitSize(num_columns, self.num_rows, coffset, roffset)
    self:AddList(items)
end
