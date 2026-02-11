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

function Container:IsBoatSlot(slot)
    if not self.hasboatequipslots then
        return
    end

    for eslot, index in pairs(self.boatcontainerequips) do
        if slot == index then
            return true
        end
    end
    return false
end

local _GetSpecificSlotForItem = Container.GetSpecificSlotForItem
function Container:GetSpecificSlotForItem(...) -- 为了让普通物品无法进入船的装备格子, 或许写法还可以进一步优化
    if self.hasboatequipslots then
        removesetter(self, "itemtestfn")
        local _itemtestfn = self.itemtestfn
        self.itemtestfn = function(container, item, i, ...)
            local slotitem = container:GetItemInSlot(i)
            return _itemtestfn(container, item, i, ...)
                and (not slotitem
                or (slotitem.components.stackable and slotitem.prefab == item.prefab and slotitem.skinname == item.skinname and not slotitem.components.stackable:IsFull()))
                and not self:IsBoatSlot(i) -- 不能通过快速移动装备船装备
                -- 总之是烦人的可堆叠检测，复制自原组件Container:GiveItem
        end

        local ret = _GetSpecificSlotForItem(self, ...)
        self.itemtestfn = _itemtestfn
        makereadonly(self, "itemtestfn")

        return ret
    end

    return _GetSpecificSlotForItem(self, ...)
end

function Container:IsOverflow(owner)
    if owner == nil then
        owner = self.inst.components.inventoryitem and self.inst.components.inventoryitem.owner
    end

    if owner == nil then
        return
    end

    return owner.components.inventory and (owner.components.inventory:GetOverflowContainer() == self) or nil
end

local _GiveItem = Container.GiveItem
function Container:GiveItem(...)
    local ret = _GiveItem(self, ...)

    -- 多余物品优先进入船容器
    if ret == false and self:IsOverflow() then -- 如果该容器是背包且无法装下所有物品
        local owner = self.inst.components.inventoryitem and self.inst.components.inventoryitem.owner

        if owner == nil then
            return
        end

        local sailor = owner.replica.sailor
        local boatcontainer = sailor and sailor:GetBoat() and sailor:GetBoat().components.container

        if boatcontainer and self ~= boatcontainer then
            return boatcontainer:GiveItem(...)
        end
    end

    return ret
end

function Container:BoatEquip(item, doer)
    if not self.hasboatequipslots then
        return
    end

    if self.inst.components.container ~= nil and item.replica.equippable and item.replica.equippable:BoatEquipSlot() ~= "INVALID" then
        local eslot = item.replica.equippable:BoatEquipSlot()
        local slot = self.boatcontainerequips[eslot]

        if slot ~= nil then
            local old_item = self:GetItemInSlot(slot)
            if old_item ~= nil and old_item.components.equippable:ShouldPreventUnequipping() then
                return
            end

            local owner = item.components.inventoryitem.owner
            local inventory = owner and owner.components.inventory or nil -- 可以是物品栏或容器
            if inventory == nil then
                inventory = owner and owner.components.container or nil
            end

            if inventory then
                inventory:RemoveItem(item)
            end
            local prevcontainer = item.prevcontainer
            local prevslot = item.prevslot

            if old_item then
                local drop_item = self:BoatUnequip(eslot)

                local iscontroller = doer and doer.components.playercontroller and doer.components.playercontroller.isclientcontrollerattached
                if iscontroller and prevslot then
                    drop_item.prevcontainer = prevcontainer
                    drop_item.prevslot = prevslot
                end

                if drop_item and drop_item:IsValid() then
                    if doer and doer.components.inventory then
                        doer.components.inventory:GiveItem(drop_item)
                    elseif inventory then
                        inventory:GiveItem(drop_item)
                    else
                        self:GiveItem(drop_item)
                    end
                end
            end
            self:GiveItem(item, slot) -- 会导致item.prevcontainer和item.prevslot发生变化

            item.prevcontainer = prevcontainer
            item.prevslot = prevslot
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
            local prevcontainer = item.prevcontainer
            local prevslot = item.prevslot

           self:DropItem(item)

           item.prevcontainer = prevcontainer
           item.prevslot = prevslot

           return item
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
