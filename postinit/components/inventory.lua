local AddComponentPostInit = AddComponentPostInit
GLOBAL.setfenv(1, GLOBAL)

local Inventory = require("components/inventory")

local _GetEquippedItem = Inventory.GetEquippedItem
function Inventory:GetEquippedItem(eslot)
    if eslot == nil then
        return false
    else
        return _GetEquippedItem(self, eslot)
    end
end

local _Equip = Inventory.Equip
function Inventory:Equip(item, ...)
    if item == nil or item.components.equippable == nil or item.components.equippable.equipslot == nil then
        return false
    else
        return _Equip(self, item, ...)
    end
end

local _GiveItem = Inventory.GiveItem
function Inventory:GiveItem(item, ...)
    -- 多余物品优先进入船容器
    if self:GetOverflowContainer() == nil and self:GetNextAvailableSlot(item) == nil then -- 如果有背包, 那么背包会处理多余物品
        local sailor = self.inst.replica.sailor
        local boatcontainer = sailor and sailor:GetBoat() and sailor:GetBoat().components.container

        if boatcontainer and boatcontainer:GiveItem(item, ...) then
            return true
        end
    end

    return _GiveItem(self, item, ...)
end

function Inventory:HasPoisonBlockerEquip()
    for k, v in pairs (self.equipslots) do
        if v.components.equippable ~= nil and v.components.equippable:IsPoisonBlocker() then
            return true
        end
    end
end

function Inventory:HasPoisonGasBlockerEquip()
    for k, v in pairs (self.equipslots) do
        if v.components.equippable ~= nil and v.components.equippable:IsPoisonGasBlocker() then
            return true
        end
    end
end

function Inventory:DisableOnEquip(eslot, disable) -- 此函数可以控制装备的onequip是否生效
    if self.onequipdisabled == nil then
        self.onequipdisabled = {}
    end

    local old_disabled = self.onequipdisabled[eslot]
    self.onequipdisabled[eslot] = disable

    if not disable and old_disabled then
        local item = self:GetEquippedItem(eslot)
        if item then
            item.components.equippable.onequipfn(item, self.inst)
        end
    elseif disable and not old_disabled then
        local item = self:GetEquippedItem(eslot)
        if item then
            item.components.equippable.onunequipfn(item, self.inst)
            if item.components.inventoryitem.onputininventoryfn then -- 额外保障
                item.components.inventoryitem.onputininventoryfn(item, self.inst)
            end
        end
    end
end

function Inventory:CanDisableOnEquip(eslot)
    if self.onequipdisabled == nil then
        return false
    end
    return self.onequipdisabled[eslot] == true
end

local function InvSpaceChanged(inst)
    inst:PushEvent("invspacechange", {percent = inst.components.inventory:NumItems() / inst.components.inventory.maxslots})
end

AddComponentPostInit("inventory", function(self)
    self.inst:ListenForEvent("itemget", InvSpaceChanged)
    self.inst:ListenForEvent("itemlose", InvSpaceChanged)
    self.inst:ListenForEvent("dropitem", InvSpaceChanged)
end)

-- Hack, hard coded wheeler's maxslots to work around the makereadonly
local _ctor = Inventory._ctor
function Inventory:_ctor(inst, ...)
    if inst.prefab == "wheeler" then
        local get_max_item_slots = GetMaxItemSlots
        GetMaxItemSlots = function()
            return 12
        end
        local ret = { _ctor(self, inst, ...) }
        GetMaxItemSlots = get_max_item_slots
        return unpack(ret)
    end
    return _ctor(self, inst, ...)
end
