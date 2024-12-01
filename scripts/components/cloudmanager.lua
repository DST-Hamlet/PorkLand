local CloudManager = Class(function(self, inst)
    self.inst = inst

    self.clouds = {}

    self.num = 32
    self.cloud_dist = 2.5

    self.oldheading = 0
end)

function CloudManager:Init()
    self.clouds_parent = SpawnPrefab("group_parent")
    local random_offset_z = 0
    for i = 1, self.num do
        local cloud = SpawnPrefab("cloud_fx")
        self.clouds[i] = cloud

        cloud.entity:SetParent(self.clouds_parent.entity)
        random_offset_z = random_offset_z + 4 + math.random() * 8
        cloud.Transform:SetPosition((i - self.num / 2) * self.cloud_dist, 0, random_offset_z)
    end
end

function CloudManager:SetEnabled(enabled)
    if enabled then
        self.clouds_parent:Show()
    else
        self.clouds_parent:Hide()
    end
end

function CloudManager:Move(offset_x, offset_z)
    if self.clouds_parent and self.clouds_parent:IsValid() then
        for i = 1, self.num do
            local cloud = self.clouds[i]
            if cloud and cloud:IsValid() then
                local x, y, z = cloud.Transform:GetWorldPosition()
                x, y, z = self.clouds_parent.entity:WorldToLocalSpace(x, y, z)
                x = x + offset_x
                z = z + offset_z
                x = (x + self.num * self.cloud_dist / 2) % (self.num * self.cloud_dist) - self.num * self.cloud_dist / 2
                z = (z + 16 / 2) % (16) - 16 / 2
                cloud.Transform:SetPosition(x, y, z)
            end
        end
    end
end

function CloudManager:UpdatePos(dt)
    local newpos = TheCamera.currentpos

    local lx, ly, lz = self.clouds_parent.entity:WorldToLocalSpace(newpos.x, newpos.y, newpos.z)
    local angle_delta = (TheCamera.heading - self.oldheading)
    if angle_delta > 180 then
        angle_delta = angle_delta - 360
    elseif angle_delta < - 180 then
        angle_delta = angle_delta + 360
    end
    lz = lz + 2 * PI * TheCamera.distance * (angle_delta / 360)
    self:Move(- lx, - lz)
    self.oldheading = TheCamera.heading

    local x, y, z = self.clouds_parent.Transform:GetWorldPosition()
    self.clouds_parent.Transform:SetPosition(newpos.x, -4, newpos.z)
    self.clouds_parent.Transform:SetRotation(- TheCamera.heading)
end

return CloudManager
