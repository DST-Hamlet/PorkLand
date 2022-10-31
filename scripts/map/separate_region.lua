local islandRegionMapping = {}
local function AddIslandRegionMapping(name, ident)
	islandRegionMapping[name] = ident
end

AddIslandRegionMapping("START", 						"A")
AddIslandRegionMapping("Edge_of_the_unknown", 			"A")
AddIslandRegionMapping("painted_sands", 				"A")
AddIslandRegionMapping("plains", 						"A")
AddIslandRegionMapping("rainforests", 					"A")
AddIslandRegionMapping("rainforest_ruins", 				"A")
AddIslandRegionMapping("plains_ruins", 					"A")
AddIslandRegionMapping("Edge_of_civilization", 			"A")
AddIslandRegionMapping("Deep_rainforest", 				"A")
AddIslandRegionMapping("Pigtopia", 						"A")
AddIslandRegionMapping("Pigtopia_capital", 				"A")
AddIslandRegionMapping("Deep_lost_ruins_gas", 			"A")
AddIslandRegionMapping("Edge_of_the_unknown_2", 		"A")
AddIslandRegionMapping("Lilypond_land", 				"A")
AddIslandRegionMapping("Lilypond_land_2", 				"A")
AddIslandRegionMapping("this_is_how_you_get_ants", 		"A")
AddIslandRegionMapping("Deep_rainforest_2", 			"A")
AddIslandRegionMapping("Lost_Ruins_1", 					"A")
AddIslandRegionMapping("Lost_Ruins_4", 					"A")

AddIslandRegionMapping("Deep_rainforest_3", 			"B")
AddIslandRegionMapping("Deep_rainforest_mandrake", 		"B")
AddIslandRegionMapping("Path_to_the_others", 			"B")
AddIslandRegionMapping("Other_edge_of_civilization", 	"B")
AddIslandRegionMapping("Other_pigtopia", 				"B")
AddIslandRegionMapping("Other_pigtopia_capital", 		"B")

AddIslandRegionMapping("Deep_lost_ruins4", 				"C")
AddIslandRegionMapping("lost_rainforest", 				"C")

AddIslandRegionMapping("pincale", 						"E")

AddIslandRegionMapping("Deep_wild_ruins4", 				"F")
AddIslandRegionMapping("wild_rainforest", 			    "F")
AddIslandRegionMapping("wild_ancient_ruins", 			"F")

local function separate_region(nodes, dist)
	local RegionMapping = {}
	for node_id, node in pairs(nodes) do
		local pos = string.find(node_id, ":")
		local task = pos and string.sub(node_id, 0, pos - 1) or node_id
		local points_x, points_y, points_type = WorldSim:GetPointsForSite(node.id)
		if #points_x ~= 0 then
			for i = 1, #points_x, 1 do
				local x, y = points_x[i], points_y[i]
				RegionMapping[x] = RegionMapping[x] or {}
				RegionMapping[x][y] = islandRegionMapping[task]
				-- WorldSim:SetTile(x, y, WORLD_TILES.GASJUNGLE)
			end
		end
	end

	for x, y_data in pairs(RegionMapping) do
		for y, ident in pairs(y_data) do
			for i = -dist, dist do
				for j = -dist, dist do
					local _x, _y = x + i, y + j
					if RegionMapping[_x] and RegionMapping[_x][_y] and RegionMapping[_x][_y] ~= RegionMapping[x][y] and WorldSim:GetTile(_x, _y) ~= WORLD_TILES.IMPASSABLE then
						WorldSim:SetTile(_x, _y, WORLD_TILES.IMPASSABLE)
						RegionMapping[_x][_y] = nil
					end
				end
			end

			RegionMapping[x][y] = nil
		end
	end
end

return separate_region