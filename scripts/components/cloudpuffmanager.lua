local function GetCloudPuffRadius()
    -- From values from camera_volcano.lua, camera range 30 to 100
    local percent = (TheCamera:GetDistance() - 30) / (70)
    local row_radius = (24 - 16) * percent + 16
    local col_radius = (8 - 2) * percent + 2

    return row_radius, col_radius
end

local CloudPuffManager = Class(function(self, inst)
    self.inst = inst

    self.cloudpuff_per_sec = 1.5
    self.cloudpuff_spawn_rate = 0

    self.inst:StartUpdatingComponent(self)
end)

function CloudPuffManager:OnUpdate(dt)
    if self.inst:HasTag("inside_interior") then
        return
    end

    local px, py, pz = self.inst.Transform:GetWorldPosition()

    self.cloudpuff_spawn_rate = self.cloudpuff_spawn_rate + self.cloudpuff_per_sec * dt

    local radius = GetCloudPuffRadius() -- shouldn't row, col radius correspond to x and z position? instead of just 1 radius for both?

    while self.cloudpuff_spawn_rate > 10.0 do
        local dx, dz = radius * UnitRand(), radius * UnitRand()
        local x, y, z = px + dx, py, pz + dz

        if IsSurroundedByTile(x, y, z, 1, WORLD_TILES.IMPASSABLE) then
            local cloudpuff = SpawnPrefab("cloudpuff_visual")
            cloudpuff.Transform:SetPosition(x, y, z)
        end

        self.cloudpuff_spawn_rate = self.cloudpuff_spawn_rate - 1.0
    end
end

return CloudPuffManager
