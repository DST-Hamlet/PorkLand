local WorldWind = Class(function(self, inst)
    self.inst = inst

    self.velocity = 1

    self.angle = math.random(0, 360)

    self.time_to_wind_change = 1

    self.windfx_spawn_rate = 0
    self.windfx_spawn_pre_sec = 16

    self.inst:ListenForEvent("ms_cyclecomplete", function()
        self.angle = math.random(0, 360)
        self.inst:PushEvent("pl_windchange", {angle = self.angle, velocity = self.velocity})
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

return WorldWind
