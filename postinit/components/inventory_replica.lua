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

local SUPPORTED_ITEMS = {
    ["abigail_flower"] = true,
}

local use_item_from_inv_tile = Inventory.UseItemFromInvTile
function Inventory:UseItemFromInvTile(item, ...)
    if not (item and item:IsValid()) then
        return
    end

    if not TheInput:ControllerAttached() and SUPPORTED_ITEMS[item.prefab] then
        local action = self.inst.components.playeractionpicker:GetInventoryActions(item)[1]
        if action == ACTIONS.USESPELLBOOK then
            self.inst.HUD.controls.spellcontrols:Open()
            return
        end
        -- if action == ACTIONS.CLOSESPELLBOOK then

        -- end
    end

    return use_item_from_inv_tile(self, item, ...)
end
