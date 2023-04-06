GLOBAL.setfenv(1, GLOBAL)

local Pollinator = require("components/pollinator")

local _CheckFlowerDensity = Pollinator.CheckFlowerDensity
function Pollinator:CheckFlowerDensity(...)
    local x, y, z = self.inst.Transform:GetWorldPosition()
    local tile = TheWorld.Map:GetTileAtPoint(x, y, z)
    if tile == WORLD_TILES.INTERIOR then
        return false
    end

    return _CheckFlowerDensity(self, ...)
end
