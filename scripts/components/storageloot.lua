-- [StorageLoot] 此组件用于提前确定的随机掉落
local StorageLoot = Class(function(self, inst)
    self.inst = inst

    self.loots = {}
end)

function StorageLoot:HasLoot(loot)
    return table.contains(self.loots, loot)
end

function StorageLoot:HasAnyLoot()
    if #self.loots == 0 then
        return false
    end

    return true
end

function StorageLoot:AddLoot(loot)
    table.insert(self.loots, loot)
end

function StorageLoot:AddLoots(loots)
    for k, v in pairs(loots) do
        table.insert(self.loots, v)
    end
end

function StorageLoot:DestroyLoots()
    self.loots = {}
end

function StorageLoot:TakeRandomLoot()
    if #self.loots == 0 then
        return
    end

    local i = math.random(1, #self.loots)
    local loot = self.loots[i]
    table.remove(self.loots, i)

    return loot
end

function StorageLoot:TakeAllLoots()
    local loots = self.loots
    self.loots = {}
    return loots
end

function StorageLoot:OnSave()
    local data = {}

    data.loots = self.loots

    return data
end

function StorageLoot:OnLoad(data)
    if data then
        self.loots = data.loots
    end
end

return StorageLoot
