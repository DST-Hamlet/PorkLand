local function onitem(self, item)
    self.inst.replica.visualshelfslot:SetItem(item)
end

local function onshelf(self, shelf)
    self.inst.replica.visualshelfslot:SetShelf(shelf)
end

local VisualShelfSlot = Class(function(self, inst)
    self.inst = inst
    self.slot = 1
    self.shelf = nil
    self.item = nil

    self.canputitem = true
end, nil, {
    item = onitem,
    shelf = onshelf
})

function VisualShelfSlot:SetShelf(shelf, slot)
    self.slot = slot
    self.shelf = shelf
end

function VisualShelfSlot:SetItem(item)
    self.item = item
    if self.item == nil then
        self.inst:RemoveTag("inspectable")
        self.inst:RemoveTag("canpick")
    else
        self.inst:AddTag("inspectable")
        self.inst:AddTag("canpick")
    end
end

function VisualShelfSlot:GetSlot()
    return self.slot
end

return VisualShelfSlot
