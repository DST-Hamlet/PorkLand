FollowPoint = Class(BehaviourNode, function(self, inst, pt, min_dist, max_dist, canrun, alwayseval, inlimbo_invalid)
    BehaviourNode._ctor(self, "FollowPoint")
    self.inst = inst
    self.pt = pt

    self.min_dist = min_dist or 0.1

    self.max_dist = max_dist or 0.25

    self.canrun = canrun ~= false
    self.alwayseval = alwayseval ~= false
    self.inlimbo_invalid = inlimbo_invalid
    self.currentpt = nil
    self.action = "STAND"
end)

local function _distsq(inst, pt)
    local x, y, z = inst.Transform:GetWorldPosition()
    local x1, y1, z1 = pt:Get()
    local dx = x1 - x
    local dy = y1 - y
    local dz = z1 - z
    --Note: Currently, this is 3D including y-component
    return dx * dx + dy * dy + dz * dz
end

function FollowPoint:Visit()
    --cached in case we need to use this multiple times
    local dist_sq, target_pos

    if self.status == READY then
        self.currentpt = FunctionOrValue(self.pt, self.inst)
        if self.currentpt ~= nil then
            dist_sq = _distsq(self.inst, self.currentpt)

            if dist_sq < self.max_dist * self.max_dist then
                self.status = SUCCESS
                return
            elseif dist_sq > self.max_dist * self.max_dist then
                self.status = RUNNING
                self.action = "APPROACH"
            else
                self.status = FAILED
            end
        else
            self.status = FAILED
        end
    end

    if self.status == RUNNING then
        self.currentpt = FunctionOrValue(self.pt, self.inst)
        if self.currentpt == nil then
            self.status = FAILED
            self.inst.components.locomotor:Stop()
            return
        end

        if self.action == "APPROACH" then
            if dist_sq == nil then
                dist_sq = _distsq(self.inst, self.currentpt)
            end

            if dist_sq < self.min_dist * self.min_dist then
                self.status = SUCCESS
                return
            end

            local max_dist = self.max_dist * .75

            if self.canrun and (dist_sq > max_dist * max_dist or self.inst.sg:HasStateTag("running")) then
                self.inst.components.locomotor:GoToPoint(self.currentpt, nil, true)
            else
                self.inst.components.locomotor:GoToPoint(self.currentpt)
            end
        end

        self:Sleep(0.1)
    end
end
