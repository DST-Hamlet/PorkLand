local function SetFires(x, y, z, rad)
    for i, v in ipairs(TheSim:FindEntities(x, 0, z, rad, nil, { "laser", "DECOR", "INLIMBO","FX" })) do
        if v.components.burnable then
            v.components.burnable:Ignite()
        end
    end
end

local function is_valid_target(inst, v)
    return not (v:HasTag("laser") or v:HasTag("laser_immune"))
end

local function OnAttacked(inst, v)
    if v.AnimState then
        SpawnPrefab("ancient_hulk_laserhit"):SetTarget(v)
    end
    if not v.components.health:IsDead() then
        if v.components.freezable ~= nil then
            if v.components.freezable:IsFrozen() then
                v.components.freezable:Unfreeze()
            elseif v.components.freezable.coldness > 0 then
                v.components.freezable:AddColdness(-2)
            end
        end
        if v.components.temperature ~= nil then
            local maxtemp = math.min(v.components.temperature:GetMax(), 10)
            local curtemp = v.components.temperature:GetCurrent()
            if maxtemp > curtemp then
                v.components.temperature:DoDelta(math.min(10, maxtemp - curtemp))
            end
        end
        if inst.owner and inst.owner:IsValid() then -- ancient_hulk_orb
            v.components.combat:SuggestTarget(inst.owner)
        end
    end
end

local function DoSectorAOE(inst, radius, start_angle, end_angle)
    local x, y, z = inst.Transform:GetWorldPosition()
    SetFires(x, y, z, radius)

    TheWorld:DoTaskInTime(0.3, function() SetFires(x, y, z, radius) end)

    local attacker = inst.owner or inst

    DoSectorAOEDamageAndDestroy(inst, {
        pos = Vector3(x, y, z),
        damage_radius = radius,
        start_angle = start_angle,
        end_angle = end_angle,
        onattackedfn = OnAttacked,
        validfn = is_valid_target,
        use_world_picker = true,
        attacker = attacker
    })
end

local function DoCircularAOE(inst, radius)
    return DoSectorAOE(inst, radius)
end

local function UpdateHit(inst)
    if inst:IsValid() then
        local oldflash = inst.flash
        inst.flash = math.max(0, inst.flash - .075)
        if inst.flash > 0 then
            local c = math.min(1, inst.flash)
            if inst.components.colouradder ~= nil then
                inst.components.colouradder:PushColour(inst, c, 0, 0, 0)
            else
                inst.AnimState:SetAddColour(c, 0, 0, 1)
            end
            if inst.flash < .3 and oldflash >= .3 then
                if inst.components.bloomer ~= nil then
                    inst.components.bloomer:PopBloom(inst)
                else
                    inst.AnimState:ClearBloomEffectHandle()
                end
            end
        else
            inst.flashtask:Cancel()
            inst.flashtask = nil
        end
    end
end

local function PowerGlow(inst)
    if inst.components.bloomer ~= nil then
        inst.components.bloomer:PushBloom(inst, "shaders/anim.ksh", -1)
    else
        inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
    end
    inst.flash = 1.7 -- .8 + math.random() * .4
    if not inst.components.updatelooper then
        inst:AddComponent("updatelooper")   
    end
    inst.components.updatelooper:AddOnUpdateFn(UpdateHit)
end

local function SpawnLaser(inst)
    local targetpos = inst.sg.statemem.targetpos
    if targetpos == nil then
        local angle =  inst.Transform:GetRotation() * DEGREES

        local DIST = 3
        local pt = Vector3(inst.Transform:GetWorldPosition())
        targetpos = pt + Vector3(math.cos(angle + PI / 2), 0, -math.sin(angle + PI / 2)) * DIST
    end
    local numsteps = 10
    local x, _, z = inst.Transform:GetWorldPosition()

    local xt = targetpos.x
    local yt = targetpos.y
    local zt = targetpos.z

    local dist =  math.sqrt(inst:GetDistanceSqToPoint(Vector3(xt, yt, zt))) -3
    local angle = (inst:GetAngleToPoint(xt, yt, zt) +90)* DEGREES
    local step = .75
    local ground = TheWorld.Map
    local targets, skiptoss = {}, {}
    local i = -1
    local noground = false
    local fx, delay, x1, z1

    while i < numsteps do
        i = i + 1
        dist = dist + step
        delay = math.max(0, i - 1)
        x1 = x + dist * math.sin(angle)
        z1 = z + dist * math.cos(angle)
        if not ground:IsPassableAtPoint(x1, 0, z1) then
            if i <= 0 then
                return
            end
            noground = true
        end
        fx = SpawnPrefab(i > 0 and "ancient_hulk_laser" or "ancient_hulk_laserempty")
        fx.caster = inst
        fx.Transform:SetPosition(x1, 0, z1)
        fx:Trigger(delay * FRAMES, targets, skiptoss)
        if noground then
            break
        end
    end

    local function delay_spawn(delay_offset)
        fx = SpawnPrefab("ancient_hulk_laser")
        fx.Transform:SetPosition(x1, 0, z1)
        fx:Trigger((delay + delay_offset) * FRAMES, targets, skiptoss)
    end

    delay_spawn(1)
    delay_spawn(2)
end

local function SetLightValue(inst, val)
    if inst.Light ~= nil then
        inst.Light:SetIntensity(.6 * val * val)
        inst.Light:SetRadius(5 * val)
        inst.Light:SetFalloff(3 * val)
    end
end

local function SetLightValueAndOverride(inst, val, override)
    if inst.Light ~= nil then
        inst.Light:SetIntensity(.6 * val * val)
        inst.Light:SetRadius(5 * val)
        inst.Light:SetFalloff(3 * val)
        inst.AnimState:SetLightOverride(override)
    end
end

local function SetLightValueWithFade(inst, val1, val2, time)
    inst.components.fader:StopAll()
    if val1 and val2 and time then
        inst.Light:Enable(true)
        inst.components.fader:Fade(val1, val2, time, function(v) inst.Light:SetIntensity(v) end)
    else
        inst.Light:Enable(false)
    end
end

local function SetLightColour(inst, val)
    if inst.Light ~= nil then
        inst.Light:SetColour(val, 0, 0)
    end
end

local function SpawnBarrier(inst, pt)
    local angle = 0
    local radius = 13
    local barrire_count = 32
    local offset

    for _ = 1, barrire_count do
        offset = Vector3(math.cos(angle), 0, math.sin(-angle)) * radius
        local spawn_point = pt + offset

        if TheWorld.Map:IsVisualGroundAtPoint(spawn_point.x, 0, spawn_point.z) then
            inst:DoTaskInTime(math.random() * 0.3, function()
                local rock = SpawnPrefab("rock_basalt")
                rock.AnimState:PlayAnimation("emerge")
                rock.AnimState:PushAnimation("full")
                inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/rock")
                rock.Transform:SetPosition(spawn_point.x, 0, spawn_point.z)
            end)
        end

        angle = angle + (PI * 2 / barrire_count)
    end
end

local function DropAncientRobots(inst)
    local parts = {
        "ancient_robot_claw",
        "ancient_robot_claw",
        "ancient_robot_leg",
        "ancient_robot_leg",
        "ancient_robot_ribs",
    }

    local x, y, z = inst.Transform:GetWorldPosition()
    local island_tag = TheWorld.Map:GetIslandTagAtPoint(x, y, z)

    for _, part in pairs(parts) do
        local part_prop = SpawnPrefab(part)
        part_prop.spawntask:Cancel()
        part_prop.spawntask = nil
        part_prop.spawned = true
        part_prop.sg:GoToState("idle_dormant")

        local target_pos = nil
        if island_tag ~= nil then
            target_pos = TheWorld.Map:FindPointByIslandTag(island_tag)
        end
        if target_pos == nil then
            target_pos = inst:GetPosition()
        end

        part_prop.Transform:SetPosition(target_pos.x, 0, target_pos.z)

        DoCircularAOE(part_prop, 5)
    end
end

local function ShootProjectile(inst, targetpos)
    local projectile = SpawnPrefab("ancient_hulk_orb")
    projectile.AnimState:PlayAnimation("spin_loop",true)

    local pt = inst.shotspawn:GetPosition()
    projectile.Transform:SetPosition(pt.x, pt.y, pt.z)
    projectile.components.throwable:Throw(targetpos, inst)
    projectile.owner = inst
end

return {
    SetFires = SetFires,
    DoDamage = DoCircularAOE,
    DoSectorAOE = DoSectorAOE,
    DoCircularAOE = DoCircularAOE,
    UpdateHit = UpdateHit,

    PowerGlow = PowerGlow,
    SpawnLaser = SpawnLaser,
    SetLightValue = SetLightValue,
    SetLightValueAndOverride = SetLightValueAndOverride,
    SetLightValueWithFade = SetLightValueWithFade,
    SetLightColour = SetLightColour,

    SpawnBarrier = SpawnBarrier,
    DropAncientRobots = DropAncientRobots,
    ShootProjectile = ShootProjectile,
}
