local MysteryDoor = Class(function(self, inst)
    self.inst = inst
end)

function MysteryDoor:Investigate(doer)
    if self.inst.door then
        doer.components.talker:Say(GetString(doer.prefab, "ANNOUNCE_MYSTERY_DOOR_FOUND"))
    else
        doer.components.talker:Say(GetString(doer.prefab, "ANNOUNCE_MYSTERY_DOOR_NOT_FOUND"))
    end
end

return MysteryDoor
