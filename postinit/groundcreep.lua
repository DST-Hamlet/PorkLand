GLOBAL.setfenv(1, GLOBAL)

local GroundCreep = GroundCreep

local _OnCreep = GroundCreep.OnCreep
function GroundCreep:OnCreep(x, y, z, ...)
    return _OnCreep(self, x, y, z, ...) and TheWorld.Map:ReverseIsVisualGroundAtPoint(x, y, z)
end

