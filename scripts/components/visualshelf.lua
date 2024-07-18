
local function OnItemGet(inst, data)
    inst.components.visualshelf:GetItem(data.slot, data.item)
end

local function OnItemLose(inst, data)
    inst.components.visualshelf:LoseItem(data.slot, data.prev_item)
end

local function onenable(self, enable)
    if enable then
        self.inst:AddTag("canput")
    else
        self.inst:RemoveTag("canput")
    end
end

local VisualShelf = Class(function(self, inst)
    assert(inst.components.container ~= nil)

    self.inst = inst

    self.visual_slots = {}
    self.slot_visualitems = {}
    self.slot_listeners = {}

    self.enable = true

    for i = 1, self.inst.components.container.numslots do
        self.slot_listeners[i] = function()
            self:DrawSlot(i, self.inst.components.container.slots[i])
        end
    end

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

function VisualShelf:GetSlotSymbol(slot)
    return "SWAP_img" .. slot
end

function VisualShelf:DrawSlot(slot, item)
    local slot_symbol = self:GetSlotSymbol(slot)

    if item then
        self.inst.AnimState:OverrideSymbol(slot_symbol, item.replica.inventoryitem:GetAtlas(), item.replica.inventoryitem:GetImage())
    else
        self.inst.AnimState:ClearOverrideSymbol(slot_symbol)
    end
end

function VisualShelf:GetItem(slot, item)
    local slot_symbol = self:GetSlotSymbol(slot)
    if Prefabs[item.prefab .. "_visual_shelf_slot"] then
        local visual_item = SpawnPrefab(item.prefab .. "_visual_shelf_slot")
        self.slot_visualitems[slot] = visual_item
        visual_item.entity:SetParent(self.inst.entity)
        if visual_item.follow_data then
            visual_item.Follower:FollowSymbol(self.inst.GUID, self:GetSlotSymbol(slot), visual_item.follow_data[1], visual_item.follow_data[2], visual_item.follow_data[3], visual_item.follow_data[4])
        else
            visual_item.Follower:FollowSymbol(self.inst.GUID, self:GetSlotSymbol(slot), 10, 0, 0.6)
        end
    else
        self:DrawSlot(slot, item)
        self.inst:ListenForEvent("imagechange", self.slot_listeners[slot], item)
    end

    self:ForceOutOfLimbo(item)
    self:SetVisualSlot(slot, item)
end

function VisualShelf:LoseItem(slot, prev_item)
    local slot_symbol = self:GetSlotSymbol(slot)
    if self.slot_visualitems[slot] then
        self.slot_visualitems[slot]:Remove()
        self.slot_visualitems[slot] = nil
    else
        self.inst:RemoveEventCallback("imagechange", self.slot_listeners[slot], prev_item)
        self:DrawSlot(slot, nil)
    end

    self:SetVisualSlot(slot, nil)
end

function VisualShelf:SetVisualSlot(slot, item)
    local visual_slot = self.visual_slots[slot]
    if not visual_slot then
        visual_slot = SpawnPrefab("visual_shelf_slot")
        visual_slot.components.visualshelfslot:SetShelf(self.inst, slot)
        visual_slot.entity:SetParent(self.inst.entity)
        visual_slot.Follower:FollowSymbol(self.inst.GUID, self:GetSlotSymbol(slot), 10, 0, 0.6)

        self.visual_slots[slot] = visual_slot
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
