local modimport = modimport
GLOBAL.setfenv(1, GLOBAL)

modimport("main/tuning")
modimport("main/tiledefs")
modimport("main/spawnutil")

require("map/porkland_lockandkey")

modimport("postinit/map/task")
-- modimport("postinit/map/level")
modimport("postinit/map/graph")
modimport("postinit/map/node")
modimport("postinit/map/maptags")
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
