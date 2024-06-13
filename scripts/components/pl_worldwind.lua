local MIN_TIME_TO_WIND_CHANGE = .5*TUNING.SEG_TIME
local MAX_TIME_TO_WIND_CHANGE = TUNING.SEG_TIME

local WorldWind = Class(function(self, inst)
    self.inst = inst

    self.velocity = 1

    self.angle = math.random(0, 360)

    self.time_to_wind_change = 1

    self.windfx_spawn_rate = 0
    self.windfx_spawn_pre_sec = 16

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

function WorldWind:OnUpdate(dt)

	if not self.inst then
		self:Stop()
		return
	end

	self.time_to_wind_change = self.time_to_wind_change - dt

	if self.time_to_wind_change <= 0 then
        if TheWorld.net.components.plateauwind:GetWindSpeed() > 0.01 and TheWorld.net.components.plateauwind:GetIsWindy() then  -- 正在刮风时不改变风向
            self.time_to_wind_change = math.random(5, 10)
        else
            self.angle = math.random(0,360)
            self.inst:PushEvent("pl_windchange", {angle=self.angle, velocity=self.velocity})

            self.time_to_wind_change = math.random(MIN_TIME_TO_WIND_CHANGE, MAX_TIME_TO_WIND_CHANGE)
        end
	end
end

return WorldWind
