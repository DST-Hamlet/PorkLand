local assets = {
    Asset("ANIM", "anim/dung_beetle_basic.zip"),
    Asset("ANIM", "anim/dung_beetle_build.zip"),
}

local prefabs = {
    "dungball",
    "monstermeat",
    "chitin",
}

local brain = require("brains/dungbeetlebrain")

SetSharedLootTable("dungbeetle", {
    {"monstermeat", 1},
    {"chitin", 0.5},
})

local function MountDungBall(inst, ball)
    inst:AddTag("hasdung")
    inst.mountball = ball
    ball.bettle = inst

    ball:RemoveFromScene()
    ball:AddTag("hasbettle")
    inst:AddChild(ball)
    ball.Transform:SetPosition(0, 0, 0)
end

local function LoseDungBall(inst)
    inst:RemoveTag("hasdung")

    local ball = inst.mountball
    inst.mountball = nil

    if ball and ball:IsValid() then
        ball.bettle = nil
        ball:RemoveTag("hasbettle")
        inst:RemoveChild(ball)
        ball:ReturnToScene()
        ball.Physics:Teleport(inst.Transform:GetWorldPosition())
        ball.AnimState:PlayAnimation("idle")
    end
end

local function FalloffDung(inst)
    inst:PushEvent("bumped")
end

local function OnAttacked(inst, data)
    inst:DoTaskInTime(1, function()
        if inst:HasTag("hasdung") and not inst.components.freezable:IsFrozen() then
            FalloffDung(inst)
        end
    end)
end

local function GetStatus(inst, viewer)
    if not inst:HasTag("hasdung") then
        return "UNDUNGED"
    end
end

local SLEEP_NEAR_ENEMY_DISTANCE = 14
local function ShouldSleep(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    return DefaultSleepTest(inst) and not IsAnyPlayerInRange(x, y, z, SLEEP_NEAR_ENEMY_DISTANCE)
end

local function OnSave(inst, data)
    if inst:HasTag("hasdung") and (inst.mountball and inst.mountball:IsValid()) then
        data.ballrecord = inst.mountball:GetSaveRecord()
    end
end

local function OnLoad(inst, data)
    if data.ballrecord then
        local ball = SpawnSaveRecord(data.ballrecord)
        if ball then
            inst:MountDungBall(ball)
            inst.AnimState:PlayAnimation("ball_idle", true)
        end
    end
end

local function HitShake(inst)
    ShakeAllCameras(CAMERASHAKE.VERTICAL, .5, .03, 2, inst, 40)
end

local function ValidCollideTarget(inst, other)
    return (inst.sg:HasStateTag("running") or inst.sg:HasStateTag("surprise"))
        and inst:HasTag("hasdung")
        and other ~= nil and other:IsValid()
        and other ~= TheWorld and not other:HasTag("dungpile")
end

local function OnCollide(inst, other)
    if ValidCollideTarget(inst, other) then
        HitShake(inst)
        FalloffDung(inst)
    end
end

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddDynamicShadow()
    inst.entity:AddNetwork()

    inst.Transform:SetSixFaced()
    inst.DynamicShadow:SetSize(2, 1.5)

    MakeCharacterPhysics(inst, 10, 0.5)

    inst:AddTag("smallcreature")
    inst:AddTag("animal")
    inst:AddTag("dungbeetle")
    inst:AddTag("insect")

    inst.AnimState:SetBank("dung_beetle")
    inst.AnimState:SetBuild("dung_beetle_build")
    inst.AnimState:PlayAnimation("idle")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.Physics:SetCollisionCallback(OnCollide)

    inst:AddComponent("knownlocations")

    inst:AddComponent("inspectable")
    inst.components.inspectable.getstatus = GetStatus

    inst:AddComponent("sleeper")
    inst.components.sleeper:SetSleepTest(ShouldSleep)

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(TUNING.DUNGBEETLE_HEALTH)
    inst.components.health.murdersound = "dontstarve/rabbit/scream_short"

    inst:AddComponent("combat")
    inst.components.combat.hiteffectsymbol = "body"

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetChanceLootTable("dungbeetle")

    inst:AddComponent("locomotor")  -- locomotor must be constructed before the stategraph
    inst.components.locomotor.runspeed = TUNING.DUNGBEETLE_RUN_SPEED
    inst.components.locomotor.walkspeed = TUNING.DUNGBEETLE_WALK_SPEED

    inst:ListenForEvent("attacked", OnAttacked)

    inst:SetBrain(brain)
    inst:SetStateGraph("SGdungbeetle")

    MakeHauntablePanicAndIgnite(inst)
    MakeSmallBurnableCharacter(inst, "body")
    MakeTinyFreezableCharacter(inst, "body")
    MakePoisonableCharacter(inst, "body")

    inst.MountDungBall = MountDungBall
    inst.LoseDungBall = LoseDungBall

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad

    return inst
end

return Prefab("dungbeetle", fn, assets, prefabs)
