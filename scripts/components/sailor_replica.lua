local function OnBoatAttacked(inst)
    inst.replica.sailor.boatattackedevent:set_local(true)
    inst.replica.sailor.boatattackedevent:set(true)
end

local function OnBoatDirty(sailor)
    if not TheWorld.ismastersim then
        sailor.inst:PushEvent("disembarkboat")
    end

    if sailor._currentboat and sailor._currentboat:IsValid() then
        -- RemoveLocalNOCLICK(sailor._currentboat)
    end
    if sailor._boat:value() then
        sailor._currentboat = sailor._boat:value()

        if sailor.inst == ThePlayer then
            -- LocalNOCLICK(sailor._currentboat)
        end

        if not TheWorld.ismastersim then
            sailor.inst:PushEvent("embarkboat", {target = sailor._currentboat})
        end
        if not TheNet:IsDedicated() and sailor.inst == ThePlayer then
            sailor.inst:PushEvent("playboatmusic")
        end
        UpdateSailorPathcaps(sailor.inst, true)
    else
        if not TheNet:IsDedicated() and sailor.inst == ThePlayer then
            sailor.inst:PushEvent("stopboatmusic")
        end
        UpdateSailorPathcaps(sailor.inst, false)
        sailor._currentboat = nil
    end
end

local function OnBoatDirty_inst(inst)
    return OnBoatDirty(inst.replica.sailor)
end

local Sailor = Class(function(self, inst)
    self.inst = inst

    self._boat = net_entity(inst.GUID, "sailor._boat", "boatdirty")
    --boatattacked event only on remote clients
    self.boatattackedevent = net_bool(inst.GUID, "boathealth.boatattackedevent", not TheWorld.ismastersim and "boatattacked" or nil)

    self.inst:DoTaskInTime(0, function()
        self.inst:ListenForEvent("boatdirty", function()
            OnBoatDirty(self)
            self.inst:DoTaskInTime(1, OnBoatDirty_inst)
        end)
        OnBoatDirty(self)
    end)

    self._currentspeed = net_float(inst.GUID, "sailor._currentspeed")
    self._currentspeed:set(1)
    self.predict_currentspeed = nil

    self.acceleration = 6
    self.deceleration = 6
    
    self.perdictframe = 0

    if TheWorld.ismastersim then
        inst:ListenForEvent("boatattacked", OnBoatAttacked)
    end

    self.inst:StartUpdatingComponent(self)
end)

-- not in use, but leaving here since it doesn't really cause problems
function Sailor:IsSailing()
    return self.inst:HasTag("sailing")
end

function Sailor:GetBoat()
    if self.inst.components.sailor then
        return self.inst.components.sailor:GetBoat()
    end

    return self._currentboat
end

function Sailor:GetSpeed()
    return self.predict_speed or self._currentspeed:value()
end

function Sailor:OnUpdate(dt)
    local boat = self:GetBoat()
    if not TheWorld.ismastersim 
        and boat and boat.replica.sailable 
        and self.inst.sg then -- 延迟补偿开启时

        local current_speed = self.predict_speed or self._currentspeed:value()
        local target_speed = boat.replica.sailable._externalspeedmultiplier:value() + 6
        local deceleration = self.deceleration * (1 + boat.replica.sailable._externalaccelerationmultiplier:value())
        local acceleration = self.deceleration * (1 + boat.replica.sailable._externalaccelerationmultiplier:value())

        if not self.inst.sg:HasStateTag("boating") then
            self.perdictframe = self.perdictframe - 1
        else
            self.perdictframe = 1
        end
        if self.perdictframe <= 0 then
            self.perdictframe = 0
            target_speed = 1
        end

        if(target_speed > current_speed) then
            current_speed = current_speed + acceleration * dt
            if(current_speed > target_speed) then
               current_speed = target_speed
           end
        elseif (target_speed < current_speed) then
            current_speed = current_speed - deceleration * dt
            if(current_speed < 1) then
                current_speed = 1
            end
        end

        self.predict_speed = current_speed
    else -- 延迟补偿关闭时
        self.predict_speed = nil
    end
end

function Sailor:GetBoatHealth()
    local boat = self:GetBoat()
    return boat and boat.replica.boathealth and boat.replica.boathealth:GetPercent() or nil
end

function Sailor:AlignBoat(direction)
    if self.inst.components.sailor then
        self.inst.components.sailor:AlignBoat(direction)
    else
        local boat = self:GetBoat()
        if boat then
            boat.Transform:SetRotation(direction or self.inst.Transform:GetRotation())
        end
    end
end

return Sailor
