local HEADDIST = 17
local HEADDIST_TARGET = 15
local BODY_DIST_TOLLERANCE = 2

local TAILDIST = 13

local LEGDIST = 6
local LEG_WALKDIST = 4
local LEG_WALKDIST_BIG = 6
local LAND_PROX = 15 --7
local DISTANCE_FROM_WATER_OR_IMPASSABLE = 8

local FIND_TARGET_DIST = 40

local function TryFindTrackTarget(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    local target = FindClosestPlayerInRange(x, y, z, 100, true)
    return target
end

local function CheckKeepTrackTarget(inst, target)
    if not target or not target:IsValid() then
        return false
    end

    if inst:IsNear(target, 140) then
        return true
    end
end

local function TryFindLand(inst)
    local angle = inst.Transform:GetRotation()
    local front_point = inst:GetPosition() + Vector3(math.cos(angle * DEGREES), 0, -math.sin(angle * DEGREES)):Normalize() * 40
    if not TheWorld.Map:IsImpassableAtPoint(front_point.x, 0, front_point.z) then
        return front_point
    end

    local start_angle = math.random() * 360
    local landpoints = {}
    local steps = 16
    for i = 1, steps do
        local testangle = start_angle + 360 / steps
        local test_point = inst:GetPosition() + Vector3(math.cos(testangle * DEGREES), 0, -math.sin(testangle * DEGREES)):Normalize() * 40
        if not TheWorld.Map:IsImpassableAtPoint(test_point.x, 0, test_point.z) then
            return test_point
        end
    end
end

local function FlyBehaviorUpdate(inst, dt, currentdata, braindata)
    local x, y, z = inst.Transform:GetWorldPosition()

    local isinimpassable = TheWorld.Map:IsImpassableAtPoint(x, 0, z)

    if not CheckKeepTrackTarget(inst, braindata.tracktarget) then
        local target = TryFindTrackTarget(inst)
        braindata.tracktarget = target
    end

    if not isinimpassable then
        braindata.lastlandpos = Vector3(x, 0, z)
    end

    if CheckKeepTrackTarget(inst, braindata.tracktarget) then
        local targetpt = braindata.tracktarget:GetPosition()
        inst.components.glidemotor:SetTargetPos(targetpt)

        local angle = inst.Transform:GetRotation()
        local anglediff = inst:GetAngleToPoint(targetpt.x,targetpt.y,targetpt.z) - angle
        if anglediff > 180 then
            anglediff = anglediff - 360
        elseif anglediff < -180 then
            anglediff = anglediff + 360
        end
        if not inst:IsNear(braindata.tracktarget, 100)
            and math.abs(anglediff) > 3
            and not inst.components.timer:TimerExists("turn_cd") then

            currentdata.isturning = true
            inst:PushEvent("turn")
        elseif not inst:IsNear(braindata.tracktarget, 60)
            and math.abs(anglediff) > 3
            and not inst.components.timer:TimerExists("turn_cd")
            and currentdata.isturning then

            inst:PushEvent("turn")
        elseif inst:IsNear(braindata.tracktarget, 5) then
            inst.components.giantbraincontroller:GoToBehavior("land")
            return
        elseif inst:IsNear(braindata.tracktarget, 60) then
            currentdata.isturning = false
        end
    elseif isinimpassable then
        local landpos = TryFindLand(inst)
        inst.components.glidemotor:SetTargetPos(landpos or braindata.lastlandpos or nil)
    else
        inst.components.glidemotor:SetTargetPos(nil)
    end

    inst:PushEvent("fly")
end

local function TryFindHeadTarget(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    local x, y, z = inst.Transform:GetWorldPosition()

    local head = inst.bodyparts.head
    if head then
        x, y, z = inst.entity:LocalToWorldSpace(head.offset:Get())
    end

    local target = FindClosestPlayerInRange(x, y, z, FIND_TARGET_DIST, true)
    return target
end

local function CheckKeepHeadTarget(inst, target)
    if not target or not target:IsValid() then
        return false
    end

    local x, y, z = inst.Transform:GetWorldPosition()

    local head = inst.bodyparts.head
    if head then
        x, y, z = inst.entity:LocalToWorldSpace(head.offset:Get())
    end

    if target:GetDistanceSqToPoint(x, y, z) < FIND_TARGET_DIST * 2 * FIND_TARGET_DIST * 2 then
        return true
    end
end

local function LandBehaviorEnter(inst, dt, currentdata, braindata)
    inst:PushEvent("land")
    inst:SetLandSpeed()
    inst.components.glidemotor:EnableMove(false)
end

local function UpdateHeadPos(inst, pos, dt)
    local head = inst.bodyparts.head
    if head and not head.sg:HasStateTag("busy") then
        local tx, ty ,tz = inst.entity:LocalToWorldSpace(head.offset:Get())
        local targetpt = Vector3(tx, ty ,tz)
        head:FacePoint(targetpt:Get())
        local offset = targetpt - head:GetPosition()
        local speed = math.sqrt(offset.x * offset.x + offset.z * offset.z)
        if speed > 0.5 then
            local speed = math.sqrt(offset.x * offset.x + offset.z * offset.z)
            speed = math.min(speed, TUNING.ROC_SPEED_LAND + 2)
            head.Physics:SetMotorVel(speed, 0, 0)
        else
            head.Physics:SetMotorVel(0, 0, 0)
        end
    end
end

local function UpdateTailPos(inst, pos, dt)
    local tail = inst.bodyparts.tail
    if tail and not tail.sg:HasStateTag("busy") then
        local tx, ty ,tz = inst.entity:LocalToWorldSpace(tail.offset:Get())
        local targetpt = Vector3(tx, ty ,tz)
        tail:FacePoint(targetpt:Get())
        local offset = targetpt - tail:GetPosition()
        local speed = math.sqrt(offset.x * offset.x + offset.z * offset.z)
        if speed > 0.5 then
            local speed = math.sqrt(offset.x * offset.x + offset.z * offset.z)
            speed = math.min(speed, TUNING.ROC_SPEED_LAND + 2)
            tail.Physics:SetMotorVel(speed, 0, 0)
        else
            tail.Physics:SetMotorVel(0, 0, 0)
        end
    end
end

local function LandBehaviorUpdate(inst, dt, currentdata, braindata)
    local head = inst.bodyparts.head
    local target = braindata.tracktarget


    if not CheckKeepHeadTarget(inst, target) then
        target = TryFindHeadTarget(inst)
        braindata.tracktarget = target
    end

    if CheckKeepHeadTarget(inst, target) and head and not head.sg:HasStateTag("busy") then
        local hx, hy, hz = inst.entity:LocalToWorldSpace(head.offset:Get())
        local targetpt = target:GetPosition()

        if target:GetDistanceSqToPoint(hx, hy, hz) > 5 * 5 then
            inst.components.glidemotor:EnableMove(true)
            inst.components.glidemotor:SetTargetPos(targetpt)
        else
            inst.components.glidemotor:EnableMove(false)
        end
    else
        inst.components.glidemotor:EnableMove(false)
        inst.components.glidemotor:SetTargetPos(nil)
    end


    UpdateHeadPos(inst, nil, dt)
    UpdateTailPos(inst, nil, dt)
end

return
{
    FlyBehaviorUpdate = FlyBehaviorUpdate,
    LandBehaviorEnter = LandBehaviorEnter,
    LandBehaviorUpdate = LandBehaviorUpdate,
}
