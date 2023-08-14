local modimport = modimport
GLOBAL.setfenv(1, GLOBAL)

-- must use modimport to add, because dst bug
modimport("scripts/map/locations/porkland")
modimport("scripts/map/startlocations/porkland")
modimport("scripts/map/tasksets/porklandset")
modimport("scripts/map/levels/porkland")

local IsTheFrontEnd = rawget(_G, "TheFrontEnd") and rawget(_G, "IsInFrontEnd") and IsInFrontEnd()
if IsTheFrontEnd then
    return
end
-- when start worldgen

require("map/pl_lockandkey")
require("map/pl_map_tags")
require("map/porkland_map")

-- postinit
modimport("main/tuning")
modimport("main/tiledefs")

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
