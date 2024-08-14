local Shopped = Class(function(self, inst)
    self.inst = inst

    self.cost_prefab = nil
    self.cost = nil
    self.on_set_cost = nil

    self.on_robbed = nil
end)

function Shopped:SetItemToSell(prefab, slot)
    local old = self:RemoveItemToSell(slot)
    if old then
        old:Remove()
    end

    local item = SpawnPrefab(prefab)
    self.inst.components.container:GiveItem(item, slot)
end

function Shopped:RemoveItemToSell(slot)
    return self.inst.components.container:RemoveItemBySlot(slot or 1)
end

function Shopped:GetItemToSell(slot)
    return self.inst.components.container:GetItemInSlot(slot or 1)
end

function Shopped:OnSetCost(fn)
    self.on_set_cost = fn
end

function Shopped:SetCost(cost_prefab, cost)
    self.cost_prefab = cost_prefab
    self.cost = cost
    self.inst.replica.shopped:SetCost(cost_prefab, cost)

    if self.on_set_cost then
        self.on_set_cost(self.inst, cost_prefab, cost)
    end
end

function Shopped:GetCost()
    return self.cost
end

function Shopped:GetCostPrefab()
    return self.cost_prefab
end

function Shopped:BoughtItem(buyer, slot)
    if buyer.components.inventory then
        local item = self:RemoveItemToSell(slot)
        if not item then
            return
        end

        if item.OnBought then
            item:OnBought()
        end

        buyer.components.inventory:GiveItem(item, nil, self.inst:GetPosition())
    end
end

function Shopped:SetOnRobbed(fn)
    self.on_robbed = fn
end

function Shopped:GetRobbed(robber, slot)
    if not self:GetItemToSell(slot) then
        return false
    end

    self.inst:AddTag("robbed")
    if self.on_robbed then
        self.on_robbed(self.inst, robber)
    end
    self:BoughtItem(robber, slot)
end

function Shopped:IsBeingWatched()
    return self.inst.replica.shopped:IsBeingWatched()
end

function Shopped:OnSave()
    return {
        robbed = self.inst:HasTag("robbed"),
        cost = self:GetCost(),
        cost_prefab = self.cost_prefab,
        add_component_if_missing = true,
    }
end

function Shopped:OnLoad(data)
    if not data then
        return
    end
    if data.robbed then
        self.inst:AddTag("robbed")
    end
    self:SetCost(data.cost_prefab, data.cost)
end

return Shopped
