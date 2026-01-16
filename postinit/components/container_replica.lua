local AddClassPostConstruct = AddClassPostConstruct
GLOBAL.setfenv(1, GLOBAL)

local Container = require("components/container_replica")

function Container:GetItemInBoatSlot(eslot)
    if not self.hasboatequipslots then
        return
    end

    if self.inst.components.container ~= nil then
        return self.inst.components.container:GetItemInBoatSlot(eslot)
    else
        if self.classified ~= nil then
            local slot = self.boatcontainerequips[eslot]
            if slot == nil then
                return
            end

            return self.classified:GetItemInSlot(slot)
        end
    end
end

local _GetSpecificSlotForItem = Container.GetSpecificSlotForItem
function Container:GetSpecificSlotForItem(...)
    local _itemtestfn = self.itemtestfn
    self.itemtestfn = function(container, item, i, ...)
        local slotitem = container:GetItemInSlot(i)
        return _itemtestfn(container, item, i, ...)
            and (not slotitem
            or (slotitem.replica.stackable ~= nil and slotitem.prefab == item.prefab and item:StackableSkinHack(slotitem) and not slotitem.replica.stackable:IsFull()))
            -- 总之是烦人的可堆叠检测，复制自原组件container_classified
    end

    local ret = _GetSpecificSlotForItem(self, ...)
    self.itemtestfn = _itemtestfn

    return ret
end

local _GetWidget = Container.GetWidget
function Container:GetWidget(boatwidget)
    if not boatwidget then
        return _GetWidget(self)
    else
        return self.inspectwidget
    end
end

AddClassPostConstruct("components/container_replica", function(self)
    self._has_sailor = net_bool(self.inst.GUID, "container._has_sailor", TheWorld.ismastersim and "has_sailor_dirty" or nil)
end)