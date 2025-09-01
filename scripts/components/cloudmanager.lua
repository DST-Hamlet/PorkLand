local CloudManager = Class(function(self, inst)
    self.inst = inst

    self.enabled = true

    self.clouds = {}
    self.clouds_move_offset = {}

    self.num = 48
    self.cloud_dist = 2.5
    self.width = 14.4

    self.oldheading = 0

    self.top_index = 0

    self.offset_y = 0
end)

function CloudManager:Init()
    self.clouds_parent = SpawnPrefab("group_parent")
    self.cloud_fx = SpawnPrefab("cloud_fx")
    local random_offset_z = 0
    for i = 1, self.num do
        local cloud = SpawnPrefab("group_child")
        self.clouds[i] = cloud
        self.clouds_move_offset[i] = math.random() * PI2

        cloud.entity:SetParent(self.clouds_parent.entity)
        random_offset_z = random_offset_z + 2 + math.random() * self.width / 2
        cloud.Transform:SetPosition((i - self.num / 2) * self.cloud_dist, 0, random_offset_z)

        self.top_index = i
    end
end

function CloudManager:SetEnabled(enabled)
    if enabled then
        self.enabled = true
    else
        self.enabled = false
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
                z = (z + self.width / 2) % (self.width) - self.width / 2
                cloud.Transform:SetPosition(x, y, z)

                if - x > self.num * self.cloud_dist / 2 - self.cloud_dist and - x <= self.num * self.cloud_dist / 2 then
                    self.top_index = i -- 遮挡排序
                end
            end
        end
    end
end

function CloudManager:UpdatePos(dt)
    local newpos = TheCamera.currentpos

    local lx, _, lz = self.clouds_parent.entity:WorldToLocalSpace(newpos.x, newpos.y, newpos.z)
    local angle_delta = (TheCamera.heading - self.oldheading)
    if angle_delta > 180 then
        angle_delta = angle_delta - 360
    elseif angle_delta < - 180 then
        angle_delta = angle_delta + 360
    end
    lz = lz + 2 * PI * TheCamera.distance * (angle_delta / 360)
    self:Move(- lx, - lz)
    self.oldheading = TheCamera.heading

    self.clouds_parent.Transform:SetPosition(newpos.x, -5, newpos.z)
    self.clouds_parent.Transform:SetRotation(- TheCamera.heading)

    self.cloud_fx.VFXEffect:ClearAllParticles(0)

    if not self.enabled then
        return
    end

    local c_down = TheCamera:GetPitchDownVec():Normalize()
    local c_right = TheCamera:GetRightVec():Normalize()

    local c_up = c_down:Cross(c_right):Normalize()

    local time = GetTime()
    local offset_y = 0
    local offset_x = 0

    for i = self.top_index, self.num do -- 根据遮挡关系执行
        local cloud = self.clouds[i]
        if cloud and cloud:IsValid() then
            offset_y = math.sin(time * 0.3 + self.clouds_move_offset[i]) * 0.25
            offset_x = math.sin(time * 0.3 + self.clouds_move_offset[i]) * 0.5
            local x, y, z = (cloud:GetPosition() + c_up * offset_y + c_right * offset_x):Get()
            self.cloud_fx.Transform:SetPosition(x, y, z)
            self.cloud_fx.VFXEffect:AddParticle(
                0,
                1e10,           -- lifetime
                0, 0, 0,         -- position
                0, 0, 0)          -- velocity
        end
    end
    for i = 1, self.top_index - 1 do
        local cloud = self.clouds[i]
        if cloud and cloud:IsValid() then
            offset_y = math.sin(time * 0.3 + self.clouds_move_offset[i]) * 0.25
            offset_x = math.sin(time * 0.3 + self.clouds_move_offset[i]) * 0.5
            local x, y, z = (cloud:GetPosition() + c_up * offset_y + c_right * offset_x):Get()
            self.cloud_fx.Transform:SetPosition(x, y, z)
            self.cloud_fx.VFXEffect:AddParticle(
                0,
                1e10,           -- lifetime
                0, 0, 0,         -- position
                0, 0, 0)          -- velocity
        end
    end
end
return CloudManager
