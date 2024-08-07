local SHOPTYPES = require("prefabs/pig_shop_defs").SHOPTYPES

local Shopped = Class(function(self, inst)
    self.inst = inst
    self.shoptype = nil
    self.item_served = nil
end)

function Shopped:SetItemPrefab(prefab)
    self.item_served = prefab
end

function Shopped:RemoveItem()
    self.item_served = nil
end

function Shopped:GetNewProduct()
    local items = TheWorld.state.isfiesta and SHOPTYPES[self.shoptype.."_fiesta"] or SHOPTYPES[self.shoptype]
    if items then
        return GetRandomItem(items)
    end
end

function Shopped:InitShop(shop_type)
    self.shoptype = shop_type
    local itemset = self.inst.saleitem or self:GetNewProduct()
    self.inst:SpawnInventory(itemset[1], itemset[2], itemset[3])
end

function Shopped:BoughtItem(player)
    if player.components.inventory and self.inst.components.shopdispenser then
        local item = SpawnPrefab(self.inst.components.shopdispenser:GetItem())
        if item.OnBought then
            item:OnBought()
        end
        player.components.inventory:GiveItem(item, nil, self.inst)
        self.inst:SoldItem()
    end
end

function Shopped:OnSave()
    return {
        shoptype = self.shoptype,
        robbed = self.inst:HasTag("robbed"),
        item_served = self.item_served,
    }
end

function Shopped:OnLoad(data)
    if not data then
        return
    end
    if data.shoptype then
        self.shoptype = data.shoptype
    end
    if data.robbed then
        self.inst:AddTag("robbed")
    end
    if data.item_served then
        self:SetItemPrefab(data.item_served)
    end
end

-- function Shopped:CollectSceneActions(doer, actions)
--     if doer.components.shopper and self.inst.components.shopdispenser.item_served then
--         table.insert(actions, ACTIONS.SHOP)
--     end
-- end

return Shopped
