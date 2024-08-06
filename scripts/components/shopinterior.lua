local SHOPTYPES = require("prefabs/pig_shop_defs").SHOPTYPES

local ShopInterior = Class(function(self, inst)
    self.inst = inst
    self.payment_wanted = nil 
    self.items = {}
    self.pigseller = nil 
    self.shopType = nil 
    self.want_all = false
    self.items_wanted = {}
end)

function ShopInterior:BoughtItem(prefab, player)
    if self.items ~= nil then   
        if player.components.inventory and prefab.components.shopdispenser then 

            local item = SpawnPrefab(prefab.components.shopdispenser:GetItem())
            if item.OnBought then
                item.OnBought(item)
            end
            
            player.components.inventory:GiveItem(item, nil, Vector3(TheSim:GetScreenPos(prefab.Transform:GetWorldPosition())))
            local newItem = GetRandomItem(self.items)
            prefab:SoldItem() -- TimedInventory(newItem)
        end 
    end 
end 
 
function ShopInterior:OnRemoveEntity()
    if self.thought then
        self.thought:Remove()
    end
    local x,y,z = self.inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x,y,z, 5, {"pig_shop_item"})
    for i=#ents,1, -1 do
        local ent = ents[i]
        if ent.components.shopped and ent.components.shopped.shop == self then
            ent:Remove()
        end
    end
end

function ShopInterior:GetNewProduct(shoptype)
    if GetAporkalypse() and GetAporkalypse():GetFiestaActive() and SHOPTYPES[shoptype.."_fiesta"] then
        shoptype = shoptype.."_fiesta"
    end
    local items = SHOPTYPES[shoptype]
    if items then
        local itemset = GetRandomItem(items)
        return itemset
    end
end

function ShopInterior:FillPedestals(numItems, shopType)

    local x,y,z = self.inst.Transform:GetWorldPosition()

    local ents = TheSim:FindEntities(x,y,z, 10, {"shop_pedestal"})

    for i=#ents,1, -1 do
        if not ents[i].interiorID or ents[i].interiorID ~= self.inst.interiorID then
            table.remove(ents,i)
        end
    end

    for i = 1, #ents do    
        local itemset = self:GetNewProduct(shopType)        
        local spawn = ents[i]
        if spawn.saleitem then
            itemset = spawn.saleitem
        end        
        spawn.components.shopped:SetShop(self.inst, shopType)
        spawn:AddTag("pig_shop_item")
        spawn:SpawnInventory(itemset[1],itemset[2],itemset[3])
    end

end

function ShopInterior:OnSave()
    local data = {}
    if self.payment_wanted then
        data.payment_wanted = self.payment_wanted
    end
    if next(data) then
        return data
    end
end

function ShopInterior:OnLoad(data)
    if data.payment_wanted then
        self.payment_wanted = data.payment_wanted

    end
end

function ShopInterior:MakeShop(numItems, shopType)
    local x,y,z = self.inst.Transform:GetWorldPosition()
    self.shopType = shopType
    if SHOPTYPES[shopType] then 
        self.items = SHOPTYPES[shopType]
        self:FillPedestals(numItems, shopType)
    end 
end 

function ShopInterior:GetWanted()
    return self.payment_wanted
end 

return ShopInterior 