local GlideMotor = Class(function(self, inst)
    self.inst = inst
    self.runspeed = 10
    self.runspeed_turnfast = 6.667
    self.turnspeed = 10 -- 旋转角速度
    self.turnspeed_fast = 60

    self.stopped = false

    self.targetpt = nil

    self.currentspeed = 0
    self.speedtarget = self.runspeed

    self.startturnfast = 0
    self.stopturnfast = 0

    self.turnfastfadein = 0.3
    self.turnfastfadeout = 0.5

    self.turnmode = "left"

    inst:StartUpdatingComponent(self)
end)

function GlideMotor:SetTargetPos(pt)
    self.targetpt = pt
end

function GlideMotor:TurnFast(duration)
    self.startturnfast = GetTime()
    self.stopturnfast = GetTime() + duration
end

function GlideMotor:EnableMove(enable)
    self.stopped = not enable
end

function GlideMotor:OnUpdate(dt)
    if not self.stopped then
        if self.targetpt then
            local turnspeed = self.turnspeed
            if self.stopturnfast > GetTime() then
                if self.stopturnfast - GetTime() <= self.turnfastfadeout then
                    turnspeed = self.turnspeed + (self.turnspeed_fast - self.turnspeed) * math.min(self.turnfastfadeout, self.stopturnfast - GetTime()) / self.turnfastfadeout
                else
                    turnspeed = self.turnspeed + (self.turnspeed_fast - self.turnspeed) * math.min(self.turnfastfadein, GetTime() - self.startturnfast) / self.turnfastfadein
                end
            end

            local pt = self.targetpt
            local angle = self.inst.Transform:GetRotation()
            local anglediff = self.inst:GetAngleToPoint(pt.x,pt.y,pt.z) - angle
            if anglediff > 180 then
                anglediff = anglediff - 360
            elseif anglediff < -180 then
                anglediff = anglediff + 360
            end

            turnspeed = turnspeed * dt

            anglediff = math.clamp(anglediff, - turnspeed, turnspeed)

            self.inst.Transform:SetRotation((angle + anglediff))

            if anglediff > 0 then
                self.turnmode = "right"
            else
                self.turnmode = "left"
            end
        end
        if self.stopturnfast > GetTime() then
            self.speedtarget = self.runspeed_turnfast
        else
            self.speedtarget = self.runspeed
        end
        self.currentspeed = self.currentspeed + (self.speedtarget - self.currentspeed) * dt
        self.inst.Physics:SetMotorVel(self.currentspeed, 0, 0)
    else
        self.inst.Physics:SetMotorVel(0, 0, 0)
    end
end

return GlideMotor
