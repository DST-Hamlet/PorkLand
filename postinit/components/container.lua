local AddComponentPostInit = AddComponentPostInit
GLOBAL.setfenv(1, GLOBAL)

local Container = require("components/container")

function Container:GetItemInBoatSlot(eslot)
    if not self.hasboatequipslots then
        return
    end

    if eslot == BOATEQUIPSLOTS.BOAT_SAIL then -- 每个船容器的第一格视为船帆的装备栏位
        return self.slots[1]
    elseif eslot == BOATEQUIPSLOTS.BOAT_LAMP then -- 每个船容器的第二格视为船灯的装备栏位
        return self.slots[2]
    end
end

local widgetprops = {
    "inspectwidget",
    "hasboatequipslots",
    "multispecificslots"
}

local _WidgetSetup = Container.WidgetSetup
function Container:WidgetSetup(...)
    for i, v in ipairs(widgetprops) do
        removesetter(self, v)
    end

    _WidgetSetup(self, ...)

    for i, v in ipairs(widgetprops) do
        makereadonly(self, v)
    end
end

local _GetSpecificSlotForItem = Container.GetSpecificSlotForItem
function Container:GetSpecificSlotForItem(item, ...)
    local ret = _GetSpecificSlotForItem(self, item, ...)
    if ret and self.multispecificslots then
        if self:GetItemInSlot(ret) then
            for i = 1, self:GetNumSlots() do
                if self:itemtestfn(item, i)
                    and (not self:GetItemInSlot(i)
                    or (self:GetItemInSlot(i) ~= nil and self:GetItemInSlot(i).components.stackable and self:GetItemInSlot(i).prefab == item.prefab and self:GetItemInSlot(i).skinname == item.skinname and not self:GetItemInSlot(i).components.stackable:IsFull())) then

                    return i
                end
            end
        end
    end

    return ret
end

function Container:BoatEquip(item)
    if not self.hasboatequipslots then
        return
    end

    if self.inst.components.container ~= nil then
        local eslot = item.components.equippable.boatequipslot
        local slot
        local old_item
        local inventory = item.components.inventoryitem.owner and item.components.inventoryitem.owner.components.inventory or nil

        item.prevslot = inventory and inventory:GetItemSlot(item) or nil

        if item.prevslot == nil and
            item.components.inventoryitem.owner ~= nil and
            item.components.inventoryitem.owner.components.container ~= nil and
            item.components.inventoryitem.owner.components.inventoryitem ~= nil then
            item.prevcontainer = item.components.inventoryitem.owner.components.container
            item.prevslot = item.components.inventoryitem.owner.components.container:GetItemSlot(item)
        else
            item.prevcontainer = nil
        end

        if eslot == BOATEQUIPSLOTS.BOAT_SAIL then
            old_item = self:GetItemInSlot(1)
            slot = 1
        elseif eslot == BOATEQUIPSLOTS.BOAT_LAMP then
            old_item = self:GetItemInSlot(2)
            slot = 2
        end
        if inventory then
            inventory:RemoveItem(item)
        end
        if old_item then
            self:DropItem(old_item)
            if inventory then
                inventory:GiveItem(old_item)
            end
        end
        self:GiveItem(item, slot)
    end
end

function Container:BoatUnequip(eslot)
    if not self.hasboatequipslots then
        return
    end

    if self.inst.components.container ~= nil then
        local item
        if eslot == BOATEQUIPSLOTS.BOAT_SAIL then
            item = self:GetItemInSlot(1)
        elseif eslot == BOATEQUIPSLOTS.BOAT_LAMP then
            item = self:GetItemInSlot(2)
        end
        if item and item.components.equippable then
           self:DropItem(item)
       end
    end
end

local function OnGetItem(inst, data)
    if inst.components.container.hasboatequipslots then
        if data.slot == 1 or data.slot == 2 then
            data.item.components.equippable:Equip(inst)
        end
    end
end

local function OnLoseItem(inst, data)
    if inst.components.container.hasboatequipslots then
        if data.slot == 1 or data.slot == 2 then
            data.prev_item.components.equippable:Unequip(inst)
        end
    end
end

AddComponentPostInit("container", function(self)
    self.inst:ListenForEvent("itemget", OnGetItem)
    self.inst:ListenForEvent("itemlose", OnLoseItem)
end)
