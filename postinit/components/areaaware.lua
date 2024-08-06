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

function AreaAware:GetDebugString() -- 替换原函数以避免调试崩溃
    local node = TheWorld.topology.nodes[self.current_area]
    if node then
        local s = string.format("%s: %s [%d]",tostring(TheWorld.topology.ids[self.current_area]), table.reverselookup(NODE_TYPE, node.type) or "", self.current_area)
        if node.tags then
            s = string.format("%s, {%s}", s, table.concat(node.tags, ", "))
        else
            s = string.format("%s, No tags.", s)
        end
        return s
    else
        local x, y = TheWorld.Map:GetTileCoordsAtPoint(self.inst.Transform:GetWorldPosition())
        return "No current node: "..x..", "..y
    end
end
