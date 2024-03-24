local GAZE_DIST_MIN = 8
local GAZE_DIST_MAX = 20
local PUGALISK_MOVE_DIST = 6 -- The distance between two pugalisk_body
local PUGALISK_TAUNT_CHANCE = 0.0001

local function FindCurrentTarget(inst)
    -- looks for a combat target, if none, sets target as home if range is too far

    local target =  FindClosestPlayerToInst(inst, 45, true)
    local DIST = 100
    local WANDERDIST = 60

    -- if the old target is dead, forget it
    if inst.target and (not inst.target:IsValid() or inst.target:HasTag("playerghost"))then
        inst.target = nil
    end

    -- if we had a valid target, keep it.
    if inst.target then
        target = inst.target
    end

    -- if target is on water or invalid forget it
    if target then
        local x, y, z = target.Transform:GetWorldPosition()
        if not target:IsValid() or not TheWorld.Map:IsVisualGroundAtPoint(x, y, z) then
            target = nil
        end
    end

    if target and inst.home and target:GetDistanceSqToInst(inst.home) < DIST*DIST then
        -- if we are close to home and there is a target, target it.        
        inst.target = target
        inst.components.combat:SetTarget(target)
    elseif inst.home and inst:GetDistanceSqToInst(inst.home) > WANDERDIST * WANDERDIST then
        -- if no target but too far away from home, target home to get close to it.
        inst.target = nil
        inst.components.combat:SetTarget(nil)
        target = inst.home
    else
        if target and not inst.home then
            inst.target = target
            inst.components.combat:SetTarget(target)
        else
            -- We don't have a target. and we are close to home, were just gonna wander.
            target = nil
            inst.target = nil
            inst.components.combat:SetTarget(target)
        end
    end

    return target
end

local function FindMoveablePosition(position, start_angle, radius, attempts, check_los)
    local function CustomCheckFn(point)
        local ents = TheSim:FindEntities(point.x, point.y, point.z, 2, nil,nil,{"pugalisk","pugalisk_avoids"})
        if next(ents) then
            return false
        end

        ents = TheSim:FindEntities(point.x, point.y, point.z, 6, {"pugalisk_avoids"})
        if next(ents) then
            return false
        end
        return true
    end

    return FindWalkableOffset(position, start_angle, radius, attempts, check_los, true, CustomCheckFn, false, false)
end

local function FindDirectionToDive(inst, target)
    local pt = inst:GetPosition()
    local angle = target and (target:GetAngleToPoint(pt.x, pt.y, pt.z) * DEGREES - PI) or math.random() * 2 * PI

    local offset, endangle = FindMoveablePosition(pt, angle, 6, 10, true)

    return endangle
end

local function FindSafeLocation(pt, angle)
    local offset = nil
    local range = 6

    while not offset do
        offset = FindMoveablePosition(pt, angle * DEGREES, range, 10, true)
        range = range + 1
    end

    return pt + offset
end

local function DetermineAction(inst)
    -- tested each frame when head to see if the head should start moving
    local target = FindCurrentTarget(inst)

    local wasgazing = inst.wantstogaze
    inst.wantstogaze = nil

    if math.random() < PUGALISK_TAUNT_CHANCE then
        inst.wantstotaunt = true
    end

    local dist = target and inst:GetDistanceSqToInst(target)

    if dist and target.components.freezable and not target.components.freezable:IsFrozen()
        and dist > GAZE_DIST_MIN * GAZE_DIST_MIN and dist < GAZE_DIST_MAX * GAZE_DIST_MAX then
        local gaze_chance = 0
        local health_percent = inst.components.health:GetPercent()
        if health_percent < 0.2 then
            gaze_chance = 0.75
        elseif health_percent < 0.4 then
            gaze_chance = 0.5
        elseif health_percent < 0.6 then
            gaze_chance = 0.3
        elseif health_percent < 0.8 then
            gaze_chance = 0.1
        end

        if wasgazing or math.random() < gaze_chance then
           inst:PushEvent("stopmove")
           inst.wantstogaze = true
            if inst.sg:HasStateTag("underground") then
                inst:PushEvent("emerge")
            end
        end
    end

    -- If we are close enough to combat target, stop moving and get out from ground
    if dist and dist < PUGALISK_MOVE_DIST * PUGALISK_MOVE_DIST and target ~= inst.home then
        if inst.sg:HasStateTag("underground") then
            inst:PushEvent("emerge")
        end
        inst:PushEvent("stopmove")
    -- If we are more than 6 unit distance away, keep moving to target
    elseif not inst.wantstogaze then
        local angle = FindDirectionToDive(inst, target)
        inst.movecommited = true

        if angle then
            inst.Transform:SetRotation(angle/DEGREES)

            inst.angle = angle

            if inst.sg:HasStateTag("underground") then
                local pos = Vector3(inst.Transform:GetWorldPosition())
                inst.components.multibody:SpawnBody(inst.angle, 0, pos)
            else
                inst.wantstopremove = true
            end
        else
            inst:PushEvent("backup")
        end
    end
end

local function RecoverFromBadAngle(inst)
    local finalpt = FindSafeLocation( inst:GetPosition(), inst.Transform:GetRotation())
    inst.Transform:SetPosition(finalpt.x, finalpt.y, finalpt.z)
end

return {
    FindSafeLocation = FindSafeLocation,
    FindCurrentTarget = FindCurrentTarget,
    DetermineAction = DetermineAction,
    RecoverFromBadAngle = RecoverFromBadAngle,
}
