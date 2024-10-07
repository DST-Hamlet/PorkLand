local windfx_spawn_rate = 0
local windfx_spawn_per_sec = 16

local PersistenceVision = Class(function(self, inst)
    self.inst = inst
    self.persistence_ents = {}

    inst:StartUpdatingComponent(self)
end)

function PersistenceVision:OnUpdate(dt)
    local x, y, z = self.inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, 3, nil, {"INLIMBO"})
    for k, v in pairs(ents) do
        local _x, _y, _z = v.Transform:GetWorldPosition()
        if TheSim:GetLightAtPoint(_x, _y, _z) > TUNING.DARK_CUTOFF then
            self.persistence_ents[v] = 1
        end
    end

    for k, v in pairs(self.persistence_ents) do
        self.persistence_ents[k] = v - dt
        if self.persistence_ents[k] <= 0 then
            self.persistence_ents[k] = nil
        end
    end
end

return PersistenceVision
