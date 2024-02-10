local WorldWind = Class(function(self, inst)
    self.inst = inst

    self.velocity = 1

    self.angle = math.random(0, 360)

    self.time_to_wind_change = 1

    self.windfx_spawn_rate = 0
    self.windfx_spawn_pre_sec = 16

    self.inst:ListenForEvent("ms_cyclecomplete", function()
        self.angle = math.random(0, 360)
        self.inst:PushEvent("windchange", {angle = self.angle, velocity = self.velocity})
    end)

    self.inst:StartUpdatingComponent(self)
end)

function WorldWind:Start()
    self.inst:StartUpdatingComponent(self)
end

function WorldWind:Stop()
    self.inst:StopUpdatingComponent(self)
end

function WorldWind:OnSave()
    return
    {
        angle = self.angle,
    }
end

function WorldWind:OnLoad(data)
    if data then
        self.angle = data.angle or self.angle
    end
end

function WorldWind:SetOverrideAngle(angle)
    self.override_angle = angle
end

function WorldWind:GetWindAngle()
    return self.override_angle or self.angle
end

function  WorldWind:GetWindVelocity()
    return self.velocity
end

function WorldWind:GetDebugString()
    return string.format("Angle: %4.4f, Veloc: %3.3f", self.angle, self.velocity)
end

function WorldWind:SpawnWindSwirl(x, y, z, speed, angle)
    local swirl = SpawnPrefab("windswirl")
    swirl.Transform:SetPosition(x, y, z)
    swirl.Transform:SetRotation(angle + 180)
    swirl.AnimState:SetMultColour(1, 1, 1, math.clamp(speed, 0.0, 1.0))
end

function WorldWind:OnUpdate(dt)
    if not self.inst then
        self:Stop()
        return
    end

    local windspeed = TheWorld.net.components.plateauwind:GetWindSpeed()
    if windspeed > 0.01 and TheWorld.net.components.plateauwind:GetIsWindy() then
        self.windfx_spawn_rate = self.windfx_spawn_rate + self.windfx_spawn_pre_sec * dt
        if self.windfx_spawn_rate > 1.0 then
            for _, player in pairs(AllPlayers) do
                local px, py, pz = player.Transform:GetWorldPosition()
                local dx, dz = 16 * UnitRand(), 16 * UnitRand()
                local x, y, z = px + dx, py, pz + dz
                local angle = self:GetWindAngle()

                self:SpawnWindSwirl(x, y, z, windspeed, angle)
                self.windfx_spawn_rate = self.windfx_spawn_rate - (1.0 / #AllPlayers) -- scale with players
            end
        end
    end
end

return WorldWind
