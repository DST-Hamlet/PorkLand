local PugaliskUtil = require("prefabs/pugalisk_util")

local assets =
{
    Asset("ANIM", "anim/python.zip"),
    Asset("ANIM", "anim/python_test.zip"),
    Asset("ANIM", "anim/python_segment_broken02_build.zip"),
    Asset("ANIM", "anim/python_segment_broken_build.zip"),
    Asset("ANIM", "anim/python_segment_build.zip"),
    Asset("ANIM", "anim/python_segment_tail02_build.zip"),
    Asset("ANIM", "anim/python_segment_tail_build.zip"),
    Asset("ANIM", "anim/python_dirt_segment_in_fast_pst.zip"),
}

local prefabs =
{
    "bluegem",
    "boneshard",
    "gaze_beam",
    "monstermeat",
    "pugalisk_body",
    "pugalisk_skull",
    "redgem",
    "snake_bone",
    "snake_scales_fx",
    "spoiled_fish",
}

SetSharedLootTable("pugalisk",
{
    {"monstermeat",             1.00},
    {"monstermeat",             1.00},
    {"monstermeat",             1.00},
})

SetSharedLootTable("pugalisk_segment",
{
    {"snake_bone",             1.000},
    {"boneshard",              0.600},
    {"monstermeat",            0.200},
    {"spoiled_fish",           0.050},
    {"redgem",                 0.005},
    {"bluegem",                0.005},
})

local SHAKE_DIST = 40

local function HealthRedirect(inst, amount, overtime, cause, ignore_invincible, afflicter, ignore_absorb)
    local originalinst = inst

    if inst.startpt then
        inst = inst.startpt
    end

    if amount < 0 and ((inst.components.segmented and inst.components.segmented.vulnerablesegments == 0) or inst:HasTag("tail") or inst:HasTag("head")) then
        if afflicter and afflicter:HasTag("player") then
            afflicter.components.talker:Say(GetString(afflicter.prefab, "ANNOUNCE_PUGALISK_INVULNERABLE"))
        end

        inst.SoundEmitter:PlaySound("dontstarve/common/destroy_metal", nil, 0.25)
        inst.SoundEmitter:PlaySound("dontstarve/wilson/hit_metal")

        return true
    elseif amount and inst.host then
        local fx = SpawnPrefab("snake_scales_fx")
        fx.Transform:SetScale(1.5, 1.5, 1.5)
        local x, y, z = originalinst.Transform:GetWorldPosition()
        fx.Transform:SetPosition(x, y + 2 + math.random() * 2, z)

        inst:PushEvent("dohitanim")
        if inst.host.components.health and not inst.host.components.health:IsDead() then
            inst.host.components.health:DoDelta(amount, overtime, "vulnerable_segment", ignore_invincible, afflicter, true)
            inst.host:PushEvent("attacked", {vulnerable_segment = true})
        end

        return true
    end
end

local function HealthRedirect_Head(inst, amount, overtime, cause, ignore_invincible, afflicter, ignore_absorb)
    if cause == "vulnerable_segment" then
        return false
    elseif amount < 0 then
        if afflicter and afflicter:HasTag("player") then
            afflicter.components.talker:Say(GetString(afflicter.prefab, "ANNOUNCE_PUGALISK_INVULNERABLE"))
        end

        inst.SoundEmitter:PlaySound("dontstarve/common/destroy_metal", nil, 0.25)
        inst.SoundEmitter:PlaySound("dontstarve/wilson/hit_metal")
        return true
    end
end

local function OnHit(inst, attacker)
    local host = inst.host or inst

    if attacker and (not inst.target or inst.target:HasTag("player")) then
        host.target = attacker
        host.components.combat:SetTarget(attacker)
    end

end

-----[[Pugalisk Segment]]-----

local STATES = {
    IDLE = 1,
    MOVING = 2,
    DEAD = 3,
}

local SEG_PARTS = {
    HEAD = 1,
    TAIL = 2,
    SGEMENT = 3,
}

local function updatesegmentart(inst, percentdist)
    local anim = "test_segment"

    if inst._segpart:value() == SEG_PARTS.HEAD then
        anim = "test_head"
    end

    if percentdist then
        inst.AnimState:SetPercent(anim, percentdist)
    end
end

local function OnRemove_Segment(inst)
    local segbody = inst._body:value()
    if segbody and segbody._state and segbody._state:value() == STATES.DEAD then
        inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/pugalisk/explode")
    end
    if segbody and segbody:IsValid() and segbody.segs then
        for i, testseg in ipairs(segbody.segs) do
            if inst == testseg then
                table.remove(segbody.segs, i)
            end
        end
    end
end

local function OnBodyDirty_Segment(inst, data)
    local segbody = inst._body:value()
    if segbody and segbody:IsValid() then
        table.insert(segbody.segs, inst)
        inst.components.cursorredirect.redirects = segbody.redirects
    end
    inst:ListenForEvent("onremove", OnRemove_Segment)
end

local function segmentfn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    inst.entity:AddPhysics()

    inst.AnimState:SetBank("giant_snake")
    inst.AnimState:SetBuild("python_test")
    inst.AnimState:PlayAnimation("test_segment")
    inst.AnimState:Hide("broken01")
    inst.AnimState:Hide("broken02")
    inst.AnimState:SetFinalOffset(-10)

    inst.Transform:SetEightFaced()
    inst.Transform:SetScale(1.5, 1.5, 1.5)

    inst:AddTag("pugalisk")
    inst:AddTag("groundpoundimmune")
    inst:AddTag("noteleport")

    inst:AddComponent("cursorredirect")

    inst._segtime = net_float(inst.GUID, "_segtime")
    -- Head, tail or segment
    inst._segpart = net_ushortint(inst.GUID, "_segpart")
    inst._body = net_entity(inst.GUID, "_body", "bodydirty")

    inst:ListenForEvent("bodydirty", OnBodyDirty_Segment)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.persists = false

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetChanceLootTable("pugalisk_segment")
    inst.components.lootdropper.lootdropangle = 360
    inst.components.lootdropper.speed = 3 + math.random() * 3

    return inst
end

local function segment_deathfn(segment)
    segment.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/pugalisk/explode")
    segment.components.lootdropper:DropLoot()

    local x, y, z = segment.Transform:GetWorldPosition()
    local fx = SpawnPrefab("snake_scales_fx")
    fx.Transform:SetScale(1.5, 1.5, 1.5)
    fx.Transform:SetPosition(x, y + 2 + math.random() * 2, z)
end

-----[[Pugalisk Body]]-----

local function OnBodyComplete_Body(inst, data)
    if not inst.exitpt then
        return
    end

    inst.exitpt.AnimState:SetBank("giant_snake")
    inst.exitpt.AnimState:SetBuild("python_test")
    inst.exitpt.AnimState:PlayAnimation("dirt_static")

    ShakeAllCameras(CAMERASHAKE.VERTICAL, 0.5, 0.03, 2, inst, SHAKE_DIST)

    inst.exitpt.Physics:SetActive(true)
    inst.exitpt.components.groundpounder:GroundPound()

    inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/pugalisk/emerge", "emerge")
    inst.SoundEmitter:SetParameter("emerge", "start", math.random())

    if inst.host then
        inst.host:PushEvent("bodycomplete", {pos = Vector3(inst.exitpt.Transform:GetWorldPosition()), angle = inst.angle})
    end
end

local function OnBodyFinished_Body(inst, data)
    if inst.host then
        inst.host:PushEvent("bodyfinished", {body = inst})
    end
    for k, v in pairs(inst.components.segmented.redirects) do
        v:Remove()
    end
    inst:Remove()
end

local function ClientPerdictPosition(inst, dt, should_update_position)
    if inst._state:value() == STATES.DEAD then
        return
    end

    dt = dt or FRAMES
    local hit = inst._hit:value()

    for _, seg in pairs(inst.segs) do
        if seg._segtime and inst._speed and inst._speed:value() > 0 and should_update_position then
            local animation_percent = math.clamp(seg._segtime:value() / 1, 0, 1)

            if inst._start_point and inst._end_point then
                local end_point = Vector3(inst._end_point.x:value(), 0, inst._end_point.z:value())
                local start_point = Vector3(inst._start_point.x:value(), 0, inst._start_point.z:value())
                local displacement = end_point - start_point
                local target_position = (displacement * animation_percent) + start_point
                seg.Physics:Teleport(target_position.x, 0, target_position.z)

                local animation_delay = (dt * inst._speed:value())/1
                updatesegmentart(seg, animation_percent - animation_delay)
                if hit > 0 then
                    local s = 1.5
                    s = Remap(hit, 1, 0, 1, 1.5)
                    seg.Transform:SetScale(s,s,s)
                end
            end
        end
    end

    if should_update_position then
        inst.SoundEmitter:SetParameter("speed", "intensity", inst._speed:value())
    end

    local ease = inst._speed:value()
    if inst._state:value() == STATES.MOVING then
        ease = math.min(ease + dt,1)
    else
        ease = math.max(ease - dt,0)
    end

    inst._speed:set_local(ease)
    inst._hit:set_local(hit - dt * 5)

    for _, seg in pairs(inst.segs) do
        seg._segtime:set_local(seg._segtime:value() + (dt * inst._speed:value()))
    end
end

local function bodyfn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("giant_snake")
    inst.AnimState:SetBuild("python_test")
    inst.AnimState:PlayAnimation("dirt_static")
    inst.AnimState:Hide("broken01")
    inst.AnimState:Hide("broken02")
    inst.AnimState:SetFinalOffset(0)

    inst.Transform:SetSixFaced()
    inst.Transform:SetScale(1.5, 1.5, 1.5)

    MakeObstaclePhysics(inst, 1)

    inst:AddTag("epic")
    inst:AddTag("monster")
    inst:AddTag("hostile")
    inst:AddTag("pugalisk")
    inst:AddTag("scarytoprey")
    inst:AddTag("largecreature")
    inst:AddTag("groundpoundimmune")
    inst:AddTag("noteleport")

    inst.invulnerable = true
    inst.name = STRINGS.NAMES.PUGALISK
    inst.redirects = {}
    inst.segs = {}

    -- The speed of the segment
    inst._speed = net_float(inst.GUID, "_speed", "speeddirty")
    -- Idle, moving or dead
    inst._state = net_float(inst.GUID, "_state")

    -- The point it left ground
    inst._start_point = {
        x = net_float(inst.GUID, "_start_point.x"),
        z = net_float(inst.GUID, "_start_point.z"),
    }
    -- The point it will enter ground
    inst._end_point = {
        x = net_float(inst.GUID, "_end_point.x"),
        z = net_float(inst.GUID, "_end_point.z"),
    }

    inst._hit = net_float(inst.GUID, "_hit")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        inst.oldpos = inst:GetPosition()
        inst:DoPeriodicTask(FRAMES, function(inst)
            if inst.oldpos == inst:GetPosition() then
                ClientPerdictPosition(inst, FRAMES, true)
            else
                ClientPerdictPosition(inst, FRAMES, false)
            end
            inst.oldpos = inst:GetPosition()
        end)
        return inst
    end

    inst.persists = false

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(9999)
    inst.components.health.destroytime = 5
    inst.components.health.redirect = HealthRedirect
    inst.components.health.canheal = false

    inst:AddComponent("combat")
    inst.components.combat:SetDefaultDamage(TUNING.PUGALISK_DAMAGE)
    inst.components.combat.playerdamagepercent = 0.75
    inst.components.combat.hiteffectsymbol = "hit_target"
    inst.components.combat.onhitfn = OnHit

    inst:AddComponent("lootdropper")

    inst:AddComponent("inspectable")
    inst.components.inspectable.nameoverride = "pugalisk"

    inst:AddComponent("knownlocations")

    inst:AddComponent("groundpounder")
    inst.components.groundpounder.destroyer = true
    inst.components.groundpounder.damageRings = 2
    inst.components.groundpounder.destructionRings = 1
    inst.components.groundpounder.numRings = 2
    inst.components.groundpounder.groundpounddamagemult = 30/TUNING.PUGALISK_DAMAGE
    inst.components.groundpounder.groundpoundfx = "groundpound_nosound_fx"
    table.insert(inst.components.groundpounder.noTags, "pugalisk")

    inst:AddComponent("segmented")
    inst.components.segmented.segment_deathfn = segment_deathfn

    inst:ListenForEvent("bodycomplete", OnBodyComplete_Body)
    inst:ListenForEvent("bodyfinished", OnBodyFinished_Body)

    inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/pugalisk/movement_LP", "speed")
    inst.SoundEmitter:SetParameter("speed", "intensity", 0)

    return inst
end

-----[[Pugalisk Tail]]-----

local RETARGET_NO_TAGS = {"FX", "NOCLICK", "INLIMBO", "playerghost", "notarget", "pugalisk"}
local RETARGET_ONE_OF_TASG = {"character", "animal", "monster"}
local function RetargetTailFn(inst)
    local targetDist = TUNING.PUGALISK_TAIL_TARGET_DIST

    return FindEntity(inst, targetDist, function(ent)
        return inst.components.combat:CanTarget(ent)
    end, nil, RETARGET_NO_TAGS, RETARGET_ONE_OF_TASG)
end

local tail_brain = require "brains/pugalisk_tailbrain"

local function tailfn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("giant_snake")
    inst.AnimState:SetBuild("python_test")
    inst.AnimState:PlayAnimation("tail_idle_loop", true)
    inst.AnimState:Hide("broken01")
    inst.AnimState:Hide("broken02")
    inst.AnimState:SetFinalOffset(0)

    inst.Transform:SetSixFaced()
    inst.Transform:SetScale(1.5, 1.5, 1.5)

    MakeObstaclePhysics(inst, 1)

    inst.invulnerable = true
    inst.name = STRINGS.NAMES.PUGALISK

    inst:AddTag("tail")
    inst:AddTag("epic")
    inst:AddTag("monster")
    inst:AddTag("hostile")
    inst:AddTag("pugalisk")
    inst:AddTag("scarytoprey")
    inst:AddTag("largecreature")
    inst:AddTag("groundpoundimmune")
    inst:AddTag("noteleport")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.persists = false

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(9999)
    inst.components.health.destroytime = 5
    inst.components.health.redirect = HealthRedirect
    inst.components.health.canheal = false

    inst:AddComponent("combat")
    inst.components.combat:SetDefaultDamage(TUNING.PUGALISK_DAMAGE/2)
    inst.components.combat.playerdamagepercent = 0.5
    inst.components.combat:SetRange(TUNING.PUGALISK_MELEE_RANGE, TUNING.PUGALISK_MELEE_RANGE)
    inst.components.combat.hiteffectsymbol = "hit_target"
    inst.components.combat:SetAttackPeriod(TUNING.PUGALISK_ATTACK_PERIOD/2)
    inst.components.combat:SetRetargetFunction(0.5, RetargetTailFn)
    inst.components.combat.onhitfn = OnHit

    inst:AddComponent("locomotor")

    inst:AddComponent("lootdropper")

    inst:AddComponent("inspectable")
    inst.components.inspectable.nameoverride = "pugalisk"

    inst:SetBrain(tail_brain)
    inst:SetStateGraph("SGpugalisk_head")

    return inst
end

-----[[Pugalisk Head]]-----

local function RetargetFn(inst)
    local targetDist = TUNING.PUGALISK_TARGET_DIST

    return FindEntity(inst, targetDist, function(ent)
        return inst.components.combat:CanTarget(ent)
    end, nil, RETARGET_NO_TAGS, RETARGET_ONE_OF_TASG)
end

local function OnDeath(inst)
    ShakeAllCameras(CAMERASHAKE.FULL, 3, 0.05, 0.2, inst, 45)

    inst.components.multibody:KillAllBodies()

    local home = inst.home or TheSim:FindFirstEntityWithTag("pugalisk_trap_door")
    if home then
        home:PushEvent("reactivate")
    end
end

local function OnBodyComplete(inst, data)
    local pt = PugaliskUtil.FindSafeLocation(data.pos, data.angle/DEGREES)
    inst.Transform:SetPosition(pt.x, 0, pt.z)
    inst:DoTaskInTime(0.75, function()
        ShakeAllCameras(CAMERASHAKE.VERTICAL, 0.3, 0.03, 1, inst, SHAKE_DIST)
        inst.components.groundpounder:GroundPound()

        inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/pugalisk/emerge", "emerge")
        inst.SoundEmitter:SetParameter("emerge", "start", math.random())

        PugaliskUtil.DetermineAction(inst)
    end)
end

local function OnSave(inst, data)
    local refs = {}
    if inst.home then
        data.home = inst.home.GUID
        table.insert(refs,inst.home.GUID)
    end
    return refs
end

local function OnLoadPostPass(inst, newents, data)
    if data and data.home then
        local home = newents[data.home].entity
        if home then
            inst.home = home
        end
    end
end

local function PushMusic(inst)
    if ThePlayer == nil then
        inst._playingmusic = false
    elseif ThePlayer:IsNear(inst, inst._playingmusic and 40 or 20) then
        inst._playingmusic = true
        ThePlayer:PushEvent("triggeredevent", {name = "pugalisk"})
    elseif inst._playingmusic and not ThePlayer:IsNear(inst, 50) then
        inst._playingmusic = false
    end
end

local head_brain = require "brains/pugalisk_headbrain"

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("giant_snake")
    inst.AnimState:SetBuild("python_test")
    inst.AnimState:PushAnimation("head_idle_loop", true)
    inst.AnimState:SetFinalOffset(0)

    inst.Transform:SetScale(1.5, 1.5, 1.5)
    inst.Transform:SetSixFaced()

    MakeObstaclePhysics(inst, 1)

    inst:AddTag("epic")
    inst:AddTag("monster")
    inst:AddTag("hostile")
    inst:AddTag("pugalisk")
    inst:AddTag("scarytoprey")
    inst:AddTag("largecreature")
    inst:AddTag("groundpoundimmune")
    inst:AddTag("head")
    inst:AddTag("noflinch")
    inst:AddTag("noteleport")

    inst.name = STRINGS.NAMES.PUGALISK

    inst.entity:SetPristine()

    --Dedicated server does not need to trigger music
    if not TheNet:IsDedicated() then
        inst._playingmusic = false
        inst:DoPeriodicTask(1, PushMusic, 0)
    end

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("sanityaura")
    inst.components.sanityaura.aura = -TUNING.SANITYAURA_LARGE

    inst:AddComponent("combat")
    inst.components.combat:SetDefaultDamage(TUNING.PUGALISK_DAMAGE)
    inst.components.combat.playerdamagepercent = 0.75
    inst.components.combat:SetRange(TUNING.PUGALISK_MELEE_RANGE, TUNING.PUGALISK_MELEE_RANGE)
    inst.components.combat.hiteffectsymbol = "hit_target"
    inst.components.combat:SetAttackPeriod(TUNING.PUGALISK_ATTACK_PERIOD)
    inst.components.combat:SetRetargetFunction(0.5, RetargetFn)
    inst.components.combat.onhitfn = OnHit

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetChanceLootTable("pugalisk")

    inst:AddComponent("inspectable")
    inst.components.inspectable.nameoverride = "pugalisk"

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(TUNING.PUGALISK_HEALTH)
    inst.components.health.destroytime = 5
    inst.components.health:StartRegen(1, 2)
    inst.components.health.redirect = HealthRedirect_Head
    inst.components.health.canheal = false

    inst:AddComponent("knownlocations")

    inst:AddComponent("locomotor")

    inst:AddComponent("groundpounder")
    inst.components.groundpounder.destroyer = true
    inst.components.groundpounder.damageRings = 2
    inst.components.groundpounder.destructionRings = 1
    inst.components.groundpounder.numRings = 2
    inst.components.groundpounder.groundpounddamagemult = 30 / TUNING.PUGALISK_DAMAGE
    inst.components.groundpounder.groundpoundfx= "groundpound_nosound_fx"
    table.insert(inst.components.groundpounder.noTags, "pugalisk")

    inst:AddComponent("multibody")
    inst.components.multibody:Setup(5, "pugalisk_body")

    inst:SetBrain(head_brain)
    inst:SetStateGraph("SGpugalisk_head")

    inst:ListenForEvent("bodycomplete", OnBodyComplete)
    inst:ListenForEvent("bodyfinished", function(inst, data) inst.components.multibody:RemoveBody(data.body) end)
    inst:ListenForEvent("death", OnDeath)

    inst:DoTaskInTime(0, function() inst.spawned = true end)

    inst.OnSave = OnSave
    inst.OnLoadPostPass = OnLoadPostPass

    return inst
end

-----[[Pugalisk Corpse]]-----

local function OnFinishCallback(inst, worker)
    inst.MiniMapEntity:SetEnabled(false)
    inst:RemoveComponent("workable")

    SpawnPrefab("collapse_small").Transform:SetPosition(inst.Transform:GetWorldPosition())

    if worker then
        -- figure out which side to drop the loot
        local pt = Vector3(inst.Transform:GetWorldPosition())
        local hispos = Vector3(worker.Transform:GetWorldPosition())

        local he_right = ((hispos - pt):Dot(TheCamera:GetRightVec()) > 0)

        if he_right then
            inst.components.lootdropper:DropLoot(pt - (TheCamera:GetRightVec() * (math.random() + 1)))
        else
            inst.components.lootdropper:DropLoot(pt + (TheCamera:GetRightVec() * (math.random() + 1)))
        end

        inst:Remove()
    end
end

local function corpsefn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("giant_snake")
    inst.AnimState:SetBuild("python_test")
    inst.AnimState:PlayAnimation("death_idle", true)

    inst.MiniMapEntity:SetIcon("snake_skull_buried.tex")

    inst.Transform:SetScale(1.5, 1.5, 1.5)
    inst.Transform:SetSixFaced()

    MakeObstaclePhysics(inst, 1)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.DIG)
    inst.components.workable:SetWorkLeft(1)
    inst.components.workable:SetOnFinishCallback(OnFinishCallback)

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetLoot({"pugalisk_skull"})

    return inst
end

local function OnRemove_Redirect(inst)
    local segbody = inst._body:value()
    if segbody and segbody:IsValid() and segbody.redirects then
        for i, testseg in ipairs(segbody.redirects)do
            if inst == testseg then
                table.remove(segbody.redirects, i)
            end
        end
    end
end

local function OnBodyDirty_Redirect(inst)
    local segbody = inst._body:value()
    if segbody and segbody:IsValid() and segbody.redirects then
        table.insert(segbody.redirects, inst)
    end
    inst:ListenForEvent("onremove", OnRemove_Redirect)
end

local function pugalisk_redirectfn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    inst:AddTag("NOCLICK")
    inst:AddTag("NOBLOCK")
    inst:AddTag("hostile")

    inst._body = net_entity(inst.GUID, "_body", "bodydirty")

    inst.name = STRINGS.NAMES.PUGALISK

    inst:ListenForEvent("bodydirty", OnBodyDirty_Redirect)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.persists = false

    inst:AddComponent("combat")
    inst.components.combat:SetDefaultDamage(0)
    inst.components.combat.hiteffectsymbol = "test_segments"

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(9999)
    inst.components.health.destroytime = 5
    inst.components.health.redirect = HealthRedirect
    inst.components.health.canheal = false

    inst:AddComponent("inspectable")
    inst.components.inspectable.nameoverride = "pugalisk"

    return inst
end

return  Prefab("pugalisk", fn, assets, prefabs),
        Prefab("pugalisk_body", bodyfn, assets, prefabs),
        Prefab("pugalisk_tail", tailfn, assets, prefabs),
        Prefab("pugalisk_segment", segmentfn, assets, prefabs),
        Prefab("pugalisk_corpse", corpsefn, assets, prefabs),
        Prefab("pugalisk_redirect", pugalisk_redirectfn, {}, {})
