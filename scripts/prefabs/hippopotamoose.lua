local assets=
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
    "hippoherd",
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

local SLEEP_DIST_FROMHOME = 1
local SLEEP_DIST_FROMTHREAT = 20
local MAX_TARGET_SHARES = 5
local SHARE_TARGET_DIST = 40

local function ShouldSleep(inst)
    local home_position = inst.components.knownlocations:GetLocation("home")
    local x, y, z = inst.Transform:GetWorldPosition()

    if not (home_position and VecUtil_DistSq(home_position.x, home_position.z, x, z) <= SLEEP_DIST_FROMHOME * SLEEP_DIST_FROMHOME)
       or (inst.components.combat and inst.components.combat.target)
       or (inst.components.burnable and inst.components.burnable:IsBurning())
       or (inst.components.freezable and inst.components.freezable:IsFrozen())
       or inst.sg:HasStateTag("busy") then
        return false
    end

    local nearestEnt = GetClosestInstWithTag("character", inst, SLEEP_DIST_FROMTHREAT)
    return nearestEnt == nil
end

local function ShouldWake(inst)
    local home_position = inst.components.knownlocations:GetLocation("home")
    local x, y, z = inst.Transform:GetWorldPosition()

    if not (home_position and VecUtil_DistSq(home_position.x, home_position.z, x, z) <= SLEEP_DIST_FROMHOME * SLEEP_DIST_FROMHOME)
       or (inst.components.combat and inst.components.combat.target)
       or (inst.components.burnable and inst.components.burnable:IsBurning())
       or (inst.components.freezable and inst.components.freezable:IsFrozen())
       or inst.sg:HasStateTag("busy") then
        return true
    end

    local nearestEnt = GetClosestInstWithTag("character", inst, SLEEP_DIST_FROMTHREAT)
    return nearestEnt ~= nil
end

local function OnAttacked(inst, data)
    inst:AddTag("enraged")
    local attacker = data and data.attacker
    inst.components.combat:SetTarget(attacker)
    inst.components.combat:ShareTarget(attacker, SHARE_TARGET_DIST, function(ent) return ent:HasTag("hippopotamoose") end, MAX_TARGET_SHARES)
end

local function OnEnterWater(inst)
    inst.DynamicShadow:Enable(false)

    if not inst.sg:HasStateTag("leapattack") then
        local noanim = inst:GetTimeAlive() < 1
        inst.sg:GoToState("submerge", noanim)
    end
end

local function OnExitWater(inst)
    inst.DynamicShadow:Enable(true)

    if not inst.sg:HasStateTag("leapattack") then
        local noanim = inst:GetTimeAlive() < 1
        inst.sg:GoToState("emerge", noanim)
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
	inst.DynamicShadow:SetSize( 3, 1.25 )
    inst.Transform:SetFourFaced()

    MakeAmphibiousCharacterPhysics(inst, 50, 1.5)

    inst:AddTag("animal")
    inst:AddTag("hippopotamoose")
    inst:AddTag("huff_idle")
    inst:AddTag("wavemaker")
    inst:AddTag("lightshake")
    inst:AddTag("groundpoundimmune")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("locomotor")
    inst.components.locomotor.walkspeed = TUNING.HIPPO_WALK_SPEED
    inst.components.locomotor.runspeed =  TUNING.HIPPO_RUN_SPEED

    inst:AddComponent("amphibiouscreature")
    inst.components.amphibiouscreature:SetEnterWaterFn(OnEnterWater)
    inst.components.amphibiouscreature:SetExitWaterFn(OnExitWater)

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetChanceLootTable("hippopotamoose")

    inst:AddComponent("sleeper")
    inst.components.sleeper:SetWakeTest(ShouldWake)
    inst.components.sleeper:SetSleepTest(ShouldSleep)
    inst.components.sleeper:SetResistance(3)

    inst:AddComponent("combat")
    inst.components.combat.hiteffectsymbol = "innerds"
    inst.components.combat:SetAttackPeriod(2)

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(TUNING.HIPPO_HEALTH)
    inst.components.combat:SetDefaultDamage(TUNING.HIPPO_DAMAGE)
    inst.components.combat:SetAttackPeriod(TUNING.HIPPO_ATTACK_PERIOD)

    inst:AddComponent("groundpounder")
    inst.components.groundpounder.destroyer = true
    inst.components.groundpounder.damageRings = 2
    inst.components.groundpounder.destructionRings = 1
    inst.components.groundpounder.numRings = 2

    inst:AddComponent("inspectable")

    inst:AddComponent("knownlocations")

    inst:AddComponent("herdmember")
    inst.components.herdmember:SetHerdPrefab("hippoherd")

    inst:SetBrain(brain)
    inst:SetStateGraph("SGhippopotamoose")

    MakeHauntablePanic(inst)
    MakePoisonableCharacter(inst)
    MakeLargeBurnableCharacter(inst, "innerds")
    MakeMediumFreezableCharacter(inst, "innerds")

    inst:DoTaskInTime(2 * FRAMES, function() inst.components.knownlocations:RememberLocation("home", Vector3(inst.Transform:GetWorldPosition()), true) end)
    inst:ListenForEvent("attacked", OnAttacked)

    return inst
end

return Prefab("hippopotamoose", fn, assets, prefabs)
