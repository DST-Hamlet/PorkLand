local RowboatWakeSpawner = Class(function(self, inst)
    self.inst = inst
    self.timeSinceSpawn = 0
    self.spawning = false
    self.spawnPeriod = 0.2
end)

function RowboatWakeSpawner:StartSpawning()
    self.inst:StartUpdatingComponent(self)
    self.spawning = true
    self.timeSinceSpawn = self.spawnPeriod  -- So that one gets spawned as soon as the boat starts moving
end

function RowboatWakeSpawner:StopSpawning()
    self.inst:StopUpdatingComponent(self)
    self.spawning = false
end

function RowboatWakeSpawner:OnUpdate(dt)
    if self.spawning then
        self.timeSinceSpawn = self.timeSinceSpawn + dt
        if self.timeSinceSpawn > self.spawnPeriod then
            local parent = self.inst
            if self.inst.components.sailable then
                parent = self.inst.components.sailable:GetSailor() or self.inst
            end
            local x, y, z = parent.Transform:GetWorldPosition()
            if x and y and z then
                local wake = SpawnPrefab("rowboat_wake")
                wake.Transform:SetPosition(x, y, z)
                wake.Transform:SetRotation(parent.Transform:GetRotation() or 0)
                self.timeSinceSpawn = 0
            else
               print("WAVE HAS NO LOCATION")
            end
        end
    end
end

return RowboatWakeSpawner
