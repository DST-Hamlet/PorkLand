GLOBAL.setfenv(1, GLOBAL)

local MapRecorder = require("components/maprecorder")

local record_map = MapRecorder.RecordMap
function MapRecorder:RecordMap(target, ...)
    local success, reason = record_map(self, target, ...)
    if success then
        -- TODO: Implement this
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
        -- TODO: Implement this
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

