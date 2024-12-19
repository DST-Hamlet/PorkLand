local UPDATE_PERIOD_WAKE = 0.25
local UPDATE_PERIOD_SLEEP = 60
local UPDATE_PERIOD_PLAYER = FRAMES * 2

local function OnUpdate(inst)
    if inst:IsInLimbo() or not inst:IsValid() or inst.components.inventoryitem or (not inst.components.health or inst.components.health:IsDead()) then
        return
    end

    local x, y, z = inst.Transform:GetWorldPosition()

    local isininteriorregion = TheWorld.components.interiorspawner and TheWorld.components.interiorspawner:IsInInteriorRegion(x, z)

    if isininteriorregion and TheWorld.components.interiorspawner:IsInInteriorRoom(x, z) then
        return
    end

    if not inst:CanOnWater() and TheWorld.Map:ReverseIsVisualWaterAtPoint(x, y, z) and not inst.components.drownable then
        inst.components.keeponpassable:FallingTest("drowning")
        return
    end

    if not inst:CanOnLand() and TheWorld.Map:ReverseIsVisualGroundAtPoint(x, y, z) then
        inst.components.keeponpassable:FallingTest("nooxygen")
        return
    end

    if not inst:CanOnImpassable() and TheWorld.Map:IsImpassableAtPoint(x, y, z) then
        if isininteriorregion then
            inst.components.keeponpassable:FallingTest("squish")
        else
            inst.components.keeponpassable:FallingTest("gravity")
        end
        return
    end
end

local KeepOnPassable = Class(function(self, inst)
    self.inst = inst
    self.period = inst:IsAsleep() and UPDATE_PERIOD_SLEEP or UPDATE_PERIOD_WAKE
    if self.inst:HasTag("player") then
        self.period = UPDATE_PERIOD_PLAYER
    end

    self:Schedule()
end)

function KeepOnPassable:FallingTest(type)
    if not self.inst.components.health then
        return
    end

    if type ~= "squish" and self.lastsavetime and GetTime() - self.lastsavetime < 1 then
        local damage = self.inst.components.health.currenthealth * 10
        self.inst.components.health:DoDelta(-damage, nil, type, nil, nil, true)
    else
        self.lastsavetime = GetTime()
        local pt = self.inst:GetPosition()
        local dest = FindNearbyLand(pt, 1)
        if not dest then
            dest = FindNearbyLand(pt, 2)
        end
        if not dest then
            dest = FindNearbyLand(pt, 4)
        end
        if dest ~= nil then
            if self.inst.Transform ~= nil then
                self.inst.Transform:SetPosition(dest:Get())
            elseif self.inst.Physics ~= nil then
                self.inst.Physics:Teleport(dest:Get())
            end
        end
    end
end

function KeepOnPassable:Schedule(new_period)
    if new_period ~= nil then
        self.period = new_period
    end
    if self.inst:HasTag("player") then
        self.period = UPDATE_PERIOD_PLAYER
    end

    self:Stop()
    self.task = self.inst:DoPeriodicTask(self.period, OnUpdate, math.random() * self.period)
end

function KeepOnPassable:Stop()
    if self.task ~= nil then
        self.task:Cancel()
        self.task = nil
    end
end

function KeepOnPassable:ForceUpdate()
    OnUpdate(self.inst)
end

function KeepOnPassable:OnEntitySleep()
    self:Schedule(UPDATE_PERIOD_SLEEP)
end

function KeepOnPassable:OnEntityWake()
    self:Schedule(UPDATE_PERIOD_WAKE)
end

KeepOnPassable.OnRemoveEntity = KeepOnPassable.Stop
KeepOnPassable.OnRemoveFromEntity = KeepOnPassable.Stop

return KeepOnPassable
