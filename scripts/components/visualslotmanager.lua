local function OnItemGet(inst, data)
    inst.components.visualslotmanager:SetVisualSlot(data.slot, data.item)
end

local function OnItemLose(inst, data)
    -- data.prev_item
    inst.components.visualslotmanager:SetVisualSlot(data.slot, nil)
end

local function onenable(self, enable)
    if enable then
        self.inst:AddTag("canput")
    else
        self.inst:RemoveTag("canput")
    end
end

local VisualSlotManager = Class(function(self, inst)
    assert(inst.components.container ~= nil)

    self.inst = inst
    self.enable = true
    self.visual_slots = {}

    self.inst:DoTaskInTime(1, function()
        self:OnEntityWake()
    end)

    inst:ListenForEvent("itemget", OnItemGet)
    inst:ListenForEvent("itemlose", OnItemLose)
end, nil, {
    enable = onenable
})

function VisualSlotManager:ForceOutOfLimbo(item)
    item:ForceOutOfLimbo(true)
    if item.Network ~= nil then
        item.Network:SetClassifiedTarget(nil)
    end
    if item.replica.inventoryitem.classified ~= nil then
        item.replica.inventoryitem.classified.Network:SetClassifiedTarget(nil)
    end
end

function VisualSlotManager:SetVisualSlot(slot, item)
    local visual_slot = self.visual_slots[slot]
    if visual_slot then
        visual_slot:Remove()
    end

    visual_slot = SpawnPrefab("visual_slot")
    self.visual_slots[slot] = visual_slot

    visual_slot.components.visualslot:SetShelf(self.inst, slot)
    visual_slot.entity:SetParent(self.inst.entity)
    visual_slot.Follower:FollowSymbol(self.inst.GUID, self.inst:GetSlotSymbol(slot), 0, 0, 0.001)

    if item then
        self:ForceOutOfLimbo(item)
    end
    visual_slot.components.visualslot:SetItem(item)
end

function VisualSlotManager:OnEntityWake()
    for i = 1, self.inst.components.container.numslots do
        local item = self.inst.components.container.slots[i]
        self:SetVisualSlot(i, item)
    end
end

function VisualSlotManager:OnEntitySleep()
    for slot, visual_slot in pairs(self.visual_slots) do
        visual_slot:Remove()
        self.visual_slots[slot] = nil
    end

    for slot, item in pairs(self.inst.components.container.slots) do
        item.replica.inventoryitem:SetOwner(nil)
    end
end

function VisualSlotManager:OnRemoveFromEntity()
    self.inst:RemoveEventCallback("itemget", OnItemGet)
    self.inst:RemoveEventCallback("itemlose", OnItemLose)
end

return VisualSlotManager
