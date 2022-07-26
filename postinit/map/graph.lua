local IAENV = env
GLOBAL.setfenv(1, GLOBAL)

require("map/network")

Graph.PorklandConvertGround = Graph.ShipwreckedConvertGround or function(self, map, spawnFN, entities, check_col)
	local nodes = self:GetNodes(true)
	for k, node in pairs(nodes) do
		node:PorklandConvertGround(map, spawnFN, entities, check_col)
	end
end