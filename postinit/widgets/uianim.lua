GLOBAL.setfenv(1, GLOBAL)

local UiAnim = require("components/uianim")

local ShakeDeltas =
{
    --------------------------------------------------------------------------
    --     4
    --  7     1
    -- 2   S   6
    --  5     3
    --     0
    --------------------------------------------------------------------------
    Vector3( 0,-1):GetNormalized(),
    Vector3( 1, 1):GetNormalized(),
    Vector3(-1, 0):GetNormalized(),
    Vector3( 1,-1):GetNormalized(),
    Vector3( 0, 1):GetNormalized(),
    Vector3(-1,-1):GetNormalized(),
    Vector3( 1, 0):GetNormalized(),
    Vector3(-1, 1):GetNormalized(),
}

function UiAnim:Shake(duration, speed, scale)
    if self.shaking then return end
    self.shake_pos_start = Vector3(self.inst.UITransform:GetLocalPosition())
    self.shake_scale_start = self.inst.UITransform:GetScale()

    self.shake_timer = 0
    self.shake_speed = speed
    self.shake_duration = duration
    self.shake_scale = scale
    self.shaking = true

    self.inst:StartWallUpdatingComponent(self)
end

local _OnWallUpdate = UiAnim.OnWallUpdate
function UiAnim:OnWallUpdate(dt, ...)
    if self.shaking then
        self.shake_duration = self.shake_duration - dt
        if self.shake_duration > 0 then
            self.shake_timer = self.shake_timer + dt
            if self.shake_timer > self.shake_speed then

                local scale = GetRandomWithVariance(1, 0.1)
                self:MoveTo(Vector3(self.inst.UITransform:GetLocalPosition()), (self.shake_pos_start + (ShakeDeltas[math.random(#ShakeDeltas)] * self.shake_scale)), self.shake_speed)
                self:ScaleTo(self.inst.UITransform:GetScale(), self.shake_scale_start * scale, self.shake_speed)
                self.shake_timer = 0
            end
        else
            --Stop shaking...
            self:MoveTo(Vector3(self.inst.UITransform:GetLocalPosition()), self.shake_pos_start, self.shake_speed)
            self:ScaleTo(self.inst.UITransform:GetScale(), self.shake_scale_start, self.shake_speed)
            self.shaking = false
        end
    end
    _OnWallUpdate(self, dt, ...)

    if not self.scale_t and not self.pos_t and not self.tint_t and not self.rot_t and not self.shaking then
        self.inst:StopWallUpdatingComponent(self)
    else
        self.inst:StartWallUpdatingComponent(self)
    end
end
