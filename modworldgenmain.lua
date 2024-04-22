local modimport = modimport
GLOBAL.setfenv(1, GLOBAL)

local IsTheFrontEnd = rawget(_G, "TheFrontEnd") and rawget(_G, "IsInFrontEnd") and IsInFrontEnd()
if IsTheFrontEnd then
    modimport("main/strings")
end

modimport("scripts/map/locations/porkland")
modimport("scripts/map/startlocations/porkland")
modimport("scripts/map/tasksets/porklandset")
modimport("scripts/map/levels/porkland")

if IsTheFrontEnd then return end

require("map/pl_lockandkey")

modimport("main/toolutil")

modimport("main/tuning")

modimport("main/tiledefs")
modimport("postinit/map/task")
-- modimport("postinit/map/level")
modimport("postinit/map/node")
modimport("postinit/map/forest_map")

require("map/pl_layouts")
-- require("map/pl_boons")
-- require("map/pl_traps")
require("map/tasks/porkland")
