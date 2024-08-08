local SHOPTYPES = require("prefabs/pig_shop_defs").SHOPTYPES

local Shopped = Class(function(self, inst)
    self.inst = inst
    self.shop_type = nil

    self.cost_prefab = nil
    self.cost = nil
    self.on_set_cost = nil
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
    return self.inst.components.container:RemoveItemBySlot(slot)
end

function Shopped:GetItemToSell(slot)
    return self.inst.components.container:GetItemInSlot(slot)
end

function Shopped:OnSetCost(fn)
    self.on_set_cost = fn
end

function Shopped:SetCost(cost_prefab, cost)
    self.cost_prefab = cost_prefab
    self.cost = cost
    self.inst.replica.shopped:SetCost(cost_prefab, cost)
    self.on_set_cost(self.inst, cost_prefab, cost)
end

function Shopped:GetCost()
    return self.cost
end

function Shopped:GetCostPrefab()
    return self.cost_prefab
end

function Shopped:GetNewProduct()
    if not self.shop_type then
        return
    end
    local items = TheWorld.state.isfiesta and SHOPTYPES[self.shop_type.."_fiesta"] or SHOPTYPES[self.shop_type]
    if items then
        return GetRandomItem(items)
    end
end

function Shopped:SpawnInventory(prefabtype, costprefab, cost)
    self:SetCost(costprefab, cost)
    self:SetItemPrefab(prefabtype)
end

function Shopped:InitShop(shop_type)
    self.shop_type = shop_type
    local itemset = self.inst.saleitem or self:GetNewProduct()
    self:SpawnInventory(itemset[1], itemset[2], itemset[3])
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

        buyer.components.inventory:GiveItem(item, nil, self.inst)
    end
end

function Shopped:GetRobbed(doer, slot)
    if not self:GetItemToSell() then
        return false
    end

    self.inst:AddTag("robbed")
    -- TODO: Make this work
    -- TheWorld.components.kramped:OnNaughtyAction(6)
    self:BoughtItem(doer, slot)
end

function Shopped:IsBeingWatched()
    return self.inst.replica.shopped:IsBeingWatched()
end

function Shopped:OnSave()
    return {
        shop_type = self.shop_type,
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
    if data.shop_type then
        self.shop_type = data.shoptype
    end
    if data.robbed then
        self.inst:AddTag("robbed")
    end
    if data.cost_prefab and data.cost then
        self:SetCost(data.cost_prefab, data.cost)
    end
end

return Shopped
