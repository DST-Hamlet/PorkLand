local SHOPTYPES = require("prefabs/pig_shop_defs").SHOPTYPES

local Shopped = Class(function(self, inst)
    self.inst = inst
    self.shop_type = nil
    self.item_to_sell = nil
end)

function Shopped:SetItemPrefab(prefab)
    self.item_to_sell = prefab
    self.inst:AddTag("has_item_to_sell")
end

function Shopped:RemoveItem()
    self.item_to_sell = nil
    self.inst:RemoveTag("has_item_to_sell")
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
        local item = SpawnPrefab(self.item_to_sell)
        if item.OnBought then
            item:OnBought()
        end
        buyer.components.inventory:GiveItem(item, nil, self.inst)
        self.inst:SoldItem()
    end
end

function Shopped:OnSave()
    return {
        shop_type = self.shop_type,
        robbed = self.inst:HasTag("robbed"),
        item_to_sell = self.item_to_sell,
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
        self:SetItemPrefab(data.item_to_sell)
    end
end

return Shopped
