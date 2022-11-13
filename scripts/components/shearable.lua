local Shearable = Class(function(self, inst)
    self.inst = inst

    inst:AddTag("shearable")

    self.shaveable = nil
    self.product = nil
    self.drop = nil
    self.product_amt = 0

    self.canshearfn = nil
    self.onshearfn = nil
end)

function Shearable:SetProduct(product, product_amt, drop)
    self.product = product
    self.product_amt = product_amt or 2
    self.drop = drop
end

function Shearable:Shear(shearer, numworks)
    if self.inst.components.hackable then
        numworks = self.inst.components.hackable.hacksleft
        self.inst.components.hackable:Hack(shearer, numworks, self.product_amt, true)
    else
        if self.drop then
            if self.inst.components.lootdropper then
                local num = self.product_amt
                local pt = self.inst:GetPosition()
                pt.y = pt.y + (self.dropheight or 0)

                for i = 1, num do
                    self.inst.components.lootdropper:SpawnLootPrefab(self.product, pt)
                end
            end
        else
            if self.product_amt then
                local product = SpawnPrefab(self.product)
                if product then
                    if product.components.inventoryitem ~= nil then
                        product.components.inventoryitem:InheritMoisture(TheWorld.state.wetness, TheWorld.state.iswet)
                    end

                    local numtoharvest = self.product_amt
                    if numtoharvest > 1 and product.components.stackable ~= nil then
                        product.components.stackable:SetStackSize(numtoharvest)
                    end
                    shearer.components.inventory:GiveItem(product, nil, self.inst:GetPosition())
                end
            end
        end

        if self.onshearfn then
            self.onshearfn(self.inst, shearer)
        end
    end
end

function Shearable:CanShear()
    if self.inst.components.hackable and self.inst.components.hackable:CanBeHacked() then
        return self.inst.components.hackable.hacksleft > 0
    else
        if self.canshearfn then
            return self.canshearfn(self.inst)
        end
    end
end

function Shearable:SetOnShearFn(fn)
    self.onshearfn = fn
end

function Shearable:SetCanShearFn(fn)
    self.canshearfn = fn
end

return Shearable
