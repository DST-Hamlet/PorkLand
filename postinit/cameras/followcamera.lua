local AddClassPostConstruct = AddClassPostConstruct
GLOBAL.setfenv(1, GLOBAL)

local FollowCamera = require("cameras/followcamera")

local _Apply = FollowCamera.Apply
function FollowCamera:Apply(...)
    if self.inside_interior then
        if self.pl_old_headingtarget == nil then
            self.pl_old_headingtarget = self.headingtarget
        end
        self.headingtarget = self.pl_interior_heading -- for playercontroller
        self.distance = 25 -- for hud cloud
        local pitch = self.pl_interior_pitch * DEGREES
        local heading = self.pl_interior_heading * DEGREES
        local distance = self.pl_interior_distance_override or self.pl_interior_distance
        local current_pos = self.pl_interior_currentpos
        if self.shake then
            local camera_shake_offset = self.shake:Update(0)
            if camera_shake_offset ~= nil then
                local right_offset = self:GetRightVec() * camera_shake_offset.x
                current_pos.x = current_pos.x + right_offset.x
                current_pos.y = current_pos.y + right_offset.y + camera_shake_offset.y
                current_pos.z = current_pos.z + right_offset.z
            else
                self.shake = nil
            end
        end
        local fov = self.pl_interior_fov
        local cos_pitch = math.cos(pitch)
        local cos_heading = math.cos(heading)
        local sin_heading = math.sin(heading)
        local dx = -cos_pitch * cos_heading
        local dy = -math.sin(pitch)
        local dz = -cos_pitch * sin_heading
        TheSim:SetCameraPos(
            current_pos.x - dx * distance,
            current_pos.y - dy * distance,
            current_pos.z - dz * distance
        )
        TheSim:SetCameraDir(dx, dy, dz)

        local right = (self.pl_interior_heading + 90) * DEGREES
        local rx = math.cos(right)
        local ry = 0
        local rz = math.sin(right)

        local ux = dy * rz - dz * ry
        local uy = dz * rx - dx * rz
        local uz = dx * ry - dy * rx

        TheSim:SetCameraUp(ux, uy, uz)
        TheSim:SetCameraFOV(fov)
        local listen_dist = -0.1 * distance
        TheSim:SetListener(
            dx * listen_dist + current_pos.x,
            dy * listen_dist + current_pos.y,
            dz * listen_dist + current_pos.z,
            dx, dy, dz,
            ux, uy, uz
        )
    else
        if self.pl_old_headingtarget ~= nil
            and not TheWorld.components.interiorspawner:IsInInteriorRegion(
                self.currentpos.x, self.currentpos.z) then
            self.headingtarget = self.pl_old_headingtarget
            --self.heading = self.headingtarget
            self.pl_old_headingtarget = nil
        end
        return _Apply(self, ...)
    end
end

local _ZoomOut = FollowCamera.ZoomOut
function FollowCamera:ZoomOut(step, ...)
    if self.inside_interior then
        return
    else
        return _ZoomOut(self, step, ...)
    end
end

AddClassPostConstruct("cameras/followcamera", function(self)
    -- Init Interior Variables
    self.pl_interior_pitch = 35
    self.pl_interior_heading = 0
    self.pl_interior_distance = 30
    self.pl_interior_currentpos = Vector3(0, 0, 0)
    self.pl_interior_fov = 35
    self.inside_interior = false -- controlled by player client component
end)

function ShakeAllCamerasInRoom(interiorID, mode, duration, speed, scale, source_or_point, max_distance)
    if not interiorID then
        return
    end

    if not TheWorld.components.interiorspawner then
        return
    end

    TheWorld.components.interiorspawner:ForEachPlayerInRoom(interiorID, function (player)
        player:ShakeCamera(mode, duration, speed, scale, source_or_point, max_distance)
    end)
end
