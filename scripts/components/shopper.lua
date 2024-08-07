    --Sits on the player prefab, not a pig.

local Shopper = Class(function(self, inst)
    self.inst = inst
end)

local function FindItem(inventory, list)
    local item = inventory:FindItem(function(look)
        for _, v in ipairs(list) do
            if look.prefab == v then
                return look
            end
        end
    end)
    return item
end

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
    local money = 0

    local inventory = self.inst.components.inventory
    local _, oincamount = inventory:Has("oinc", 0, true)
    local _, oinc10amount = inventory:Has("oinc10", 0, true)
    local _, oinc100amount = inventory:Has("oinc100", 0, true)

    money = oincamount + (oinc10amount * 10) + (oinc100amount * 100)
    return money
end

function Shopper:IsWatching(item)
    if item:HasTag("cost_one_oinc") or item.components.shopped then
        local x, y, z = item.Transform:GetWorldPosition()
          local ents = TheSim:FindEntities(x, y, z, 50, {"shopkeep"}, {"INLIMBO"})
          if #ents > 0 then
              for _, ent in ipairs(ents) do
                  if not ent.components.sleeper or not ent.components.sleeper:IsAsleep() then
                      return true
                  end
              end
        end
    end
    return false
end

function Shopper:CanPayFor(item)
    if not self:IsWatching(item) then
        print("NOT WATCHED")
        return true
    end

    if item.components.shopped then
        if not item.components.shopped:GetItem() then
            return false
        end

        local prefab_wanted = item.costprefab
        print("TESTING prefab_wanted", prefab_wanted)

        if prefab_wanted == "oinc" then
             if self:GetMoney() >= item.cost then
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
    else
        if item:HasTag("cost_one_oinc") then
             if self:GetMoney() >= 1 then
                 return true
             end
        end
    end
    return false, "REPAIRBOAT"
end

function Shopper:PayFor(item)
    if item:HasTag("cost_one_oinc") then
        self:PayMoney(1)
    else
        if not item.components.shopped:GetItem() then
            return false
        end

        if item.costprefab then
            if item.costprefab == "oinc" then
                self:PayMoney(item.cost)
                item:BoughtItem(self.inst)
            else
                local item = self.inst.components.inventory:FindItem(function(look) return look.prefab == item.costprefab end)
                if item then
                    self.inst.components.inventory:RemoveItem(item)
                    item:BoughtItem(self.inst)
                end
            end
        end
    end
end

function Shopper:Take(shop_buyer)
    if not shop_buyer.components.shopped:GetItem() then
        return false
    end

    if self.inst.components.inventory then
        shop_buyer:AddTag("robbed")
        self.inst.components.kramped:OnNaughtyAction(6)
        shop_buyer:BoughtItem(self.inst)
    end
end

return Shopper
