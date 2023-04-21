-- must use modimport. Otherwise, it collapse will when mod is tuen on again
local modimport = modimport
GLOBAL.setfenv(1, GLOBAL)

modimport("scripts/map/locations/porkland")
modimport("scripts/map/startlocations/porkland")
modimport("scripts/map/tasksets/porklandset")
modimport("scripts/map/levels/porkland")

local IsTheFrontEnd = rawget(_G, "TheFrontEnd") and rawget(_G, "IsInFrontEnd") and IsInFrontEnd()
if IsTheFrontEnd then
    return
end
-- when start worldgen

-- postinit

modimport("main/pl_util")
modimport("main/tuning")
modimport("main/tiledefs")
modimport("main/spawnutil")

require("map/porkland_lockandkey")

modimport("postinit/map/task")
-- modimport("postinit/map/level")
modimport("postinit/map/graph")
modimport("postinit/map/node")
modimport("postinit/map/storygen")
modimport("postinit/map/forest_map")

-- require("map/porkland_layouts")
-- require("map/porkland_boons")
-- require("map/porkland_traps")

-- when we have layout, remove it
local _AddRoom = AddRoom
AddRoom = function(name, data)
    if data.contents then
        data.contents.countstaticlayouts = nil
    end
    _AddRoom(name, data)
end
local _AddTask = AddTask
AddTask = function(name, data)
    if data.set_pieces then
        data.set_pieces = nil
    end
    _AddTask(name, data)
end

require("map/tasks/porkland")
AddTask = _AddTask
AddRoom = _AddRoom
