local SPEED_VAR_PERIOD = 5
local SPEED_VAR_PERIOD_VARIANCE = 2

local BlowInWind = Class(function(self, inst)
    self.inst = inst

    self.max_speed_multiplier = 1.5
    self.min_speed_multiplier = .5
    self.average_speed = (TUNING.WILSON_RUN_SPEED + TUNING.WILSON_WALK_SPEED)/2
    self.speed = 0

    self.wind_angle = 0
    self.wind_vector = Vector3(0,0,0)

    self.current_angle = 0
    self.current_vector = Vector3(0,0,0)

    self.velocity = Vector3(0,0,0)

    self.speed_var_time = 0
    self.speed_var_period = GetRandomWithVariance(SPEED_VAR_PERIOD, SPEED_VAR_PERIOD_VARIANCE)

    self.sound_parameter = nil
    self.sound_name = nil

    self.spawn_period = 1.0
    self.time_since_spawn = self.spawn_period

    self.inst:ListenForEvent("on_landed", function(it, data)
        self:Start()
    end)
    self.inst:ListenForEvent("ondropped", function(it, data)
        self:Start()
    end)
    self.inst:ListenForEvent("onpickup", function(it, data)
        self:Stop()
    end)

    self.inst:WatchWorldState("season", function(inst, season)
        if season == SEASONS.LUSH then
            self:Start()
        end
    end)
end)

function BlowInWind:OnRemoveEntity()
    self:Stop()
end

function BlowInWind:OnEntitySleep()
    self:Stop()
end

function BlowInWind:OnEntityWake()
    self:Start(self.wind_angle, self.velocity_multiplier)
end

function BlowInWind:Start(angle, velocity)
    if self.inst:HasTag("falling") or (self.inst.components.inventoryitem and self.inst.components.inventoryitem.owner) then
        return
    end

    if angle then
        self.wind_angle = angle
        self.wind_vector = Vector3(math.cos(angle), 0, math.sin(angle)):GetNormalized()
        self.current_angle = angle
        self.current_vector = Vector3(math.cos(angle), 0, math.sin(angle)):GetNormalized()
        self.inst.Transform:SetRotation(self.current_angle)
    end

    if velocity then
        self.velocity_multiplier = velocity
    end

    if self.inst.SoundEmitter and self.soundPath and self.sound_name then
        self.inst.SoundEmitter:PlaySound(self.soundPath, self.sound_name)
    end

    self.inst:StartUpdatingComponent(self)
    self.check_land_time = math.random()
end

function BlowInWind:Stop()
    self.velocity = Vector3(0,0,0)
    self.speed = 0.0
    self.inst.Physics:Stop()

    if self.inst.SoundEmitter and self.sound_name then
        self.inst.SoundEmitter:KillSound(self.sound_name)
    end

    self.inst:StopUpdatingComponent(self)
end

function BlowInWind:ChangeDirection(angle)
    if angle then
        self.wind_angle = angle
        self.wind_vector = Vector3(math.cos(angle), 0, math.sin(angle)):GetNormalized()
    end
end

function BlowInWind:SetMaxSpeedMultiplier(speed)
    if speed then
        self.max_speed_multiplier = speed
    end
end

function BlowInWind:SetMinSpeedMultiplier(speed)
    if speed then
        self.min_speed_multiplier = speed
    end
end

function BlowInWind:SetAverageSpeed(speed)
    if speed then
        self.average_speed = speed
    end
end

function BlowInWind:GetSpeed()
    return self.speed
end

function  BlowInWind:GetVelocity()
    return self.velocity
end

function BlowInWind:SpawnWindTrail(dt)
    self.time_since_spawn = self.time_since_spawn + dt
    if self.time_since_spawn > self.spawn_period and math.random() < 0.8 then
        local wake = SpawnPrefab("windtrail")
        local x, y, z = self.inst.Transform:GetWorldPosition()
        wake.Transform:SetPosition(x, y, z)
        wake.Transform:SetRotation(self.inst.Transform:GetRotation() + 180)

        self.time_since_spawn = 0
    end
end

function BlowInWind:OnUpdate(dt)
    if not self.inst then
        self:Stop()
        return
    end

    if self.inst:HasTag("falling") or (self.inst.components.inventoryitem and self.inst.components.inventoryitem.owner) then
        return
    end

    self.check_land_time = self.check_land_time - dt
    if self.check_land_time < 0 then
        self.check_land_time = 1 -- don't care about time accumulation
        if self.inst.components.inventoryitem then
            self.inst.components.inventoryitem:SetLanded(true, false)
        end
    end

    if TheWorld:HasTag("porkland") then
        if TheWorld.net.components.plateauwind and TheWorld.net.components.plateauwind:GetIsWindy() then
            local windspeed = TheWorld.net.components.plateauwind:GetWindSpeed() -- from 0 to 1
            local windangle = TheWorld.net.components.plateauwind:GetWindAngle() * DEGREES
            self.velocity = Vector3(windspeed * math.cos(windangle), 0.0, windspeed * math.sin(windangle))
        else
            self:Stop()
            return
        end
    else
        self.velocity = self.velocity + (self.wind_vector * dt)
        return
    end

    -- unbait from traps
    if self.inst.components.bait and self.inst.components.bait.trap then
        self.inst.components.bait.trap:RemoveBait()
    end

    if self.velocity:Length() > 1 then
        self.velocity = self.velocity:GetNormalized()
    end

    -- Map velocity magnitudes to a useful range of walkspeeds
    self.speed = self.velocity:Length() * self.average_speed

    -- Do some variation on the speed if velocity is a reasonable amount
    if self.velocity:Length() >= .5 then
        self.speed_var_time = self.speed_var_time + dt
        if self.speed_var_time > SPEED_VAR_PERIOD then
            self.speed_var_time = 0
            self.speed_var_period = GetRandomWithVariance(SPEED_VAR_PERIOD, SPEED_VAR_PERIOD_VARIANCE)
        end
        local speedvar = math.sin(2 * PI * (self.speed_var_time / self.speed_var_period))
        local mult = Remap(speedvar, -1, 1, self.min_speed_multiplier, self.max_speed_multiplier)
        self.speed = self.speed * mult
    end

    -- Change the sound parameter if there is one
    if self.sound_name and self.sound_parameter and self.inst.SoundEmitter then
        self.soundspeed = self.speed / self.average_speed * self.max_speed_multiplier
        self.inst.SoundEmitter:SetParameter(self.sound_name, self.sound_parameter, self.soundspeed)
    end

    -- Walk!
    self.current_angle = math.atan2(self.velocity.z, self.velocity.x) / DEGREES
    self.inst.Transform:SetRotation(self.current_angle)
    self.inst.Physics:SetMotorVel(self.speed, 0, 0)


    if self.speed > 3.0 then
        self:SpawnWindTrail(dt)
    end

    local x, y, z = self.inst.Transform:GetWorldPosition()
    local tile = TheWorld.Map:GetTileAtPoint(x, y, z)
    if TheWorld.Map:ReverseIsVisualWaterAtPoint(x, y, z) then
        if self.inst.components.burnable and self.inst.components.burnable:IsBurning() then
            self.inst.components.burnable:Extinguish() --Do this before anything that required the inventory item component, it gets removed when something is lit on fire and re-added when it's extinguished
        end
        if self.inst.components.inventoryitem then
            self.inst.components.inventoryitem:SetLanded(true)
            self.inst:PushEvent("on_landed") -- force this event for floater component, since it's already landed
            self.inst.components.inventoryitem:TryToSink()
        end
        if self.inst.components.floater then
            -- maybe slowly stops it?
            local vx, vy, vz = self.inst.Physics:GetMotorVel()
            self.inst.Physics:SetMotorVel(0.5 * vx, 0, 0)
            self.inst:DoTaskInTime(1, function(inst)
                self.inst.Physics:SetMotorVel(0, 0, 0)
            end)
            self.inst:StopUpdatingComponent(self)
        end
    elseif TileGroupManager:IsImpassableTile(tile) and not TheWorld.Map:IsVisualGroundAtPoint(x, y, z) then
        self.inst.components.inventoryitem:SetLanded(false, true)
        self.inst.Physics:SetMotorVel(0, 0, 0)
    end
end

return BlowInWind
