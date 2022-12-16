local GLOBAL = GLOBAL
GLOBAL.setfenv(1, GLOBAL)

--暂时没有大灾变
function GetAporkalypse()
    return false
end

GLOBAL.GetAporkalypse = GetAporkalypse

-- -- 清理掉太多的蚁人
-- function CleanUpMants()
--     local interior_spawner = TheWorld.components.interiorspawner
-- 	-- one time cleanup of surplus glowflies.
-- 	if TheWorld.culledMants then
-- 		return
-- 	end
-- 	print("Cleaning up stray Mants")
-- 	local count = 0
-- 	for i,v in pairs(Ents) do
-- 		if v.prefab == "antman" or v.prefab == "antman_warrior" then
-- 			if not v:HasTag("INTERIOR_LIMBO") then
-- 				-- it's not in interior limbo, so it's either current room or outside
-- 				if interior_spawner then
-- 					local pt = interior_spawner:getSpawnOrigin()
-- 					local pos = v:GetPosition()
-- 					local delta = (pos-pt):Length()
-- 					-- we're not in interior limbo, so we're either in the current room, or we are outside
-- 					if delta > 20 then
-- 						-- not in the current room, so we're outside
-- 						if not v.components.homeseeker then
-- 							-- we lost our home	.
-- 							count = count + 1
-- 							v:DoTaskInTime(0, function() v:Remove() end)
-- 						end
-- 					end
-- 				end
-- 			end
-- 		end
-- 	end
-- 	if count > 0 then
-- 		print(string.format("Removed %d stray mants", count))
-- 	end
-- 	TheWorld.culledMants = true
-- end
