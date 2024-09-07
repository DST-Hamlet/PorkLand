local RoomDemolisher = Class(function(self, inst)
    self.inst = inst
end)

function RoomDemolisher:DemolishRoom(doer, door_frame, permit)
    if not door_frame:HasTag("interior_door") then
        return false
    end

    local interior_spawner = TheWorld.components.interiorspawner
    local target_interior = door_frame.components.door.target_interior
    local index_x, index_y = interior_spawner:GetPlayerRoomIndexByID(interior_spawner:GetPlayerHouseByRoomID(target_interior), target_interior)

    if door_frame:CanBeRemoved() and not (index_x == 0 and index_y == 0) then
        -- TODO clear contents to exterior
        interior_spawner:ClearInteriorContents(interior_spawner:GetInteriorCenter(target_interior):GetPosition(), door_frame:GetPosition())

        local fx = SpawnPrefab("collapse_small")
        fx.Transform:SetPosition(door_frame.Transform:GetWorldPosition())
        fx:SetMaterial("wood")

        if permit then
            permit:Remove()
        end

        door_frame:DeactivateSelf()
    else
        doer.components.talker:Say(GetString(doer.prefab, "ANNOUNCE_ROOM_STUCK"))
    end

    return true
end

return RoomDemolisher
