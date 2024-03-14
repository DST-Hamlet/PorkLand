local function FindCurrentTarget(inst)
    -- looks for a combat target, if none, sets target as home if range is too far

    local target =  FindClosestPlayerToInst(inst, 45, true)
    local DIST = 100
    local WANDERDIST = 60

    -- if the old target is dead, forget it
    if inst.target and not inst.target:IsValid() then
        inst.target = nil
    end

    -- if we had a valid target, keep it.
    if inst.target then
        target = inst.target
    end

    -- if target is on water or invalid forget it
    if target and ( not target:IsValid() or target.onwater) then -- TODO
        target = nil
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
    local angle = target and (target:GetAngleToPoint(pt.x, pt.y, pt.z) * DEGREES - PI) or math.random()*2*PI

    local offset, endangle = FindMoveablePosition(pt, angle, 6, 24, true)

    return endangle
end

local function FindSafeLocation(pt, angle)
    local offset = nil
    local range = 6

    while not offset do
        offset = FindMoveablePosition(pt, angle * DEGREES, range, 24, true)
        range = range + 1
    end

    return pt + offset
end

local function getNewBodyPosition(inst, bodies, target)
    local finalpt = nil

    -- get the new origin point
    if #bodies < 1 then
        -- this is the first body piece, start at the spawn point
        finalpt = inst:GetPosition()
    else
        -- this is a new body piece. try to put it out front of the last piece. 
        finalpt = FindSafeLocation( bodies[#bodies].exitpt:GetPosition(), bodies[#bodies].Transform:GetRotation())
    end

    return finalpt
end

local function DetermineAction(inst)
    -- tested each frame when head to see if the head should start moving
    local target = FindCurrentTarget(inst)

    local wasgazing = inst.wantstogaze
    inst.wantstogaze = nil

    local dist = nil

    local rando = math.random()
    if rando < 0.0001  then -- questionable
        inst.wantstotaunt = true
    end

    if target then
        dist = inst:GetDistanceSqToInst(target)
    end

    if dist and target.components.freezable and not target.components.freezable:IsFrozen( ) and dist > 8*8 and dist < 20*20 then     --and not head:HasTag("now_segmented")                        
        local gazechange = 0
        local health = inst.components.health:GetPercent()
        if health < 0.2 then
            gazechange = 0.75
        elseif health < 0.4 then
            gazechange = 0.5
        elseif health < 0.6 then
            gazechange = 0.3
        elseif health < 0.8 then
            gazechange = 0.1
        end

        if wasgazing or math.random() < gazechange then
           inst:PushEvent("stopmove")
           inst.wantstogaze = true
            if inst.sg:HasStateTag("underground") then
                inst:PushEvent("emerge")
            end
        end
    end

    if dist and dist < 6*6 and target ~= inst.home then
        if inst.sg:HasStateTag("underground") then
            inst:PushEvent("emerge")
        end
        inst:PushEvent("stopmove")
    elseif not inst.wantstogaze and not inst.wantstotaunt then

        local angle = nil
        inst.movecommited = true

        -- if no target, then direction is random.
       -- if target then       
            angle = FindDirectionToDive(inst,target)
       -- else
       --     angle = math.random()*2*PI
       -- end 

        if angle then
            inst.Transform:SetRotation(angle/DEGREES)

            inst.angle = angle

            if inst.sg:HasStateTag("underground") then
                local pos = Vector3(inst.Transform:GetWorldPosition())
                inst.components.multibody:SpawnBody(inst.angle,0,pos)
            else
                inst.wantstopremove = true        
            end
        else
            inst:PushEvent("backup")
        end
    end
end

local function recoverfrombadangle(inst)
    local finalpt = FindSafeLocation( inst:GetPosition(), inst.Transform:GetRotation())
    inst.Transform:SetPosition(finalpt.x, finalpt.y, finalpt.z)
end

return {
    FindMoveablePosition = FindMoveablePosition,
    FindDirectionToDive = FindDirectionToDive,
    FindValidPositionByFan = FindValidPositionByFan,
    FindSafeLocation = FindSafeLocation,
    getNewBodyPosition = getNewBodyPosition,
    FindCurrentTarget = FindCurrentTarget,
    DetermineAction = DetermineAction,
    RecoverFromBadAngle = recoverfrombadangle,
}
