local AddComponentPostInit = AddComponentPostInit
GLOBAL.setfenv(1, GLOBAL)

local Container = require("components/container")

function Container:GetItemInBoatSlot(eslot)
    if not self.hasboatequipslots then
        return
    end

    local slot = self.boatcontainerequips[eslot]
    if slot ~= nil then
        return self:GetItemInSlot(slot)
    end
end

local widgetprops = {
    "inspectwidget",
    "hasboatequipslots",
    "boatcontainerequips",
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

    if self.inst.components.container ~= nil and item.replica.equippable and item.replica.equippable:BoatEquipSlot() ~= "INVALID" then
        local eslot = item.replica.equippable:BoatEquipSlot()
        local slot = self.boatcontainerequips[eslot]

        if slot ~= nil then
            local old_item = self:GetItemInSlot(slot)
            local inventory = item.components.inventoryitem.owner and item.components.inventoryitem.owner.components.inventory or nil -- 可以是物品栏或容器
            if inventory == nil then
                inventory = item.components.inventoryitem.owner and item.components.inventoryitem.owner.components.container or nil
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
end

function Container:BoatUnequip(eslot)
    if not self.hasboatequipslots then
        return
    end

    if self.inst.components.container ~= nil then
        local item

        local slot = self.boatcontainerequips[eslot]
        if slot ~= nil then
            item = self:GetItemInSlot(slot)
        end

        if item and item.components.equippable then
           self:DropItem(item)
       end
    end
end

local function OnGetItem(inst, data)
    if inst.components.container.hasboatequipslots then
        for eslot, index in pairs(inst.components.container.boatcontainerequips) do
            if index == data.slot then
                data.item.components.equippable:Equip(inst)
                return
            end
        end
    end
end

local function OnLoseItem(inst, data)
    if inst.components.container.hasboatequipslots then
        for eslot, index in pairs(inst.components.container.boatcontainerequips) do
            if index == data.slot then
                data.prev_item.components.equippable:Unequip(inst)
                return
            end
        end
    end
end

AddComponentPostInit("container", function(self)
    self.inst:ListenForEvent("itemget", OnGetItem)
    self.inst:ListenForEvent("itemlose", OnLoseItem)
end)
