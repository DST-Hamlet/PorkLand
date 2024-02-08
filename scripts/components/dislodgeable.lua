local ondislodgeable = function(self, ondislodgeable)
    if ondislodgeable and self.caninteractwith then
        self.inst:AddTag("DISLODGE_workable")
    else
        self.inst:RemoveTag("DISLODGE_workable")
    end
end

local Dislodgeable = Class(function(self, inst)
    self.inst = inst

    self.product = nil
    self.product_num = 1

    self.ondislodgedfn = nil
    self.canbedislodgedfn = nil

    self.canbedislodged = nil
    self.caninteractwith = true

    self.dropsymbol = nil
end,
nil,
{
    canbedislodged = ondislodgeable
})

function Dislodgeable:OnRemoveFromEntity()
    self.inst:RemoveTag("DISLODGE_workable")
end

function Dislodgeable:SetUp(product, num)
    self.canbedislodged = true
    self.product = product
    self.product_num = num or 1
end

function Dislodgeable:SetOnDislodgedFn(fn)
    self.ondislodgedfn = fn
end

function Dislodgeable:SetCanBeDislodgedFn(fn)
    self.canbedislodgedfn = fn
end

function Dislodgeable:SetDropFromSymbol(symbolname)
    self.dropsymbol = symbolname
end

function Dislodgeable:GetLootDropPosition()
    return self.dropsymbol and Vector3(self.inst.AnimState:GetSymbolPosition(self.dropsymbol, 0,0,0)) or nil
end

function Dislodgeable:CanBeDislodged()
    return (self.canbedislodgedfn == nil or self.canbedislodgedfn(self.inst)) and self.canbedislodged
end

function Dislodgeable:Dislodge(dislodger)
    if self:CanBeDislodged() and self.caninteractwith then
        local pt = self:GetLootDropPosition()
        local alwaysinfront = (pt == nil)
        local loot = nil

        for i = 1, self.product_num do
            loot = SpawnPrefab(self.product)
            self.inst.components.lootdropper:DropLootPrefab(loot, pt, nil, nil, alwaysinfront)
        end

        if self.ondislodgedfn then
            self.ondislodgedfn(self.inst, dislodger, loot)
        end

        self.inst:PushEvent("dislodged", {dislodger = dislodger, loot = loot})
    end
end

function Dislodgeable:OnSave()
    local data = {
        caninteractwith = self.caninteractwith,
    }

    return next(data) ~= nil and data or nil
end

function Dislodgeable:OnLoad(data)
    if data ~= nil then
        self.caninteractwith = data.caninteractwith
    end
end

function Dislodgeable:GetDebugString()
    return "caninteractwith: "..tostring(self.caninteractwith)
        .." canbedislodged: "..tostring(self:CanBeDislodged())
end

return Dislodgeable
