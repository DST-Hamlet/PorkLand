local assets =
{
    Asset("ANIM", "anim/metal_spider.zip"),
    Asset("ANIM", "anim/metal_claw.zip"),
    Asset("ANIM", "anim/metal_leg.zip"),
    Asset("ANIM", "anim/metal_head.zip"),
}

local prefabs =
{
    "iron",
    "sparks_fx",
    "sparks_green_fx",
    "laser_ring",
}

local function RemoveMoss(inst)
    if not inst:HasTag("mossy") then
        return
    end

    inst:RemoveTag("mossy")
    local x, y, z = inst.Transform:GetWorldPosition()
    for _ = 1, math.random(12, 15) do
        inst:DoTaskInTime(math.random() * 0.5, function()
            local fx = SpawnPrefab("robot_leaf_fx")
            fx.Transform:SetPosition(x + math.random() * 4 - 2 , y, z + math.random() * 4 -2)
        end)
    end
end

local RETARGET_DIST = 15
local RETARGET_NO_TAGS = {"FX", "NOCLICK", "INLIMBO", "wall", "ancient_robot", "structure"}

local function RetargetFn(inst)
    return FindEntity(inst, RETARGET_DIST, function(ent)
        return inst.components.combat:CanTarget(ent)
    end, nil, RETARGET_NO_TAGS)
end

local function KeepTargetFn(inst, target)
    return true
end

local function OnLightning(inst, data)
    inst.components.timer:SetTimeLeft("discharge", TUNING.ROBOT_DISCHARGE_TIME)
    if not TheWorld.state.isaporkalypse then
        inst.components.timer:ResumeTimer("discharge")
    end

    if inst:HasTag("dormant") then
        inst.wantstodeactivate = nil
        inst:RemoveTag("dormant")
        inst:PushEvent("shock")
    end
end

local function OnAttacked(inst, data)
    inst.components.combat:SetTarget(data.attacker)

    local fx = SpawnPrefab("sparks_green_fx")
    local x, y, z = inst.Transform:GetWorldPosition()
    fx.Transform:SetPosition(x, y + 1, z)
end

local function OnWorkCallback(inst, worker, work_left)
    OnAttacked(inst, {attacker = worker})
    inst.components.workable:SetWorkLeft(1)
    inst:PushEvent("attacked")
end

local function OnAporkalypse(inst, isaporkalypse)
    if isaporkalypse then
        OnLightning(inst)
    else
        inst.components.timer:ResumeTimer("discharge")
    end
end

local function OnTimerDone(inst, data)
    if data.name == "discharge" then
        inst.wantstodeactivate = true
    end
end

local function OnSave(inst, data)
    if inst.hits then
        data.hits = inst.hits
    end
    if inst:HasTag("dormant") then
        data.dormant = true
    end
    if inst:HasTag("mossy") then
        data.mossy = true
    end
    if inst.spawned then
        data.spawned = true
    end
end

local function OnLoad(inst, data)
    if data then
        if data.hits then
            inst.hits = data.hits
        end
        if data.dormant then
            inst:AddTag("dormant")
        end
        if data.mossy then
            inst:AddTag("mossy")
        end
        if data.spawned then
            inst.spawned = true
        end
    end

    if inst:HasTag("dormant") then
        inst.sg:GoToState("idle_dormant")
    end
end

local function OnLoadPostPass(inst, newents, data)
    if inst.spawned then
        if inst.spawntask then
            inst.spawntask:Cancel()
            inst.spawntask = nil
        end
    end
end

local brain = require("brains/ancientrobotbrain")

local function commonfn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddLight()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("metal_spider")
    inst.AnimState:SetBuild("metal_spider")
    inst.AnimState:PlayAnimation("idle", true)

    inst.Light:SetIntensity(0.6)
    inst.Light:SetRadius(5)
    inst.Light:SetFalloff(3)
    inst.Light:SetColour(1, 0, 0)
    inst.Light:Enable(false)

    inst.MiniMapEntity:SetIcon("metal_spider.tex")

    inst.Transform:SetFourFaced()

    inst.collisionradius = 1.2
    MakeCharacterPhysics(inst, 99999, inst.collisionradius)

    inst:AddTag("lightningrod")
    inst:AddTag("laser_immune")
    inst:AddTag("ancient_robot")
    inst:AddTag("dontteleporttointerior")
    inst:AddTag("mech")
    inst:AddTag("monster")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("lootdropper")
    inst:AddComponent("knownlocations")
    inst:AddComponent("inspectable")
    inst:AddComponent("mechassembly")

    inst:AddComponent("locomotor") -- locomotor must be constructed before the stategraph

    inst:AddComponent("combat")
    inst.components.combat.hiteffectsymbol = "body01"
    inst.components.combat:SetDefaultDamage(TUNING.ROBOT_RIBS_DAMAGE)
    inst.components.combat:SetRetargetFunction(1, RetargetFn)
    inst.components.combat:SetKeepTargetFunction(KeepTargetFn)

    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.MINE)
    inst.components.workable:SetWorkLeft(1)
    inst.components.workable:SetOnWorkCallback(OnWorkCallback)
    inst.components.workable.undestroyable = true

    inst:AddComponent("timer")
    inst.components.timer:StartTimer("discharge", TUNING.ROBOT_DISCHARGE_TIME, true)

    inst:SetBrain(brain)

    inst.hits = 0

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad
    inst.OnLoadPostPass = OnLoadPostPass

    inst.spawntask = inst:DoTaskInTime(0, function()
        if not inst.spawned then
            inst:AddTag("mossy")
            inst:AddTag("dormant")
            inst.sg:GoToState("idle_dormant")
            inst.spawned = true
        end
    end)

    inst:ListenForEvent("removemoss", RemoveMoss)
    inst:ListenForEvent("lightningstrike", OnLightning)
    inst:ListenForEvent("timerdone", OnTimerDone)
    inst:WatchWorldState("isaporkalypse", OnAporkalypse)

    return inst
end

local function ribs_fn()
    local inst = commonfn()

    inst.entity:AddDynamicShadow()

    inst.AnimState:SetBank("metal_spider")
    inst.AnimState:SetBuild("metal_spider")
    inst.AnimState:PlayAnimation("idle", true)

    inst.collisionradius = 2
    inst.DynamicShadow:SetSize(6, inst.collisionradius)

    inst:AddTag("beam_attack")
    inst:AddTag("robot_ribs")

    if not TheWorld.ismastersim then
        return inst
    end

    inst.components.locomotor.walkspeed = TUNING.ROBOT_LOCOMOTE_SPEED.RIBS
    inst.components.locomotor.runspeed = TUNING.ROBOT_LOCOMOTE_SPEED.RIBS

    inst.components.mechassembly:SetUp({RIBS = 1})

    inst:SetStateGraph("SGancient_robot_ribs")

    return inst
end

local function claw_fn()
    local inst = commonfn()

    inst.AnimState:SetBank("metal_claw")
    inst.AnimState:SetBuild("metal_claw")
    inst.AnimState:PlayAnimation("idle", true)

    inst.MiniMapEntity:SetIcon("metal_claw.tex")

    inst.collisionradius = 1.2
    MakeCharacterPhysics(inst, 99999, inst.collisionradius)

    inst.Transform:SetSixFaced()

    inst:AddTag("beam_attack")
    inst:AddTag("robot_arm")

    if not TheWorld.ismastersim then
        return inst
    end

    inst.components.locomotor.walkspeed = TUNING.ROBOT_LOCOMOTE_SPEED.CLAW
    inst.components.locomotor.runspeed = TUNING.ROBOT_LOCOMOTE_SPEED.CLAW

    inst.components.mechassembly:SetUp({CLAW = 1})

    inst:SetStateGraph("SGancient_robot_claw")

    return inst
end

local function leg_fn()
    local inst = commonfn()

    inst.entity:AddDynamicShadow()

    inst.AnimState:SetBank("metal_leg")
    inst.AnimState:SetBuild("metal_leg")
    inst.AnimState:PlayAnimation("idle", true)

    inst.DynamicShadow:SetSize(4, 2)

    inst.MiniMapEntity:SetIcon("metal_leg.tex")

    inst.collisionradius = 1.2
    MakeCharacterPhysics(inst, 99999, inst.collisionradius)

    inst.Transform:SetSixFaced()

    inst:AddTag("jump_attack")
    inst:AddTag("lightning_taunt")
    inst:AddTag("robot_leg")

    if not TheWorld.ismastersim then
        return inst
    end

    inst.components.locomotor.walkspeed = TUNING.ROBOT_LOCOMOTE_SPEED.LEG
    inst.components.locomotor.runspeed = TUNING.ROBOT_LOCOMOTE_SPEED.LEG

    inst.components.mechassembly:SetUp({LEG = 1})

    inst:SetStateGraph("SGancient_robot_leg")

    inst.components.combat:SetDefaultDamage(TUNING.ROBOT_LEG_DAMAGE)

    return inst
end

local function head_fn()
    local inst = commonfn()

    inst.entity:AddDynamicShadow()

    inst.AnimState:SetBank("metal_head")
    inst.AnimState:SetBuild("metal_head")
    inst.AnimState:PlayAnimation("idle", true)

    inst.DynamicShadow:SetSize(4, 2)

    inst.MiniMapEntity:SetIcon("metal_head.tex")

    inst.collisionradius = 2
    MakeCharacterPhysics(inst, 99999, inst.collisionradius)

    inst.Transform:SetSixFaced()

    inst:AddTag("jump_attack")
    inst:AddTag("robot_head")

    if not TheWorld.ismastersim then
        return inst
    end

    inst.components.locomotor.walkspeed = TUNING.ROBOT_LOCOMOTE_SPEED.HEAD
    inst.components.locomotor.runspeed = TUNING.ROBOT_LOCOMOTE_SPEED.HEAD

    inst.components.combat:SetDefaultDamage(TUNING.ROBOT_LEG_DAMAGE)

    inst.components.mechassembly:SetUp({HEAD = 1})

    inst:SetStateGraph("SGancient_robot_head")

    return inst
end

return Prefab("ancient_robot_ribs", ribs_fn, assets, prefabs),
       Prefab("ancient_robot_claw", claw_fn, assets, prefabs),
       Prefab("ancient_robot_leg", leg_fn, assets, prefabs),
       Prefab("ancient_robot_head", head_fn, assets, prefabs)
