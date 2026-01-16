local AddComponentPostInit = AddComponentPostInit
GLOBAL.setfenv(1, GLOBAL)

local Container = require("components/container")

function Container:ForceOpen(doer, ...)
    self.forceopen = true

    self:Open(doer, ...)
end

local _Close = Container.Close
function Container:Close(doer, ...)
    if self.forceopen then
        return
    end

    return _Close(self, doer, ...)
end

function Container:ForceClose(doer, ...)
    self.forceopen = false

    self:Close(doer, ...)
end

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
function Container:GetSpecificSlotForItem(...)
    removesetter(self, "itemtestfn")
    local _itemtestfn = self.itemtestfn
    self.itemtestfn = function(container, item, i, ...)
        local slotitem = container:GetItemInSlot(i)
        return _itemtestfn(container, item, i, ...)
            and (not slotitem
            or (slotitem.components.stackable and slotitem.prefab == item.prefab and slotitem.skinname == item.skinname and not slotitem.components.stackable:IsFull()))
            -- 总之是烦人的可堆叠检测，复制自原组件Container:GiveItem
    end

    local ret = _GetSpecificSlotForItem(self, ...)
    self.itemtestfn = _itemtestfn
    makereadonly(self, "itemtestfn")

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
