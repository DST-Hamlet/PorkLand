local obj_layout = require("map/object_layout")

local Pl_Traps = {}

local function AddTraps(area, name)
    if not Pl_Traps[area] then
        Pl_Traps[area] = {}
    end

    table.insert(Pl_Traps[area], name)
    obj_layout.AddLayoutToSanbox("map/traps", area, name)
end

return Pl_Traps
