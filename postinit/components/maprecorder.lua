local AddComponentPostInit = AddComponentPostInit
GLOBAL.setfenv(1, GLOBAL)

local MapRecorder = require("components/maprecorder")

local record_map = MapRecorder.RecordMap
function MapRecorder:RecordMap(target, ...)
    local success, reason = record_map(self, target, ...)
    if success then
        if target.components.interiorvisitor then
            self.interior_map_data = {
                interior_map = deepcopy(target.components.interiorvisitor.interior_map),
                room_visited_time = deepcopy(target.components.interiorvisitor.room_visited_time),
            }
        end
    end
    return success, reason
end

local clear_map = MapRecorder.ClearMap
function MapRecorder:ClearMap(target, ...)
    self.interior_map_data = nil
    return clear_map(self, target, ...)
end

local teach_map = MapRecorder.TeachMap
function MapRecorder:TeachMap(target, ...)
    local success, reason = teach_map(self, target, ...)
    if success then
        local interiorvisitor = target.components.interiorvisitor
        if interiorvisitor and self.interior_map_data then
            for id, map_data in pairs(self.interior_map_data.interior_map) do
                if not interiorvisitor.interior_map[id] or interiorvisitor.room_visited_time[id] < self.interior_map_data.room_visited_time[id] then
                    interiorvisitor:RecordMap(id, map_data)
                end
            end
        end
    end
    return success, reason
end

local on_save = MapRecorder.OnSave
function MapRecorder:OnSave(...)
    local data, refs = on_save(self, ...)
    data.interior_map_data = self.interior_map_data
    return data, refs
end

local on_load = MapRecorder.OnLoad
function MapRecorder:OnLoad(data, ...)
    if data and data.interior_map_data then
        self.interior_map_data = data.interior_map_data
    end
    return on_load(self, data, ...)
end

AddComponentPostInit("maprecorder", function(self)
    self.record_map_on_room_removal = function(_, data)
        if self.interior_map_data then
            self.interior_map_data.interior_map[data.id] = nil
            self.interior_map_data.room_visited_time[data.id] = nil
        end
    end
    self.inst:ListenForEvent("room_removed", self.record_map_on_room_removal, TheWorld)
end)

local on_remove_from_entity = MapRecorder.OnRemoveFromEntity or function() end
function MapRecorder:OnRemoveFromEntity(...)
    self.inst:RemoveEventCallback("room_removed", self.record_map_on_room_removal, TheWorld)
    return on_remove_from_entity(self, ...)
end
