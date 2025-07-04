local AncientHulkUtil = require("prefabs/ancient_hulk_util")

local SetLightValueWithFade = AncientHulkUtil.SetLightValueWithFade
local DoCircularAOE = AncientHulkUtil.DoCircularAOE

local SHAKE_DIST = 40

local assets =
{
    Asset("ANIM", "anim/ground_chunks_breaking_brown.zip"),
    Asset("ANIM", "anim/laser_explode_sm.zip"),
    Asset("ANIM", "anim/laser_explosion.zip"),
    Asset("ANIM", "anim/metal_hulk_actions.zip"),
    Asset("ANIM", "anim/metal_hulk_attacks.zip"),
    Asset("ANIM", "anim/metal_hulk_barrier.zip"),
    Asset("ANIM", "anim/metal_hulk_basic.zip"),
    Asset("ANIM", "anim/metal_hulk_bomb.zip"),
    Asset("ANIM", "anim/metal_hulk_build.zip"),
    Asset("ANIM", "anim/metal_hulk_explode.zip"),
    Asset("ANIM", "anim/metal_hulk_projectile.zip"),
    Asset("ANIM", "anim/smoke_aoe.zip"),
}

local prefabs =
{
    "groundpound_fx",
    "groundpoundring_fx",
    "ancient_robots_assembly",
    "rock_basalt",
    "living_artifact",
    "ancient_hulk_orb_small",
    "infused_iron",
    "living_artifact_blueprint",
}

SetSharedLootTable("ancient_hulk",
{
    {"living_artifact_blueprint",   1.00},
    {"infused_iron",                1.00},
    {"infused_iron",                1.00},
    {"infused_iron",                1.00},
    {"infused_iron",                1.00},
    {"infused_iron",                1.00},
    {"infused_iron",                1.00},
    {"infused_iron",                0.25},
    {"iron",                        1.00},
    {"iron",                        1.00},
    {"iron",                        0.75},
    {"iron",                        0.25},
    {"iron",                        0.25},
    {"iron",                        0.25},
    {"gears",                       1.00},
    {"gears",                       1.00},
    {"gears",                       0.75},
    {"gears",                       0.30},
})

local function CalcSanityAura(inst, observer)
    if inst.components.combat.target then
        return -TUNING.SANITYAURA_HUGE
    end

    return -TUNING.SANITYAURA_LARGE
end

local RETARGET_DIST = 30

local function RetargetFn(inst)
    return FindEntity(inst, RETARGET_DIST, function(ent)
        return inst.components.combat:CanTarget(ent)
    end)
end

local function KeepTargetFn(inst, target)
    return inst.components.combat:CanTarget(target)
end

local function OnAttacked(inst, data)
    inst.components.combat:SetTarget(data.attacker)
end

local function ClearRecentlyCollided(inst, other)
    inst.recently_collided[other] = nil
end

local function OnDestroyOther(inst, other)
    if other:IsValid() and
        other.components.workable ~= nil and
        other.components.workable:CanBeWorked() and
        other.components.workable.action ~= ACTIONS.NET and
        not inst.recently_collided[other] then
        SpawnPrefab("collapse_small").Transform:SetPosition(other.Transform:GetWorldPosition())
        other.components.workable:Destroy(inst)
        if other:IsValid() and other.components.workable ~= nil and other.components.workable:CanBeWorked() then
            inst.recently_collided[other] = true
            inst:DoTaskInTime(3, ClearRecentlyCollided, other)
        end
    end
end

local function OnCollide(inst, other)
    if other ~= nil and
        other:IsValid() and
        other.components.workable ~= nil and
        other.components.workable:CanBeWorked() and
        other.components.workable.action ~= ACTIONS.NET and
        Vector3(inst.Physics:GetVelocity()):LengthSq() >= 1 and
        not inst.recently_collided[other] then
        inst:DoTaskInTime(2 * FRAMES, OnDestroyOther, other)
    end
end

local function PushMusic(inst)
    if ThePlayer == nil then
        inst._playingmusic = false
    elseif ThePlayer:IsNear(inst, inst._playingmusic and 40 or 20) then
        inst._playingmusic = true
        ThePlayer:PushEvent("triggeredevent", {name = "ancient_hulk"})
    elseif inst._playingmusic and not ThePlayer:IsNear(inst, 50) then
        inst._playingmusic = false
    end
end

local function OnMixerDirty(inst, data)
    if inst.mixer:value() then
        TheMixer:PushMix("boom")
    else
        TheMixer:PopMix("boom")
    end
end

local function OnRemoveEntity_Client(inst)
    TheMixer:PopMix("boom")
end

local brain = require("brains/ancienthulkbrain")

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddDynamicShadow()
    inst.entity:AddLight()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("metal_hulk")
    inst.AnimState:SetBuild("metal_hulk_build")
    inst.AnimState:PlayAnimation("idle", true)

    inst.AnimState:AddOverrideBuild("laser_explode_sm")
    inst.AnimState:AddOverrideBuild("smoke_aoe")
    inst.AnimState:AddOverrideBuild("laser_explosion")
    inst.AnimState:AddOverrideBuild("ground_chunks_breaking")

    inst.DynamicShadow:SetSize(6, 3.5)

    inst.Light:SetIntensity(0.6)
    inst.Light:SetRadius(5)
    inst.Light:SetFalloff(3)
    inst.Light:SetColour(1, 0.3, 0.3)
    inst.Light:Enable(false)

    inst.Transform:SetSixFaced()

    MakeCharacterPhysics(inst, 1000, 1.5)

    inst:AddComponent("fader")

    inst:AddTag("epic")
    inst:AddTag("monster")
    inst:AddTag("hostile")
    inst:AddTag("scarytoprey")
    inst:AddTag("largecreature")
    inst:AddTag("ancient_hulk")
    inst:AddTag("laser_immune")
    inst:AddTag("mech")
    inst:AddTag("noember")
    inst:AddTag("soulless")

    inst.mixer = net_bool(inst.GUID, "antqueen.mixer", "mixerdirty")

    inst.entity:SetPristine()

    if not TheNet:IsDedicated() then
        inst._playingmusic = false
        inst:DoPeriodicTask(1, PushMusic, 0)
    end

    if not TheWorld.ismastersim then
        inst:ListenForEvent("mixerdirty", OnMixerDirty)

        inst.OnRemoveEntity = OnRemoveEntity_Client

        return inst
    end

    inst.recently_collided = {}
    inst.Physics:SetCollisionCallback(OnCollide)

    inst:AddComponent("locomotor")
    inst.components.locomotor.walkspeed = TUNING.BEARGER_CALM_WALK_SPEED
    inst.components.locomotor.runspeed = TUNING.BEARGER_RUN_SPEED
    inst.components.locomotor:SetShouldRun(true)

    inst:AddComponent("sanityaura")
    inst.components.sanityaura.aurafn = CalcSanityAura

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(TUNING.ANCIENT_HULK_HEALTH)
    inst.components.health.destroytime = 5
    inst.components.health.fire_damage_scale = 0

    inst:AddComponent("combat")
    inst.components.combat:SetDefaultDamage(TUNING.ANCIENT_HULK_DAMAGE)
    inst.components.combat.playerdamagepercent = 0.5
    inst.components.combat:SetRange(TUNING.ANCIENT_HULK_ATTACK_RANGE, TUNING.ANCIENT_HULK_MELEE_RANGE)
    inst.components.combat:SetAreaDamage(5.5, 0.8)
    inst.components.combat.hiteffectsymbol = "segment01"
    inst.components.combat:SetAttackPeriod(TUNING.BEARGER_ATTACK_PERIOD)
    inst.components.combat:SetRetargetFunction(3, RetargetFn)
    inst.components.combat:SetKeepTargetFunction(KeepTargetFn)

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetChanceLootTable("ancient_hulk")

    inst:AddComponent("inspectable")

    inst:AddComponent("timer")

    inst:AddComponent("groundpounder")
    inst.components.groundpounder.destroyer = true
    inst.components.groundpounder.damageRings = 2
    inst.components.groundpounder.destructionRings = 3
    inst.components.groundpounder.numRings = 3
    inst.components.groundpounder.groundpoundfx = "groundpound_fx_hulk"
    table.insert(inst.components.groundpounder.noTags, "ancient_hulk")

    inst:SetBrain(brain)
    inst:SetStateGraph("SGancient_hulk")

    inst.OnRemoveEntity = OnRemoveEntity_Client

    inst.orbs = 2

    inst:ListenForEvent("attacked", OnAttacked)

    inst:ListenForEvent("killed", function(inst, data)
        if inst.components.combat and data and data.victim == inst.components.combat.target then
            inst.components.combat.target = nil
        end
    end)

    if not inst.shotspawn then
        inst.shotspawn = SpawnPrefab("ancient_hulk_marker")
        inst.shotspawn:Hide()
        inst.shotspawn.persists = false
        local follower = inst.shotspawn.entity:AddFollower()
        follower:FollowSymbol( inst.GUID, "hand01", 0,0,0 )
    end

    return inst
end

local function OnNearMine(inst, ents)
    SetLightValueWithFade(inst, 0, 0.75, 0.2)
    inst.AnimState:PlayAnimation("red_loop", true)
    inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/active_LP", "boom_loop")
    inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/electro")
    inst:DoTaskInTime(0.8, function()
        inst:Hide()
        inst.SoundEmitter:KillSound("boom_loop")
        ShakeAllCameras(CAMERASHAKE.VERTICAL, 0.5, 0.03, 2, inst, SHAKE_DIST)

        local ring = SpawnPrefab("laser_ring")
        ring.Transform:SetPosition(inst.Transform:GetWorldPosition())
        inst:DoTaskInTime(0.3, function()
            DoCircularAOE(inst, 3.5)
            inst:Remove()
        end)

        local explosion = SpawnPrefab("laser_explosion")
        explosion.Transform:SetPosition(inst.Transform:GetWorldPosition())
        inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/smash_3")
    end)
end

local function MineTestFn(inst)
    return not (inst:HasTag("ancient_hulk") or inst:HasTag("flying") or inst:HasTag("shadow"))
end

local function OnHit(inst, dist)
    inst.AnimState:PlayAnimation("land")
    inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/ribs/step_wires")
    inst.AnimState:PushAnimation("open")
    inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/rust")
    inst:ListenForEvent("animover", function()
        if inst.AnimState:IsCurrentAnimation("open") then
            inst.AnimState:PlayAnimation("green_loop", true)

            inst:AddComponent("creatureprox")
            inst.components.creatureprox.period = 0.01
            inst.components.creatureprox:SetDist(3.5, 5)
            inst.components.creatureprox:SetOnNear(OnNearMine)
            inst.components.creatureprox:SetFindTestFn(MineTestFn)
        end
    end)
end

local function MineOnSave(inst, data)
    if inst.components.creatureprox then
        data.primed = true
    end
end

local function MineOnLoad(inst, data)
    if data and data.primed then
        inst:AddComponent("creatureprox")
        inst.components.creatureprox.period = 0.01
        inst.components.creatureprox:SetDist(3.5, 5)
        inst.components.creatureprox:SetOnNear(OnNearMine)
        inst.components.creatureprox:SetFindTestFn(MineTestFn)
        inst.components.creatureprox:Schedule()
    end
end

local function mine_fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddLight()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeThrowablePhysics(inst, 75, 0.5)

    inst.AnimState:SetBank("metal_hulk_mine")
    inst.AnimState:SetBuild("metal_hulk_bomb")
    inst.AnimState:PlayAnimation("green_loop", true)

    inst.Light:SetIntensity(0.6)
    inst.Light:SetRadius(2)
    inst.Light:SetFalloff(1)
    inst.Light:SetColour(1, 0.3, 0.3)
    inst.Light:Enable(false)

    inst:AddComponent("fader")

    inst:AddTag("ancient_hulk_mine")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("locomotor")

    inst:AddComponent("throwable")
    inst.components.throwable:SetOnHitFn(OnHit)
    inst.components.throwable.yOffset = 2.5
    inst.components.throwable.speed = 60

    inst:AddComponent("combat")
    inst.components.combat:SetDefaultDamage(TUNING.ANCIENT_HULK_MINE_DAMAGE)
    inst.components.combat.playerdamagepercent = 0.5

    inst.OnSave = MineOnSave
    inst.OnLoad = MineOnLoad

    MakeHauntable(inst)

    return inst
end

local function OnHitOrb(inst, other)
    ShakeAllCameras(CAMERASHAKE.VERTICAL, 0.4, 0.03, 1.5, inst, SHAKE_DIST)

    inst.AnimState:PlayAnimation("impact")
    inst:ListenForEvent("animover", function()
        if inst.AnimState:IsCurrentAnimation("impact") then
           inst:Remove()
        end
    end)

    local x, y, z = inst.Transform:GetWorldPosition()
    inst:DoTaskInTime(0.3, function() DoCircularAOE(inst, 3.5) end)

    -- TODO: use different visual and sound effects hitting clouds/water(spawn some waves maybe?)
    local ring = SpawnPrefab("laser_ring")
    ring.Transform:SetPosition(x, y, z)
    inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/smash_2")
end

local function orb_fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddLight()
    inst.entity:AddNetwork()

    MakeThrowablePhysics(inst, 75, 0.5)

    inst.AnimState:SetBank("metal_hulk_projectile")
    inst.AnimState:SetBuild("metal_hulk_projectile")
    inst.AnimState:PlayAnimation("spin_loop", true)

    inst.Light:SetIntensity(0.6)
    inst.Light:SetRadius(3)
    inst.Light:SetFalloff(1)
    inst.Light:SetColour(1, 0.3, 0.3)
    inst.Light:Enable(true)

    inst:AddComponent("fader")

    inst:AddTag("ancient_hulk_orb")
    inst:AddTag("projectile")
    inst:AddTag("laser")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.persists = false

    inst:AddComponent("locomotor")

    inst:AddComponent("throwable")
    inst.components.throwable:SetOnHitFn(OnHitOrb)
    inst.components.throwable.yOffset = 2.5
    inst.components.throwable.speed = 60
    inst.components.throwable.maxdistance = 64

    inst:AddComponent("combat")
    inst.components.combat:SetDefaultDamage(TUNING.ANCIENT_HULK_MINE_DAMAGE)
    inst.components.combat.playerdamagepercent = 0.5

    return inst
end

local function OnCollidesmall(inst, other)
    DoCircularAOE(inst, 1.5)

    local explosion = SpawnPrefab("laser_explosion_small")
    explosion.Transform:SetPosition(inst.Transform:GetWorldPosition())

    inst.AnimState:PlayAnimation("impact")

    inst:DoTaskInTime(10 * FRAMES, inst.Remove)
end

local function orb_small_fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddLight()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeCharacterThrowablePhysics(inst, 1, 0.5)

    inst.AnimState:SetBank("metal_hulk_projectile")
    inst.AnimState:SetBuild("metal_hulk_projectile")
    inst.AnimState:PlayAnimation("spin_loop", true)

    inst.Light:SetIntensity(0.6)
    inst.Light:SetRadius(3)
    inst.Light:SetFalloff(1)
    inst.Light:SetColour(1, 0.3, 0.3)
    inst.Light:Enable(true)

    inst.Transform:SetScale(0.5, 0.5, 0.5)

    inst:AddComponent("fader")

    inst:AddTag("projectile")
    inst:AddTag("laser")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.persists = false

    inst:AddComponent("locomotor")

    inst:AddComponent("combat")
    inst.components.combat:SetDefaultDamage(TUNING.ANCIENT_HULK_MINE_DAMAGE/3)
    inst.components.combat.playerdamagepercent = 0.5

    inst:AddComponent("throwable")
    inst.components.throwable:SetOnHitFn(OnCollidesmall)
    inst.components.throwable.yOffset = 1.5
    inst.components.throwable.xOffset = 1.5
    inst.components.throwable.speed = 60

    inst:DoTaskInTime(2, inst.Remove)

    return inst
end

local function OnCollidecharge(inst, other)
    inst.Physics:SetMotorVelOverride(0, 0, 0)
    ShakeAllCameras(CAMERASHAKE.VERTICAL, 0.4, 0.03, 1.5, inst, SHAKE_DIST)

    inst.AnimState:PlayAnimation("impact")
    inst:ListenForEvent("animover", function()
        if inst.AnimState:IsCurrentAnimation("impact") then
           inst:Remove()
        end
    end)

    local ring = SpawnPrefab("laser_ring")
    ring.Transform:SetPosition(inst.Transform:GetWorldPosition())
    inst:DoTaskInTime(0.3, function() DoCircularAOE(inst, 3.5) end)
    inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/smash_2")
end

local function marker_fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddNetwork()

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.persists = false

    return inst
end

return Prefab("ancient_hulk", fn, assets, prefabs),
       Prefab("ancient_hulk_mine", mine_fn, assets, prefabs),
       Prefab("ancient_hulk_orb", orb_fn, assets, prefabs),
       Prefab("ancient_hulk_orb_small", orb_small_fn, assets, prefabs),
       Prefab("ancient_hulk_marker", marker_fn, assets, prefabs)
