    --Sits on the player prefab, not a pig.

local Shopper = Class(function(self, inst)
    self.inst = inst
end)

local function RemoveMoney(inventory, prefab, amount)
    -- print("RemoveMoney", prefab, amount)
    local need_removed_amount = amount
    local items = inventory:GetItemByName(prefab, amount, true)
    for item, v in pairs(items) do
        if item:IsValid() then -- 可能会在前一组remove的时候触发
            local stacksize = item.components.stackable:StackSize()
            if need_removed_amount > stacksize then
                item:Remove()
            elseif need_removed_amount > 0 then
                item.components.stackable:Get(need_removed_amount):Remove()
            end
        end
    end
    if need_removed_amount > 0 then
        return false
    end
    return true
end

function Shopper:PayMoney(cost)
    local inventory = self.inst.components.inventory
    local _, oinc_amount = inventory:Has("oinc", 0, true)
    local _, oinc10_amount = inventory:Has("oinc10", 0, true)
    local _, oinc100_amount = inventory:Has("oinc100", 0, true)
    local debt = cost

    local oinc_used = 0
    local oinc10_used = 0
    local oinc100_used = 0
    local oinc_gained = 0
    local oinc10_gained = 0

    while debt > 0 do
        while debt > 0 and oinc_amount > 0 do
            oinc_amount = oinc_amount - 1
            debt = debt - 1
            oinc_used = oinc_used + 1
        end
        if debt > 0 then
            if oinc10_amount > 0 then
                oinc10_amount = oinc10_amount - 1
                oinc10_used = oinc10_used + 1
                for i = 1, 10 do
                    oinc_amount = oinc_amount + 1
                    oinc_gained = oinc_gained + 1
                end
            elseif oinc100_amount > 0 then
                oinc100_amount = oinc100_amount - 1
                oinc100_used = oinc100_used + 1
                for i = 1, 10 do
                    oinc10_amount = oinc10_amount + 1
                    oinc10_gained = oinc10_gained + 1
                end
            end
        end
    end

    local oinc_result = oinc_gained - oinc_used
    if oinc_result > 0 then
        for i = 1, oinc_result do
            local coin = SpawnPrefab("oinc")
            inventory:GiveItem(coin)
        end
    end
    if oinc_result < 0 then
        RemoveMoney(inventory, "oinc", math.abs(oinc_result))
    end

    local oinc10_result = oinc10_gained - oinc10_used
    if oinc10_result > 0 then
        for i = 1, oinc10_result do
            local coin = SpawnPrefab("oinc10")
            inventory:GiveItem(coin)
        end
    end
    if oinc10_result < 0 then
        RemoveMoney(inventory, "oinc10", math.abs(oinc10_result))
    end

    local oinc100_result = 0 - oinc100_used
    if oinc100_result < 0 then
        RemoveMoney(inventory, "oinc100", math.abs(oinc100_result))
    end
end

function Shopper:GetMoney()
    local inventory = self.inst.components.inventory
    local _, oincamount = inventory:Has("oinc", 0, true)
    local _, oinc10amount = inventory:Has("oinc10", 0, true)
    local _, oinc100amount = inventory:Has("oinc100", 0, true)
    return oincamount + (oinc10amount * 10) + (oinc100amount * 100)
end

function Shopper:CanPayFor(item, slot)
    if not item.components.shopped:IsBeingWatched() then
        -- print("NOT WATCHED")
        return true
    end
    if not item.components.shopped:GetItemToSell(slot) then
        return false
    end

    local prefab_wanted = item.components.shopped:GetCostPrefab()
    -- print("TESTING prefab_wanted", prefab_wanted)

    if prefab_wanted == "oinc" then
        if self:GetMoney() >= item.components.shopped:GetCost() then
            return true
        end
    else
        if prefab_wanted then
            local item = self.inst.components.inventory:FindItem(function(look) return look.prefab == prefab_wanted end)
            if item then
                return true
            end
        end
    end
    return false, "REPAIRBOAT"
end

function Shopper:Buy(shelf, slot)
    if not shelf.components.shopped:GetItemToSell(slot) then
        return false
    end

    local cost_prefab = shelf.components.shopped:GetCostPrefab()
    if cost_prefab == "oinc" then
        self:PayMoney(shelf.components.shopped:GetCost())
        shelf.components.shopped:BoughtItem(self.inst, slot)
    else
        local item = self.inst.components.inventory:FindItem(function(look) return look.prefab == cost_prefab end)
        if item then
            self.inst.components.inventory:RemoveItem(item)
            shelf.components.shopped:BoughtItem(self.inst, slot)
        end
    end
end

return Shopper
