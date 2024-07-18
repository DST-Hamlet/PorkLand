local VisualShelfSlot = Class(function(self, inst)
    self.inst = inst
    self._item = net_entity(inst.GUID, "shelfslot._item")
    self._shelf = net_entity(inst.GUID, "shelfslot._shelf")
end)

function VisualShelfSlot:SetShelf(shelf)
    self._shelf:set(shelf)
end

function VisualShelfSlot:SetItem(item)
    self._item:set(item)
end

function VisualShelfSlot:GetItem()
    return self._item:value()
end

function VisualShelfSlot:GetShelf()
    return self._shelf:value()
end

return VisualShelfSlot
