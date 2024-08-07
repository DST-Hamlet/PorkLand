local Shopped = Class(function(self, inst)
    self.inst = inst
    self._item_to_sell = net_string(inst.GUID, "shopped._item_to_sell")
    self._cost_prefab = net_string(inst.GUID, "shopped._cost_prefab")
    self._cost = net_shortint(inst.GUID, "shopped._cost")
end)

function Shopped:SetItemToSell(prefab)
    self.inst._item_to_sell:set(prefab)
end

function Shopped:GetItemToSell()
    local prefab = self._item_to_sell:value()
    return prefab ~= "" and prefab or nil
end

function Shopped:SetCost(cost_prefab, cost)
    self._cost:set(cost)
    self._cost_prefab:set(cost)
end

function Shopped:GetCost()
    return self._cost:value()
end

function Shopped:GetCostPrefab()
    return self._cost_prefab:value()
end

-- function Shopped:IsBeingWatched()
-- end

return Shopped
