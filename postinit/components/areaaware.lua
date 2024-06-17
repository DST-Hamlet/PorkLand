GLOBAL.setfenv(1, GLOBAL)

local AreaAware = require("components/areaaware")

local _UpdatePosition = AreaAware.UpdatePosition
function AreaAware:UpdatePosition(x, y, z, ...)
    if TheWorld.components.interiorspawner and TheWorld.components.interiorspawner:IsInInteriorRegion(x, z) then
        self.lastpt.x, self.lastpt.z = x, z
        if self.current_area_data ~= nil then
            self.current_area = -1
            self.current_area_data = nil
            self.inst:PushEvent("changearea", self:GetCurrentArea())
        end
        return
    end

    return _UpdatePosition(self,x, y, z, ...)
end
