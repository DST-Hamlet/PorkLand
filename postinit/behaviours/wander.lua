GLOBAL.setfenv(1, GLOBAL)

require("behaviours/wander")
function Wander:PickNewDirection()

    self.far_from_home = self:IsFarFromHome()
    self.walking = true

    if self.far_from_home then
        self.inst.components.locomotor:GoToPoint(self:GetHomePos())
    else
        local start_position = Point(self.inst.Transform:GetWorldPosition())
        local angle = (self.getdirectionFn and self.getdirectionFn(self.inst))

        if not angle then
            angle = math.random() * 2 * PI
            if self.setdirectionFn then
                self.setdirectionFn(self.inst, angle)
            end
        end

        local radius = FunctionOrValue(self.wander_dist, self.inst)
        local attempts = self.offest_attempts
        local find_offset_fn = self.inst.components.amphibiouscreature ~= nil and FindAmphibiousOffset
            or self.inst.components.locomotor:IsAquatic() and FindSwimmableOffset or FindWalkableOffset
        local offset, check_angle = find_offset_fn(start_position, angle, radius, attempts, true, false, self.checkpointFn) -- try to avoid walls
        if not check_angle then
            offset, check_angle = find_offset_fn(start_position, angle, radius, attempts, true, true, self.checkpointFn) -- if we can't avoid walls
        end
        if check_angle then
            angle = check_angle
            if self.setdirectionFn then
                self.setdirectionFn(self.inst, angle)
            end
        end

        local run = FunctionOrValue(self.should_run, self.inst)

        if offset then
            self.inst.components.locomotor:GoToPoint(self.inst:GetPosition() + offset, nil, run)
        else
            self.inst.components.locomotor:WalkInDirection(angle/DEGREES, run)
        end
    end

    self:Wait(self.times.minwalktime +  math.random()*self.times.randwalktime)
end
