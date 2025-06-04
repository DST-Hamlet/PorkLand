local InteriorHudIndicatableManager = Class(function(self, inst)
    self.inst = inst
    self.markers = {}
end)

function InteriorHudIndicatableManager:UpdateMarker(id, data)
    if self.markers[id] then
        self.markers[id].marker_data = data
    else
        local marker = SpawnPrefab("target_indicator_marker")
        marker.marker_data = data
        self.markers[id] = marker
    end
end

function InteriorHudIndicatableManager:RemoveMarker(id)
    if self.markers[id] then
        self.markers[id]:Remove()
        self.markers[id] = nil
    end
end

function InteriorHudIndicatableManager:ClearMarkers()
    for _, marker in pairs(self.markers) do
        marker:Remove()
    end
    self.markers = {}
end

-- Receiving from `update_hud_indicatable_entities` client RPC
function InteriorHudIndicatableManager:OnInteriorHudIndicatableData(data)
    for _, action in ipairs(data) do
        if action.type == "delete" then
            self:RemoveMarker(action.data)
        elseif action.type == "replace" then
            self:UpdateMarker(action.data.id, action.data)
        elseif action.type == "clear" then
            self:ClearMarkers()
        end
    end
end

return InteriorHudIndicatableManager
