local RoomDemolisher = Class(function(self, inst)
    self.inst = inst
end)

function RoomDemolisher:DemolishRoom(doer, door_frame, permit)
    if not door_frame:HasTag("interior_door") then
        return false
    end

    local interior_spawner = TheWorld.components.interiorspawner
    local target_interior = door_frame.components.door.target_interior
    local house_id = interior_spawner:GetPlayerHouseByRoomId(target_interior)
    local index_x, index_y = interior_spawner:GetPlayerRoomIndexById(house_id, target_interior)

    if door_frame:RoomCanBeRemoved() and not (index_x == 0 and index_y == 0) then
        interior_spawner:DemolishPlayerRoom(target_interior, door_frame:GetPosition())
        interior_spawner:UnregisterPlayerRoom(house_id, target_interior)

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
