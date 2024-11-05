local RoomDemolisher = Class(function(self, inst)
    self.inst = inst
end)

function RoomDemolisher:DemolishRoom(doer, door_frame, permit)
    if not door_frame:HasTag("interior_door") then
        return false
    end

    local interior_spawner = TheWorld.components.interiorspawner
    local target_interior = door_frame.components.door.target_interior
    local coord_x, coord_y = target_interior:GetCoordinates()

    if door_frame:RoomCanBeRemoved() and not (coord_x == 0 and coord_y == 0) then
        interior_spawner:DemolishPlayerRoom(target_interior, door_frame:GetPosition())

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
