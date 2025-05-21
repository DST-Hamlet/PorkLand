GLOBAL.setfenv(1, GLOBAL)

local Inventory = require("components/inventory_replica")

local has = Inventory.Has
function Inventory:Has(prefab, amount, checkallcontainers, ...)
    if self.check_all_oincs and prefab == "oinc" then
        local _, oincamount = has(self, "oinc", 0, true)
        local _, oinc10amount = has(self, "oinc10", 0, true)
        local _, oinc100amount = has(self, "oinc100", 0, true)
        local total = oincamount + (oinc10amount * 10) + (oinc100amount * 100)
        return total >= amount, total
    end
    return has(self, prefab, amount, checkallcontainers, ...)
end

function Inventory:GetItem(prefab)
    local item = self:GetActiveItem()
    if item and item.prefab == prefab then
        return item
    end

    local containers = {}
    local inventory = self.inst.replica.inventory
    table.insert(containers, inventory)
    local backpack = inventory:GetOverflowContainer()
    if backpack then
        table.insert(containers, backpack)
    end
    for _, inv in ipairs(containers) do
        local items = inv:GetItems()
        for slot, item in pairs(items) do
            if item.prefab == prefab then
                return item
            end
        end
    end

end

local get_num_slots = Inventory.GetNumSlots
function Inventory:GetNumSlots(...)
    if not self.inst.components.inventory then
        if self.inst.prefab == "wheeler" then
            return 12
        end
    end
    return get_num_slots(self, ...)
end

-- This is the same as the one postinit/widgets/invslot.lua,
-- but we need to hook on both for the keyboard shortcuts

local SUPPORTED_ITEMS = {
    ["abigail_flower"] = true,
}

local function get_slot_position(inventory_bar, item)
    local slots = JoinArrays(unpack(inventory_bar:GetInventoryLists()))
    for _, slot in pairs(slots) do
        if slot.tile and slot.tile.item == item then
            return slot.tile:GetWorldPosition()
        end
    end
end

local use_item_from_inv_tile = Inventory.UseItemFromInvTile
function Inventory:UseItemFromInvTile(item, ...)
    if not (item and item:IsValid()) then
        return
    end

    if not TheInput:ControllerAttached() and SUPPORTED_ITEMS[item.prefab] then
        local action = self.inst.components.playeractionpicker:GetInventoryActions(item)[1]
        if action then
            if action.action == ACTIONS.USESPELLBOOK then
                self.inst.HUD.controls.spellcontrols:Open(item.components.spellbook.items, item, get_slot_position(self.inst.HUD.controls.inv, item))
                return
            end
            if action.action == ACTIONS.CLOSESPELLBOOK then
                self.inst.HUD.controls.spellcontrols:Close()
                return
            end
        end
    end

    return use_item_from_inv_tile(self, item, ...)
end
