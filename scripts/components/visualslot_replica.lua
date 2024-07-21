local client_postinitfns = require("main/special_visualslots").client_postinitfns

local function OnVisualSlotItemDirty(inst)
    local item = inst.replica.visualslot:GetItem()
    if item then
        inst.replica.visualslot:ListenItem(item)
    end
end

local VisualSlot = Class(function(self, inst)
    self.inst = inst

    self._item = net_entity(inst.GUID, "visualslot._item", "visualslotitemdirty")
    self._slot = net_smallbyte(inst.GUID, "visualslot._slot")
    self._shelf = net_entity(inst.GUID, "visualslot._shelf")

    if not TheNet:IsDedicated() then
        self.inst:ListenForEvent("visualslotitemdirty", OnVisualSlotItemDirty)
    end
end)

function VisualSlot:SetSlot(slot)
    self._slot:set(slot)
end

function VisualSlot:SetShelf(shelf)
    self._shelf:set(shelf)
end

function VisualSlot:SetItem(item)
    self._item:set(item)
end

function VisualSlot:GetShelf()
    if TheWorld.ismastersim then
        return self.inst.components.visualslot:GetShelf()
    end
    return self._shelf:value()
end

function VisualSlot:GetSlot()
    if TheWorld.ismastersim then
        return self.inst.components.visualslot:GetSlot()
    end
    return self._slot:value()
end

function VisualSlot:GetItem()
    if TheWorld.ismastersim then
        return self.inst.components.visualslot:GetItem()
    end
    return self._item:value()
end

function VisualSlot:ListenItem(item)
    if TheNet:IsDedicated() then
        return
    end

    local fn = client_postinitfns[item.prefab]
    if fn then
        fn(self.inst, self:GetShelf(), self:GetSlot(), item)
        return
    end

    local function OnClientSideInventoryFlagsChange()
        local item = self:GetItem()
        if item and item.replica.inventoryitem then
            self.inst.AnimState:OverrideSymbol("visual_slot", item.replica.inventoryitem:GetAtlas(), item.replica.inventoryitem:GetImage())
        end
    end

    self.inst:ListenForEvent("imagechange", OnClientSideInventoryFlagsChange, item)
    if item:HasClientSideInventoryImageOverrides() then
        OnClientSideInventoryFlagsChange()
        self.inst:ListenForEvent("clientsideinventoryflagschanged", OnClientSideInventoryFlagsChange, ThePlayer)
    end
end

return VisualSlot
