GLOBAL.setfenv(1, GLOBAL)

local AreaAware = require "components/areaaware"

local Old_GetDebugString = AreaAware.GetDebugString
function AreaAware:GetDebugString(...)
    local node = TheWorld.topology.nodes[self.current_area]
    if node then
        local s = string.format("%s: %s [%d]",tostring(TheWorld.topology.ids[self.current_area]), tostring(table.reverselookup(NODE_TYPE, node.type)), self.current_area)
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
