local obj_layout = require("map/object_layout")

local Pl_Boons = {}

local function AddBoons(area, name)
    if not Pl_Boons[area] then
        Pl_Boons[area] = {}
    end

    table.insert(Pl_Boons[area], name)
    obj_layout.AddLayoutToSanbox("map/boons", area, name)
end

return Pl_Boons
