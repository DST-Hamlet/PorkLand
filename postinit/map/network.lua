GLOBAL.setfenv(1, GLOBAL)

require("map/network")

print("load network")

local _PopulateVoronoi = Graph.PopulateVoronoi
function Graph:PopulateVoronoi(spawnFN, entities, width, height, world_gen_choices, prefabDensities, ...)
    if not self.is_porkland then
        return _PopulateVoronoi(self, spawnFN, entities, width, height, world_gen_choices, prefabDensities, ...)
    end

    local nodes = self:GetNodes(false)
	for k,node in pairs(nodes) do
		node:PopulateVoronoi(spawnFN, entities, width, height, world_gen_choices, prefabDensities)
		local perTerrain = false
		if type(self.data.background) == type({}) then
			perTerrain = true
		end
		local backgroundRoom = self:GetBackgroundRoom(self.data.background)
		node:PopulateChildren(spawnFN, entities, width, height, backgroundRoom, perTerrain, world_gen_choices)
	end
	for k,child in pairs(self:GetChildren()) do
		child:PopulateVoronoi(spawnFN, entities, width, height, world_gen_choices, prefabDensities)
	end
end

function Graph:HasRoomTag(tagname)
    return table.contains(self.room_tags, tagname)
end
