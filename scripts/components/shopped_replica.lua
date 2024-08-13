local Shopped = Class(function(self, inst)
    self.inst = inst
    self._cost_prefab = net_string(inst.GUID, "shopped._cost_prefab")
    self._cost = net_shortint(inst.GUID, "shopped._cost")
end)

function Shopped:SetCost(cost_prefab, cost)
    self._cost:set(cost)
    self._cost_prefab:set(cost_prefab)
end

function Shopped:GetCost()
    return self._cost:value()
end

function Shopped:GetCostPrefab()
    return self._cost_prefab:value()
end

function Shopped:IsBeingWatched()
    local x, y, z = self.inst.Transform:GetWorldPosition()
    local shopkeeps = TheSim:FindEntities(x, y, z, 20, {"shopkeep"}, {"INLIMBO"})
    for _, shopkeep in ipairs(shopkeeps) do
        if not IsEntityDead(shopkeep) and not shopkeep.components.sleeper or not shopkeep.components.sleeper:IsAsleep() then
            return true
        end
    end
    return false
end

return Shopped
