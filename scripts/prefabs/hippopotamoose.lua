local assets =
{
    Asset("ANIM", "anim/hippo_basic.zip"),
    Asset("ANIM", "anim/hippo_attacks.zip"),
    Asset("ANIM", "anim/hippo_water.zip"),
    Asset("ANIM", "anim/hippo_water_attacks.zip"),
    Asset("ANIM", "anim/hippo_build.zip"),
}

local prefabs =
{
    "meat",
    "hippo_antler",
}

SetSharedLootTable("hippopotamoose",
{
    {"meat",            1.00},
    {"meat",            1.00},
    {"meat",            1.00},
    {"meat",            1.00},
    {"hippo_antler",    1.00},
})

local brain = require("brains/hippopotamoosebrain")

local MAX_TARGET_SHARES = 5
local SHARE_TARGET_DIST = 40

local WAKE_TO_FACE_DISTANCE = 10
local SLEEP_NEAR_ENEMY_DISTANCE = 12

local function ShouldWakeUp(inst)
    local target = GetClosestInstWithTag("character", inst, WAKE_TO_FACE_DISTANCE)
    return  (inst.components.combat ~= nil and inst.components.combat.target ~= nil)
        or (inst.components.burnable ~= nil and inst.components.burnable:IsBurning())
        or (inst.components.freezable ~= nil and inst.components.freezable:IsFrozen())
        or (inst.components.poisonable ~= nil and inst.components.poisonable:IsPoisoned())
        or (TheWorld.state.isday and (target and not target:HasTag("playerghost") and not target:HasTag("notarget") or not inst.components.amphibiouscreature.in_water))
        or TheWorld.state.isdusk
end

local function ShouldSleep(inst)
    local target = GetClosestInstWithTag("character", inst, SLEEP_NEAR_ENEMY_DISTANCE)
    return not (inst.components.combat ~= nil and inst.components.combat.target ~= nil)
    and not (inst.components.burnable ~= nil and inst.components.burnable:IsBurning())
    and not (inst.components.freezable ~= nil and inst.components.freezable:IsFrozen())
    and not(inst.components.poisonable ~= nil and inst.components.poisonable:IsPoisoned())
    and not inst.sg:HasStateTag("busy")
    and not (target and not target:HasTag("playerghost"))
    and inst.components.amphibiouscreature.in_water
    and not TheWorld.state.isdusk
    or TheWorld.state.isnight
end

local function OnAttacked(inst, data)
    inst:AddTag("enraged")
    local attacker = data and data.attacker
    inst.components.combat:SetTarget(attacker)
    inst.components.combat:ShareTarget(attacker, SHARE_TARGET_DIST, function(ent) return ent:HasTag("hippopotamoose") end, MAX_TARGET_SHARES)
end

local function ShouldSilent(inst)
    return (inst.components.freezable and inst.components.freezable:IsFrozen())
        or (inst.components.sleeper and inst.components.sleeper:IsAsleep())
        or inst.sg:HasStateTag("leapattack")
end

local function OnEnterWater(inst)
    inst.components.knownlocations:ForgetLocation("landing_point")
    inst.components.knownlocations:ForgetLocation("water_nearby")
end

local function OnExitWater(inst)
    inst.components.knownlocations:RememberLocation("landing_point", inst:GetPosition())
end

local function Init(inst)
    if TheWorld.components.hippospawner then
        TheWorld.components.hippospawner:AddHippo(inst)
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()
    inst.entity:AddDynamicShadow()

    inst.AnimState:SetBank("hippo")
    inst.AnimState:SetBuild("hippo_build")
    inst.DynamicShadow:SetSize(3, 1.25)
    inst.Transform:SetFourFaced()

    MakeAmphibiousCharacterPhysics(inst, 50, 1.5)

    inst:AddTag("animal")
    inst:AddTag("hippopotamoose")
    inst:AddTag("huff_idle")
    inst:AddTag("wavemaker")
    inst:AddTag("lightshake")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("knownlocations")

    inst:AddComponent("locomotor")
    inst.components.locomotor.walkspeed = TUNING.HIPPO_WALK_SPEED
    inst.components.locomotor.runspeed = TUNING.HIPPO_RUN_SPEED
    inst.components.locomotor.pathcaps = {allowocean = true}

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetChanceLootTable("hippopotamoose")

    inst:AddComponent("sleeper")
    inst.components.sleeper:SetSleepTest(ShouldSleep)
    inst.components.sleeper:SetWakeTest(ShouldWakeUp)
    inst.components.sleeper:SetResistance(3)

    inst:AddComponent("combat")
    inst.components.combat.hiteffectsymbol = "innerds"
    inst.components.combat:SetAttackPeriod(2)
    inst.components.combat:SetDefaultDamage(TUNING.HIPPO_DAMAGE)
    inst.components.combat:SetAttackPeriod(TUNING.HIPPO_ATTACK_PERIOD)

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(TUNING.HIPPO_HEALTH)

    inst:AddComponent("groundpounder")
    inst.components.groundpounder.destroyer = true
    inst.components.groundpounder.damageRings = 2
    inst.components.groundpounder.destructionRings = 1
    inst.components.groundpounder.numRings = 2
    table.insert(inst.components.groundpounder.noTags, "hippopotamoose")

    inst:SetBrain(brain)
    inst:SetStateGraph("SGhippopotamoose")

    inst:ListenForEvent("attacked", OnAttacked)

    inst:DoTaskInTime(0, Init)

    MakeAmphibious(inst, "hippo", "hippo_water", ShouldSilent, OnEnterWater, OnExitWater)
    MakeHauntablePanic(inst)
    MakePoisonableCharacter(inst)
    MakeLargeBurnableCharacter(inst, "innerds")
    MakeMediumFreezableCharacter(inst, "innerds")

    return inst
end

local function OnEntitySleep(inst)
    if TheWorld.components.hippospawner then
        TheWorld.components.hippospawner:RemoveHippo(inst, true)
    end
    ReplacePrefab(inst, "hippopotamoose")
end

-- Dummy prefab for hippo spawner
local function newborn_fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:SetPristine()

    inst:AddTag("hippopotamoose")

    -- [[Non-networked entity]]

    inst.is_dummy_prefab = true
    inst.OnEntitySleep = OnEntitySleep

    return inst
end

return Prefab("hippopotamoose", fn, assets, prefabs),
    Prefab("hippopotamoose_newborn", newborn_fn)
