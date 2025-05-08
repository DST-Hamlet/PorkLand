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

    self.avoid_cant_tags = {"INLIMBO", "NOCLICK", "FX"}

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

            if self.accurate
                and (anglediff > 135 or anglediff < -135) 
                and self.inst:GetDistanceSqToPoint(pt) < self.currentspeed * self.currentspeed * 2 * 2 then -- 离目标太近且角度差过大时不转向
                
                anglediff = 0
            elseif self.avoid
                and (anglediff < 75 and anglediff > -75) 
                and self.inst:GetDistanceSqToPoint(pt) < self.currentspeed * self.currentspeed * 2 * 2 then -- 离目标太近时保持距离

                anglediff = -anglediff
            end

            if anglediff > 0 then
                self.turnmode = "right"
            else
                self.turnmode = "left"
            end

            if self.avoidother then -- 离其他物体太近时不会朝这些物体转向，以保持距离，比如和吸血蝙蝠阴影之间会通过这个机制避免重叠
                local x, _, z = self.inst.Transform:GetWorldPosition()
                local ents = TheSim:FindEntities(x, 0, z, 1.5, self.avoid_must_tags, self.avoid_cant_tags, self.avoid_oneof_tags)
                local angle = self.inst.Transform:GetRotation()
                for k, v in pairs(ents) do
                    local diff = self.inst:GetAngleToPoint(v.Transform:GetWorldPosition()) - angle
                    if diff > 180 then
                        diff = diff - 360
                    elseif diff < -180 then
                        diff = diff + 360
                    end

                    if diff > 0 and diff < 90 and self.turnmode == "right" then
                        anglediff = 0
                    elseif diff < 0 and diff > -90 and self.turnmode == "left" then
                        anglediff = 0
                    end
                end
            end

            turnspeed = turnspeed * dt

            anglediff = math.clamp(anglediff, - turnspeed, turnspeed)

            self.inst.Transform:SetRotation((angle + anglediff))
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
