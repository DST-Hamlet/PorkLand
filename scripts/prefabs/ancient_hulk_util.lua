local function SetFires(x, y, z, rad)
    for i, v in ipairs(TheSim:FindEntities(x, 0, z, rad, nil, { "laser", "DECOR", "INLIMBO" })) do
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

local function DoCircularAOE(inst, radius)
    local function OnWorked(inst, v)
        local x, y, z = inst.Transform:GetWorldPosition()
        v:DoTaskInTime(0.3, function() SetFires(x, y, z, radius) end)
    end

    local x, y, z = inst.Transform:GetWorldPosition()
    SetFires(x, y, z, radius)
    DoCircularAOEDamageAndDestroy(inst, {damage_radius = radius, onattackedfn = OnAttacked, onworkedfn = OnWorked, validfn = is_valid_target})
end

local function DoSectorAOE(inst, radius, start_angle, end_angle)
    local function OnWorked(inst, v)
        local x, y, z = inst.Transform:GetWorldPosition()
        v:DoTaskInTime(0.3, function() SetFires(x, y, z, radius) end)
    end

    local x, y, z = inst.Transform:GetWorldPosition()
    SetFires(x, y, z, radius)
    DoSectorAOEDamageAndDestroy(inst, {damage_radius = radius, start_angle = start_angle, end_angle = end_angle, onattackedfn = OnAttacked, onworkedfn = OnWorked, validfn = is_valid_target})
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

local function powerglow(inst)

    if inst.components.bloomer ~= nil then
        inst.components.bloomer:PushBloom(inst, "shaders/anim.ksh", -1)
    else
        inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
    end
    inst.flash = 1.7 -- .8 + math.random() * .4
    inst.flashtask = inst:DoPeriodicTask(0, UpdateHit, nil, inst)
end

local function SpawnLaser(inst)
    assert(inst.sg.statemem.targetpos)
    local numsteps = 10
    local x, y, z = inst.Transform:GetWorldPosition()

    local xt = inst.sg.statemem.targetpos.x
    local yt = inst.sg.statemem.targetpos.y
    local zt = inst.sg.statemem.targetpos.z

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

-- TODO modify this
local function color(x,y,tiles,islands,value)
    tiles[y][x] = false
    islands[y][x] = value
end

local function check_validity(x,y,w,h,tiles,stack)
    if x >= 1 and y >= 1 and x <= w and y <= h and tiles[y][x] then
        stack[#stack+1] = {x=x,y=y}
    end
end

local function floodfill(x,y,w,h,tiles,islands,value)
    -- Queue q
    local q = {}
    q[#q+1] = {x=x,y=y}
    while #q > 0 do
        local el = q[#q]
        table.remove(q)
        local x1,y1 = el.x, el.y

        color(x1,y1,tiles,islands,value)

        check_validity(x1 + 1, y1,     w, h, tiles, q)
        check_validity(x1 - 1, y1,     w, h, tiles, q)
        check_validity(x1,     y1 + 1, w, h, tiles, q)
        check_validity(x1,     y1 - 1, w, h, tiles, q)
        check_validity(x1 - 1, y1 - 1, w, h, tiles, q)
        check_validity(x1 - 1, y1 + 1, w, h, tiles, q)
        check_validity(x1 + 1, y1 - 1, w, h, tiles, q)
        check_validity(x1 + 1, y1 + 1, w, h, tiles, q)
    end
end

local function dofloodfillfromcoord(x,y,w, h, tiles, islands)
    local index = 3
    local rescan = true
    local val = tiles[y][x]
    if val then
        floodfill(x,y,w,h,tiles,islands,index)
        index = index + 1
    end
end

local function GetDropLocations(inst)
    local island_nodes = {
        {
            ["START"] = true,
            ["Edge_of_the_unknown"] = true,
            ["painted_sands"] = true,
            ["plains" ]= true,
            ["rainforests" ]= true,
            ["rainforest_ruins" ]= true,
            ["plains_ruins"] = true,
            ["Edge_of_civilization"]= true,
            ["Deep_rainforest"] = true,
            ["Pigtopia"] = true,
            ["Pigtopia_capital"] = true,
            ["Deep_lost_ruins_gas"] = true,
            ["Edge_of_the_unknown_2"] = true,
            ["Lilypond_land"] = false,
            ["Lilypond_land_2"] = false,
            ["this_is_how_you_get_ants"] = true,
            ["Deep_rainforest_2"] = true,
            ["Lost_Ruins_1"] = true,
            ["Lost_Ruins_4"] = true,
        },
        {
            ["Deep_rainforest_3"] = true,
            ["Deep_rainforest_mandrake"] = true,
            ["Path_to_the_others"] = true,
            ["Other_edge_of_civilization"] = true,
            ["Other_pigtopia"] = true,
            ["Other_pigtopia_capital"] = true,
        },
        {
            ["Deep_lost_ruins4"] = true,
            ["lost_rainforest"] = true,
        },
        {
            ["pincale"] = true,
        },
        {
            ["Deep_wild_ruins4"] = true,
            ["wild_rainforest"] = true,
            ["wild_ancient_ruins"] = true,
        }
    }

    local nodes = TheWorld.topology.nodes
    -- TheWorld.topolog.nodes[1].tags[]

    local islands = {}
    local tiles = {}
    local map = TheWorld.Map
    local w,h = map:GetSize()

    for y = 1, h do
        tiles[y] = {}
        islands[y] = {}
        for x = 1, w do
            local tile = map:GetTile(x-1,y-1)

            tiles[y][x] = tile ~= WORLD_TILES.IMPASSABLE and tile ~= WORLD_TILES.LILYPOND
        end
    end
    local x,y,z = inst.Transform:GetWorldPosition()

    x = math.floor(x/4+ (w/2))
    z = math.floor(z/4 + (h/2))
    dofloodfillfromcoord(x,z,w, h, tiles, islands)

    local locations = {}
    for z=1,h do
        for x=1,w do
            if islands[z][x] then
                table.insert(locations,{x=x,z=z})
            end
        end
    end

    return locations
end

local function DropAncientRobots(inst)
    local locations = GetDropLocations(inst)
    local map = TheWorld.Map
    local w,h = map:GetSize()

    assert(#locations > 0,"Locations for ancient robots not found!")

    local parts = {
        "ancient_robot_claw",
        "ancient_robot_claw",
        "ancient_robot_leg",
        "ancient_robot_leg",
        "ancient_robot_ribs",
    }

    for i, part in ipairs(parts) do
        local partprop = SpawnPrefab(part)
        partprop.spawntask:Cancel()
        partprop.spawntask = nil
        partprop.spawned = true
        partprop:AddTag("dormant")
        partprop.sg:GoToState("idle_dormant")

        local idx = math.random(1,#locations)
        local loc = locations[idx]
        table.remove(locations, idx)

        partprop.Transform:SetPosition( (loc.x-(w/2)) *4 -4,0, (loc.z-(h/2)) *4-4 )

        DoCircularAOE(partprop, 5)
    end
end

local function ShootProjectile(inst, targetpos)
    local projectile = SpawnPrefab("ancient_hulk_orb")
    projectile.AnimState:PlayAnimation("spin_loop",true)

    local pt = inst.shotspawn:GetPosition()
    projectile.Transform:SetPosition(pt.x, pt.y, pt.z)
    projectile.components.pl_complexprojectile:SetHorizontalSpeed(60)
    projectile.components.pl_complexprojectile:SetGravity(-25)
    projectile.components.pl_complexprojectile:Launch(targetpos, inst, inst)
    projectile.owner = inst
end

local function ApplyDamageToEntities(inst,ent, targets, rad, hit)
    local x, y, z = inst.Transform:GetWorldPosition()
    if hit then
        targets = {}
    end
    if not rad then
        rad = 0
    end
    local v = ent
    if not targets[v] and v:IsValid() and not v:IsInLimbo() and not (v.components.health ~= nil and v.components.health:IsDead()) and not v:HasTag("laser_immune") then
        local vradius = 0
        if v.Physics then
            vradius = v.Physics:GetRadius()
        end

        local range = rad + vradius
        if hit or v:GetDistanceSqToPoint(Vector3(x, y, z)) < range * range then
            local isworkable = false
            if v.components.workable ~= nil then
                local work_action = v.components.workable:GetWorkAction()
                --V2C: nil action for campfires
                isworkable =
                    (work_action == nil and v:HasTag("campfire")) or
                        (   work_action == ACTIONS.CHOP or
                            work_action == ACTIONS.HAMMER or
                            work_action == ACTIONS.MINE or
                            work_action == ACTIONS.DIG or
                            work_action == ACTIONS.BLANK
                        )
            end
            if isworkable then
                targets[v] = true
                v:DoTaskInTime(0.6, function()
                    if v.components.workable then
                        v.components.workable:Destroy(inst)
                        local vx,vy,vz = v.Transform:GetWorldPosition()
                        v:DoTaskInTime(0.3, function() SetFires(vx,vy,vz,1) end)
                    end
                 end)
            elseif v.components.pickable ~= nil
                and v.components.pickable:CanBePicked()
                and not v:HasTag("intense") then
                targets[v] = true
                local num = v.components.pickable.numtoharvest or 1
                local product = v.components.pickable.product
                local x1, y1, z1 = v.Transform:GetWorldPosition()
                v.components.pickable:Pick(inst) -- only calling this to trigger callbacks on the object
                if product ~= nil and num > 0 then
                    for i = 1, num do
                        local loot = SpawnPrefab(product)
                        loot.Transform:SetPosition(x1, 0, z1)
                        targets[loot] = true
                    end
                end

            elseif v.components.health then
                targets[v] = true
                inst.components.combat:DoAttack(v)
                if v:IsValid() then
                    if not v.components.health or not v.components.health:IsDead() then
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
                    end
                end
            end
            if v:IsValid() and v.AnimState then
                SpawnPrefab("ancient_hulk_laserhit"):SetTarget(v)
            end
        end
    end
    return targets
end

return {
    SetFires = SetFires,
    DoDamage = DoCircularAOE,
    UpdateHit = UpdateHit,
    powerglow = powerglow,
    SpawnLaser = SpawnLaser,
    SetLightValue = SetLightValue,
    SetLightValueAndOverride = SetLightValueAndOverride,
    SetLightValueWithFade = SetLightValueWithFade,
    SetLightColour = SetLightColour,

    SpawnBarrier = SpawnBarrier,
    DropAncientRobots = DropAncientRobots,
    ShootProjectile = ShootProjectile,

    ApplyDamageToEntities = ApplyDamageToEntities,
    DoSectorAOE = DoSectorAOE,
}
