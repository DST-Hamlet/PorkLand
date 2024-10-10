local Throwable = Class(function(self, inst)
    self.inst = inst

    self.inst:AddTag("Throwable")

    self.onthrown = nil
    -- self.onland = nil
    self.throwdistance_controller = 10
    self.random_angle = 0

    self.yOffset = 1

    self.stopped = true

    self.speed = 10

    self.angle = 0

    self.maxdistance = math.huge
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

local function ThrowableOnCollide(inst, other)
    if inst.components.throwable and not inst.components.throwable.stopped then
        inst.components.throwable.stopped = true
        if inst.components.throwable.collidegroundtask then
            inst.components.throwable.collidegroundtask:Cancel()
            inst.components.throwable.collidegroundtask = nil
        end
        if inst.components.throwable.onhitfn ~= nil then
            inst.Physics:Stop()
            inst.components.throwable.onhitfn(inst, other)
        end
    end
end

function Throwable:SetOnHitFn(fn)
    self.onhitfn = fn
    if self.inst.Physics then
        self.inst.Physics:SetCollisionCallback(ThrowableOnCollide)
    end
end

function Throwable:FlatThrow(rotation, thrower, offset_vel)
    local tothrow = self.inst

    if thrower == nil and self.inst.components.inventoryitem then
        thrower = self.inst.components.inventoryitem:GetGrandOwner()
    end

    if thrower and self.inst.components.inventoryitem and self.inst.components.inventoryitem:GetGrandOwner() == thrower then
        tothrow = thrower.components.inventory:DropItem(self.inst)
        print("Item after being dropped from the inventory: " .. tostring(tothrow) .. " / prefab = " .. tostring(tothrow.prefab))
    end

    local grav = self.gravity or 39.24 -- 饥荒世界的重力是现实的4倍
    local yOffset = self.yOffset
    local pos = (thrower and thrower:GetPosition()) or (self.inst:IsValid() and not self.inst:IsInLimbo() and self.inst:GetPosition()) or nil

    if pos == nil then
        return
    end

    local offset = Vector3(0, yOffset, 0)
    local angle = rotation * DEGREES
    self.angle = angle
    local vel_y = offset_vel and offset_vel.y or 0

    local time_to_target = (vel_y / grav) + math.sqrt((2 * yOffset / grav) + (vel_y / grav)^2)

    if self.xOffset then
        offset = offset + Vector3(self.xOffset*math.cos(angle), 0, -self.xOffset*math.sin(angle))
    end

    self.stopped = false
    self.collidegroundtask = self.inst:DoTaskInTime(time_to_target, ThrowableOnCollide)

    tothrow.Transform:SetPosition((pos + offset):Get())

    local throwvel = Vector3(self.speed*math.cos(angle), 0, -self.speed*math.sin(angle))
    if offset_vel then
        throwvel = throwvel + offset_vel
    end
    if tothrow.components.inventoryitem then
        tothrow.components.inventoryitem:Launch(throwvel)
    else
        tothrow.Physics:SetVel(throwvel.x, throwvel.y, throwvel.z)
    end

    local dir = Vector3((time_to_target*self.speed)*math.cos(angle), 0, -(time_to_target*self.speed)*math.sin(angle))

    local thrownpt = thrower:GetPosition() + dir

    if self.onthrown then
        self.onthrown(tothrow, thrower, thrownpt, time_to_target)
    end

    tothrow:AddTag("falling")

    return true
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

    local grav = self.gravity or 39.24 -- 饥荒世界的重力是现实的4倍
    local yOffset = self.yOffset
    local pos = (thrower and thrower:GetPosition()) or (self.inst:IsValid() and not self.inst:IsInLimbo() and self.inst:GetPosition()) or nil

    if pos == nil then
        return
    end

    local offset = Vector3(0, yOffset, 0)
    local distance = math.min(self.maxdistance, pos:Dist(pt))
    local totarget = pt - pos
    local angle = -(math.atan2(totarget.z, totarget.x) + (math.random()*self.random_angle - (self.random_angle * 0.5)) * DEGREES)
    self.angle = angle
    local time_to_target = distance/self.speed

    if self.xOffset then
        offset = offset + Vector3(self.xOffset*math.cos(angle), 0, -self.xOffset*math.sin(angle))
    end

    self.stopped = false
    self.collidegroundtask = self.inst:DoTaskInTime(time_to_target, ThrowableOnCollide)

    local Viy = ((grav*0.5*(time_to_target^2))-yOffset)/time_to_target

    tothrow.Transform:SetPosition((pos + offset):Get())

    local throwvel = Vector3(self.speed*math.cos(angle), Viy, -self.speed*math.sin(angle))
    if tothrow.components.inventoryitem then
        tothrow.components.inventoryitem:Launch(throwvel)
    else
        tothrow.Physics:SetVel(throwvel.x, throwvel.y, throwvel.z)
    end

    local dir = Vector3((time_to_target*self.speed)*math.cos(angle), 0, -(time_to_target*self.speed)*math.sin(angle))

    local thrownpt = thrower:GetPosition() + dir

    if self.onthrown then
        self.onthrown(tothrow, thrower, thrownpt, time_to_target)
    end

    tothrow:AddTag("falling")

    return true
end

return Throwable
