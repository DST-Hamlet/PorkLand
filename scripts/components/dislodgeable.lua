local function ondislodgeable(self, canbedislodged)
    if canbedislodged then
        self.inst:AddTag("DISLODGE_workable")
    else
        self.inst:RemoveTag("DISLODGE_workable")
    end
end

local function AlwaysInPlayer(self, loot, pt, dislodger)
    local angle = (180 - dislodger:GetAngleToPoint(pt.x, 0, pt.z) + math.random() * 60 - 30) * DEGREES
    local speed = 1 * math.random()
    local dir = Vector3(math.cos(angle), 0, math.sin(angle))
    loot.Physics:SetVel(speed * math.cos(angle), math.random() * 2 + 8, speed * math.sin(angle))
    if loot.Physics ~= nil and self.inst.Physics ~= nil then
        pt = pt + dir*((loot.Physics:GetRadius() or 1) + (self.inst.Physics:GetRadius() or 0))
        loot.Transform:SetPosition(pt.x,pt.y,pt.z)
    end
end

local Dislodgeable = Class(function(self, inst)
    self.inst = inst

    self.canbedislodged = nil
    self.product = nil
    self.ondislodgedfn = nil
    self.caninteractwith = true
    self.numtoharvest = 1
    self.dropsymbol = nil
end,
nil,
{
    canbedislodged = ondislodgeable,
})

function Dislodgeable:SetUp(product, number)
    self.canbedislodged = true
    self.product = product
    self.numtoharvest = number or 1
end

function Dislodgeable:Dislodge(dislodger)
    if self:CanBeDislodged() and self.caninteractwith then
        local pt = self.inst:GetPosition()

        for _ = 1, self.numtoharvest do
            local loot = SpawnPrefab(self.product)

            if loot ~= nil then
                if self.ondislodgedfn ~= nil then
                    self.ondislodgedfn(self.inst, dislodger, loot)
                end
                AlwaysInPlayer(self, loot, pt, dislodger)
                self:SetDislodged()
                self.inst:PushEvent("dislodged", {dislodger = dislodger, loot = loot})
            end
        end
    end
end

function Dislodgeable:OnRemoveFromEntity()
    self.inst:RemoveTag("DISLODGE_workable")
end

function Dislodgeable:SetOnDislodgedFn(fn)
    self.ondislodgedfn = fn
end

function Dislodgeable:CanBeDislodged()
    return self.canbedislodged
end

function Dislodgeable:SetDislodged()
    self.canbedislodged = false
end

return Dislodgeable
