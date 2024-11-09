local InteriorMapRevealer = Class(function(self, inst)
    self.inst = inst
    self.tracking_entities = {}
    -- self.inst:StartUpdatingComponent(self)
end)

local function on_tracked_entity_removed(inst)
    TheWorld.components.interiormaprevealer:UntrackEntity(inst)
end

function InteriorMapRevealer:TrackEntity(entity)
    self.tracking_entities[entity] = true
    entity:ListenForEvent("onremove", on_tracked_entity_removed)
end

function InteriorMapRevealer:UntrackEntity(entity)
    self.tracking_entities[entity] = nil
    entity:RemoveEventCallback("onremove", on_tracked_entity_removed)
end

-- function InteriorMapRevealer:OnUpdate()
--     local in_interior_players = {}
--     for _, player in ipairs(AllPlayers) do

--     end
-- end

return InteriorMapRevealer
