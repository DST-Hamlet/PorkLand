local AddComponentPostInit = AddComponentPostInit
GLOBAL.setfenv(1, GLOBAL)

AddComponentPostInit("worldwind", function(self)
	self.windfx_spawn_rate = 0
	self.windfx_spawn_pre_sec = 16

    function self:SpawnWindSwirl(x, y, z, speed, angle)
        local swirl = SpawnPrefab("windswirl")
        swirl.Transform:SetPosition(x, y, z)
        swirl.Transform:SetRotation(angle + 180)
        swirl.AnimState:SetMultColour(1, 1, 1, math.clamp(speed, 0.0, 1.0))
    end

    local OnUpdate = self.OnUpdate
    function self:OnUpdate(dt)
        OnUpdate(self, dt)
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
end)
