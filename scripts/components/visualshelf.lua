
local function OnItemGet(inst, data)
    inst.components.visualshelf:SetVisualSlot(data.slot, data.item)
end

local function OnItemLose(inst, data)
    inst.components.visualshelf:SetVisualSlot(data.slot, nil)

    if data and data.prev_item then
        data.prev_item.replica.inventoryitem:SetOwner(nil)
    end
end

local function onenable(self, enable)
    if enable then
        self.inst:AddTag("canput")
    else
        self.inst:RemoveTag("canput")
    end
end

local VisualShelf = Class(function(self, inst)
    self.inst = inst
    self.visual_slots = {}
    self.enable = true

    self.inst:DoTaskInTime(0, function()
        self:OnEntityWake()
    end)

    inst:ListenForEvent("itemget", OnItemGet)
    inst:ListenForEvent("itemlose", OnItemLose)
end, nil, {
    enable = onenable
})

function VisualShelf:ForceOutOfLimbo(item)
    item:ForceOutOfLimbo(true)
    if item.Network ~= nil then
        item.Network:SetClassifiedTarget(nil)
    end
    if item.replica.inventoryitem.classified ~= nil then
        item.replica.inventoryitem.classified.Network:SetClassifiedTarget(nil)
    end
end

function VisualShelf:SetVisualSlot(slot, item)
    local slot_symbol = "SWAP_img" .. slot
    local visual_slot = self.visual_slots[slot]
    if not visual_slot then
        visual_slot = SpawnPrefab("visual_shelf_slot")
        visual_slot.components.visualshelfslot:SetShelf(self.inst, slot, slot_symbol)
        self.visual_slots[slot] = visual_slot
    end

    if item then
        self:ForceOutOfLimbo(item)
        self.inst.AnimState:OverrideSymbol(slot_symbol, item.replica.inventoryitem:GetAtlas(), item.replica.inventoryitem:GetImage())
    else
        self.inst.AnimState:ClearOverrideSymbol(slot_symbol)
    end

    visual_slot.components.visualshelfslot:SetItem(item)
end

function VisualShelf:OnEntitySleep()
    for slot, visual_slot in pairs(self.visual_slots) do
        visual_slot:Remove()
        self.visual_slots[slot] = nil
    end

    for slot, item in pairs(self.inst.components.container.slots) do
        item.replica.inventoryitem:SetOwner(nil)
    end
end

function VisualShelf:OnEntityWake()
    for i = 1, self.inst.components.container.numslots do
        local item = self.inst.components.container.slots[i]
        self:SetVisualSlot(i, item)
    end
end

return VisualShelf
