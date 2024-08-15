    --Sits on the player prefab, not a pig.

local Shopper = Class(function(self, inst)
    self.inst = inst
end)

function Shopper:PayMoney(cost)
    local inventory = self.inst.components.inventory
    local _, oincamount = inventory:Has("oinc", 0, true)
    local _, oinc10amount = inventory:Has("oinc10", 0, true)
    local _, oinc100amount = inventory:Has("oinc100", 0, true)
    local debt = cost

    local oincused = 0
    local oinc10used = 0
    local oinc100used = 0
    local oincgained = 0
    local oinc10gained = 0

    if self.inst.components.builder and self.inst.components.builder.freebuildmode then
        return
    else
        while debt > 0 do
            while debt > 0 and oincamount > 0 do
                oincamount = oincamount - 1
                debt = debt - 1
                oincused = oincused + 1
            end
            if debt > 0 then
                if oinc10amount > 0 then
                    oinc10amount = oinc10amount - 1
                    oinc10used = oinc10used + 1
                    for i = 1, 10 do
                        oincamount = oincamount + 1
                        oincgained = oincgained + 1
                    end
                elseif oinc100amount > 0 then
                    oinc100amount = oinc100amount - 1
                    oinc100used = oinc100used + 1
                    for i = 1, 10 do
                        oinc10amount = oinc10amount + 1
                        oinc10gained = oinc10gained + 1
                    end
                end
            end
        end

        local oincresult = oincgained - oincused
        if oincresult > 0 then
            for i = 1, oincresult do
                local coin = SpawnPrefab("oinc")
                inventory:GiveItem(coin)
            end
        end
        if oincresult < 0 then
            for i = 1, math.abs(oincresult) do
                inventory:ConsumeByName("oinc", 1, true)
            end
        end

        local oinc10result = oinc10gained - oinc10used
        if oinc10result > 0 then
            for i = 1, oinc10result do
                local coin = SpawnPrefab("oinc10")
                inventory:GiveItem(coin)
            end
        end
        if oinc10result < 0 then
            for i = 1, math.abs(oinc10result) do
                inventory:ConsumeByName("oinc10", 1, true)
            end
        end

        local oinc100result = 0 - oinc100used
        if oinc100result < 0 then
            for i = 1, math.abs(oinc100result) do
                inventory:ConsumeByName("oinc100", 1, true)
            end
        end
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
