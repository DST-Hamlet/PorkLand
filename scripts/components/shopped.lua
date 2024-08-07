local SHOPTYPES = require("prefabs/pig_shop_defs").SHOPTYPES

local Shopped = Class(function(self, inst)
    self.inst = inst
    self.shop_type = nil
    self.item_to_sell = nil
    self.cost_prefab = nil
    self.cost = nil
end)

function Shopped:SetItemToSell(prefab)
    self.item_to_sell = prefab
    self.inst.replica.shopped:SetItemToSell(prefab)
end

function Shopped:RemoveItemToSell()
    self:SetItemToSell()
end

function Shopped:GetItemToSell()
    return self.item_to_sell
end

function Shopped:SetCost(cost_prefab, cost)
    self.cost_prefab = cost_prefab
    self.cost = cost
    self.inst.replica.shopped:SetCost(cost_prefab, cost)

    local image = cost_prefab == "oinc" and cost and "cost-"..cost or cost_prefab
    if image ~= nil then
        local texname = image..".tex"
        self.inst.AnimState:OverrideSymbol("SWAP_COST", GetInventoryItemAtlas(texname), texname)
        --self.inst.AnimState:OverrideSymbol("SWAP_SIGN", "store_items", image)
    else
        self.inst.AnimState:ClearOverrideSymbol("SWAP_COST")
    end
end

function Shopped:GetCost()
    return self.cost
end

function Shopped:GetCostPrefab()
    return self.cost_prefab
end

function Shopped:GetNewProduct()
    local items = TheWorld.state.isfiesta and SHOPTYPES[self.shop_type.."_fiesta"] or SHOPTYPES[self.shop_type]
    if items then
        return GetRandomItem(items)
    end
end

function Shopped:InitShop(shop_type)
    self.shop_type = shop_type
    local itemset = self.inst.saleitem or self:GetNewProduct()
    self.inst:SpawnInventory(itemset[1], itemset[2], itemset[3])
end

function Shopped:BoughtItem(buyer)
    if buyer.components.inventory then
        local item = SpawnPrefab(self:GetItemToSell())
        if item.OnBought then
            item:OnBought()
        end
        buyer.components.inventory:GiveItem(item, nil, self.inst)
        self.inst:SoldItem()
    end
end

function Shopped:GetRobbed(doer)
    if not self:GetItem() then
        return false
    end
    self.inst:AddTag("robbed")
    -- TODO: Make this work
    -- TheWorld.components.kramped:OnNaughtyAction(6)
    self:BoughtItem(doer)
end

function Shopped:OnSave()
    return {
        shop_type = self.shop_type,
        robbed = self.inst:HasTag("robbed"),
        item_to_sell = self:GetItemToSell(),
        cost = self:GetCost(),
        cost_prefab = self.cost_prefab,
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
    if data.item_to_sell then
        self:SetItemToSell(data.item_to_sell)
    end
    if data.cost_prefab and data.cost then
        self:SetCost(data.cost_prefab, data.cost)
    end
end

return Shopped
