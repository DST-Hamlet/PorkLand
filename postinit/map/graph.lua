GLOBAL.setfenv(1, GLOBAL)
require("map/network")

Graph.PorkLandConvertGround = function(self, map, spawnFN, entities, check_col)
	local nodes = self:GetNodes(true)
	for k, node in pairs(nodes) do
		node:PorkLandConvertGround(map, spawnFN, entities, check_col)
	end
end
