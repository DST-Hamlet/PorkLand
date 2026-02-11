local AddClassPostConstruct = AddClassPostConstruct
GLOBAL.setfenv(1, GLOBAL)

local Container = require("components/container_replica")

function Container:GetItemInBoatSlot(eslot)
    if self.inst.components.container ~= nil then
        return self.inst.components.container:GetItemInBoatSlot(eslot)
    else
        return self.opener ~= nil and self.classified ~= nil and self.classified:GetItemInBoatSlot(eslot)
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
function Container:GetSpecificSlotForItem(...)
    local _itemtestfn = self.itemtestfn
    if _itemtestfn then
        self.itemtestfn = function(container, item, i, ...)
            local slotitem = container:GetItemInSlot(i)
            return _itemtestfn(container, item, i, ...)
                and (not slotitem
                or (slotitem.replica.stackable ~= nil and slotitem.prefab == item.prefab and item:StackableSkinHack(slotitem) and not slotitem.replica.stackable:IsFull()))
                and not self:IsBoatSlot(i) -- 不能通过快速移动装备船装备
                -- 总之是烦人的可堆叠检测，复制自原组件container_classified
        end
    end

    local ret = _GetSpecificSlotForItem(self, ...)
    self.itemtestfn = _itemtestfn

    if _itemtestfn and ret == nil then
        -- 如果找不到可用的物品格子但该容器有其他空余的格子, 那么就返回一个已被占据的格子(仅对同时有装备栏和物品栏的船那么做)
        -- 这是为了防止客户端强制将物品塞入装备格子
        return 1
    end

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
