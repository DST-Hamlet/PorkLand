local AddComponentPostInit = AddComponentPostInit
GLOBAL.setfenv(1, GLOBAL)

local PositionalWarp = require("components/positionalwarp")

local _GetHistoryPosition = PositionalWarp.GetHistoryPosition
function PositionalWarp:GetHistoryPosition(rewind, ...)
    local x, y, z = _GetHistoryPosition(self, rewind, ...)
    if x and z and TheWorld.components.interiorspawner and TheWorld.components.interiorspawner:IsInInteriorRegion(x, z)
        and not TheWorld.components.interiorspawner:IsInInterior(x, z) then
        return nil
    else
        return x, y, z
    end
end

AddComponentPostInit("positionalwarp", function(self, inst)
    inst:ListenForEvent("pl_clearfrominterior", function()
        self:Reset()
    end)
end)
