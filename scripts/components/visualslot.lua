local master_postinitfns = require("main/special_visualslots").master_postinitfns

local function onslot(self, slot)
    self.inst.replica.visualslot:SetSlot(slot)
end

local function onitem(self, item)
    self.inst.replica.visualslot:SetItem(item)
end

local function onshelf(self, shelf)
    self.inst.replica.visualslot:SetShelf(shelf)
end

local VisualSlot = Class(function(self, inst)
    self.inst = inst
    self.slot = 1
    self.item = nil
    self.shelf = nil

    self.inst:AddTag("visual_slot")
end, nil, {
    slot = onslot,
    item = onitem,
    shelf = onshelf
})

function VisualSlot:SetShelf(shelf, slot)
    self.slot = slot
    self.shelf = shelf
end

function VisualSlot:SetItem(item)
    self.item = item
    if self.item == nil then
        self.inst:RemoveTag("inspectable")
        self.inst:AddTag("empty")
    else
        self.inst:AddTag("inspectable")
        self.inst:RemoveTag("empty")
    end
    self:SetArt()
end

function VisualSlot:GetShelf()
    return self.shelf
end

function VisualSlot:GetSlot()
    return self.slot
end

function VisualSlot:GetItem()
    return self.item
end

function VisualSlot:SetDefault()
    local slot_symbol = self.shelf:GetSlotSymbol(self.slot)
    self.inst.AnimState:SetBuild("visual_slot")
    self.inst.AnimState:SetBank(self.shelf.anim_def.slot_bank)
    self.inst.AnimState:PlayAnimation(slot_symbol)
end

function VisualSlot:SetArt()
    if self.shelf.anim_def.layer then
        self.inst.AnimState:SetLayer(self.shelf.anim_def.layer)
    end
    if self.shelf.anim_def.order then
        self.inst.AnimState:SetSortOrder(self.shelf.anim_def.layer)
    end
    self.inst.SetFinalOffset(1) -- 保证不会因为followsymbol的小概率奇怪bug而被挡住

    if self.item then
        local fn = master_postinitfns[self.item.prefab]
        self:SetDefault()
        self.inst.AnimState:OverrideSymbol("visual_slot", self.item.replica.inventoryitem:GetAtlas(), self.item.replica.inventoryitem:GetImage())
        if fn then
            fn(self.inst, self.shelf, self.slot, self.item)
        end
    else
        self:SetDefault()
        self.inst.AnimState:ClearOverrideSymbol("visual_slot")
    end
end

return VisualSlot
