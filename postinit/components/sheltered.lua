GLOBAL.setfenv(1, GLOBAL)

local Sheltered = require("components/sheltered")

local _SetSheltered = Sheltered.SetSheltered
function Sheltered:SetSheltered(issheltered, level, ...)
    local _sheltered = issheltered
    local _level = level
    local x, y, z = self.inst.Transform:GetWorldPosition()
    if TheWorld.Map:IsVisualCanopyAtPoint(x, y, z) then
        _sheltered = true
        _level = 2
    end
    return _SetSheltered(self, _sheltered, _level, ...)
end
