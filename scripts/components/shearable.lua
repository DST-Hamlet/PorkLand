local function oncanbesheared(self, canbesheared)
    if canbesheared then
        self.inst:AddTag("SHEAR_workable")
    else
        self.inst:RemoveTag("SHEAR_workable")
    end
end

local Shearable = Class(function(self, inst)
    self.inst = inst

    self.drop = false
    self.drop_height = 0
    self.product_num = 1
    self.canbesheared = true

    self.product = nil
    self.onshearfn = nil

    inst:DoTaskInTime(0, function()
        if inst.components.hackable then
            self.canbesheared = inst:HasTag("HACK_workable")
        end
    end)
end,
nil,
{
    canbesheared = oncanbesheared
})

function Shearable:OnRemoveFromEntity()
    self.inst:RemoveTag("SHEAR_workable")
end

function Shearable:SetUp(product, product_num, drop)
    self.canbesheared = true
    self.product = product
    self.product_num = product_num or 2
    self.drop = drop or false
end

local function SpawnProduct(prefab)
    local product = SpawnPrefab(prefab)
    if product.components.inventoryitem ~= nil then
        product.components.inventoryitem:InheritMoisture(TheWorld.state.wetness, TheWorld.state.iswet)
    end
    return product
end

function Shearable:Shear(shearer, numworks)
    -- A hacky way for workable/hackable handlers to check if they're getting a shear, not a hack
    self.shearing = true

    if self.inst.components.hackable then
        self.inst.components.hackable:Destroy(shearer)
    end

    if self.product then
        local pt = self.inst:GetPosition()
        if not self.drop and shearer and shearer.components.inventory then
            local product = SpawnProduct(self.product)
            if product then
                if self.product_num > 1 then
                    if product.components.stackable then
                        product.components.stackable:SetStackSize(self.product_num)
                    else
                        for i = 1, self.product_num - 1 do
                            local _product = SpawnProduct(self.product)
                            shearer.components.inventory:GiveItem(_product, nil, pt)
                        end
                    end
                end
                shearer.components.inventory:GiveItem(product, nil, pt)
            end
        elseif self.inst.components.lootdropper then
            pt.y = pt.y + self.drop_height

            for i = 1, self.product_num do
                self.inst.components.lootdropper:SpawnLootPrefab(self.product, pt)
            end
        end
    end

    if self.onshearfn then
        self.onshearfn(self.inst, shearer)
    end

    self.shearing = nil
end

function Shearable:CanShear()
    return self.canbesheared
end

function Shearable:SetOnShearFn(fn)
    self.onshearfn = fn
end

return Shearable
