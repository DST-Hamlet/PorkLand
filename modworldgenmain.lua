local modimport = modimport
GLOBAL.setfenv(1, GLOBAL)

modimport("scripts/map/locations/porkland")
modimport("scripts/map/startlocations/porkland")
modimport("scripts/map/tasksets/porklandset")
modimport("scripts/map/levels/porkland")

local IsTheFrontEnd = rawget(_G, "TheFrontEnd") and rawget(_G, "IsInFrontEnd") and IsInFrontEnd()
if IsTheFrontEnd then return end

require("map/pl_lockandkey")

modimport("main/toolutil")

modimport("main/tuning")

modimport("main/tiledefs")
modimport("postinit/map/task")
-- modimport("postinit/map/level")
modimport("postinit/map/node")
modimport("postinit/map/forest_map")

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
