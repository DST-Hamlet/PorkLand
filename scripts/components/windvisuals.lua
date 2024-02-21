local windfx_spawn_rate = 0
local windfx_spawn_per_sec = 16

local WindVisuals = Class(function(self, inst)
	self.inst = inst

	inst:StartUpdatingComponent(self)
end)

function WindVisuals:SpawnWindSwirl(x, y, z, angle)
    local swirl = SpawnPrefab("windswirl")
    swirl.Transform:SetPosition(x, y, z)
    swirl.Transform:SetRotation(angle + 180)
end

function WindVisuals:OnUpdate(dt)
    -- No need to check for plateauwind component, WindVisuals is only added in Hamlet
    local windspeed = TheWorld.net.components.plateauwind:GetWindSpeed()
    if windspeed > 0.01 and TheWorld.net.components.plateauwind:GetIsWindy() then
        windfx_spawn_rate = windfx_spawn_rate + windfx_spawn_per_sec * dt
        if windfx_spawn_rate > 1.0 then
            local px, py, pz = self.inst.Transform:GetWorldPosition()
            local dx, dz = 16 * UnitRand(), 16 * UnitRand()
            local x, y, z = px + dx, py, pz + dz
            local angle = TheWorld.net.components.plateauwind:GetWindAngle()

            self:SpawnWindSwirl(x, y, z, angle)
            windfx_spawn_rate = windfx_spawn_rate - 1.0
        end
    end
end

return WindVisuals
