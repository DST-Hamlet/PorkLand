local Throwable = Class(function(self, inst)
    self.inst = inst

    self.inst:AddTag("Throwable")

    self.onthrown = nil
    -- self.onland = nil
    self.throwdistance_controller = 10
    self.random_angle = 10

    self.yOffset = 1

    self.speed = 10
end)

function Throwable:GetThrowPoint()
    --For use with controller.
    local owner = self.inst.components.inventoryitem.owner
    if not owner then return end
    local pt = nil
    local rotation = owner.Transform:GetRotation()*DEGREES
    local pos = owner:GetPosition()

    for r = self.throwdistance_controller, 1, -1 do
        local numtries = 2*PI*r
        pt = FindValidPositionByFan(rotation, r, numtries, function() return true end) --TODO: #BDOIG Might not need to be walkable?
        if pt then
            return pt + pos
        end
    end
end

function Throwable:Throw(pt, thrower)
    local tothrow = self.inst

    if thrower == nil and self.inst.components.inventoryitem then
        thrower = self.inst.components.inventoryitem:GetGrandOwner()
    end


    if thrower and self.inst.components.inventoryitem and self.inst.components.inventoryitem:GetGrandOwner() == thrower then
        tothrow = thrower.components.inventory:DropItem(self.inst)
        print("Item after being dropped from the inventory: " .. tostring(tothrow) .. " / prefab = " .. tostring(tothrow.prefab))
    end

    local grav = 39.24 -- 饥荒世界的重力是现实的4倍
    local yOffset = self.yOffset
    local pos = (thrower and thrower:GetPosition()) or (self.inst:IsValid() and not self.inst:IsInLimbo() and self.inst:GetPosition()) or nil

    if pos == nil then
        return
    end

    local offset = Vector3(0, yOffset, 0)
    local distance = pos:Dist(pt)
    local totarget = pt - pos
    local angle = math.atan2(totarget.z, totarget.x) + (math.random()*self.random_angle - (self.random_angle * 0.5))*DEGREES
    local time_to_target = distance/self.speed

    local Viy = ((grav*0.5*(time_to_target^2))-yOffset)/time_to_target

    tothrow.Transform:SetPosition((pos + offset):Get())
    tothrow.Physics:SetVel(self.speed*math.cos(angle), Viy, self.speed*math.sin(angle))

    local dir = Vector3((time_to_target*self.speed)*math.cos(angle), 0, (time_to_target*self.speed)*math.sin(angle))

    local thrownpt = thrower:GetPosition() + dir

    if self.onthrown then
        self.onthrown(tothrow, thrower, thrownpt, time_to_target)
    end

    tothrow:AddTag("falling")

    return true
end

return Throwable
