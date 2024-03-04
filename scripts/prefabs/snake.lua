local brain = require("brains/snakebrain")

local assets=
{
    Asset("ANIM", "anim/snake_basic.zip"),
    Asset("ANIM", "anim/snake_water.zip"),
    Asset("ANIM", "anim/snake_scaly_build.zip"),
}

local prefabs =
{
    "monstermeat",
    "snakeskin",
    "snakeoil",
}

SetSharedLootTable("snake",
{
    {"monstermeat", 1},
    {"snakeskin", 0.5},
    {"snakeoil", 0.01},
})

local SHARE_TARGET_DIST = 30

local function OnNewTarget(inst, data)
    if inst.components.sleeper:IsAsleep() then
        inst.components.sleeper:WakeUp()
    end
end

local RETARGET_CANT_TAGS = {"FX", "NOCLICK","INLIMBO", "wall", "snake", "structure"}
local function Retarget(inst)
    return FindEntity(inst, TUNING.SNAKE_TARGET_DIST, function(ent) return inst.components.combat:CanTarget(ent) end, nil, RETARGET_CANT_TAGS)
end

local function KeepTarget(inst, target)
    return inst.components.combat:CanTarget(target)
        and inst:GetDistanceSqToInst(target) <= (TUNING.SNAKE_KEEP_TARGET_DIST * TUNING.SNAKE_KEEP_TARGET_DIST)
end

local function OnAttacked(inst, data)
    inst.components.combat:SetTarget(data.attacker)
    inst.components.combat:ShareTarget(data.attacker, SHARE_TARGET_DIST, function(ent)
        return ent:HasTag("snake") and not ent.components.health:IsDead()
    end, 5)
end

local function OnAttackOther(inst, data)
    inst.components.combat:ShareTarget(data.target, SHARE_TARGET_DIST, function(ent)
        return ent:HasTag("snake") and not ent.components.health:IsDead()
    end, 5)
end

local function SanityAura(inst, observer) -- Add this as a postinit to webber instead?
    if observer.prefab == "webber" then
        return 0
    end

    return -TUNING.SANITYAURA_SMALL
end

local function OnEnterWater(inst)
    inst.DynamicShadow:Enable(false)

    if (inst.components.freezable and inst.components.freezable:IsFrozen())
        or (inst.components.sleeper and inst.components.sleeper:IsAsleep()) then
        inst.AnimState:SetBank("snake_water")
        return
    end

    local noanim = inst:GetTimeAlive() < 1
    inst.sg:GoToState("submerge", noanim)
end

local function OnExitWater(inst)
    inst.DynamicShadow:Enable(true)

    if (inst.components.freezable and inst.components.freezable:IsFrozen())
        or (inst.components.sleeper and inst.components.sleeper:IsAsleep()) then
        inst.AnimState:SetBank("snake")
        return
    end

    local noanim = inst:GetTimeAlive() < 1
    inst.sg:GoToState("emerge", noanim)
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddPhysics()
    inst.entity:AddSoundEmitter()
    inst.entity:AddDynamicShadow()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("snake")
    inst.AnimState:SetBuild("snake_scaly_build")
    inst.AnimState:PlayAnimation("idle")
    inst.AnimState:SetRayTestOnBB(true)

    inst.Transform:SetFourFaced()

    inst:AddTag("scarytoprey")
    inst:AddTag("monster")
    inst:AddTag("hostile")
    inst:AddTag("snake")
    inst:AddTag("animal")
    inst:AddTag("canbetrapped")
    inst:AddTag("amphibious")
    inst:AddTag("snake_amphibious")

    MakeAmphibiousCharacterPhysics(inst, 1, 0.5)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("knownlocations")

    inst:AddComponent("locomotor") -- locomotor must be constructed before the stategraph
    inst.components.locomotor.runspeed = TUNING.SNAKE_SPEED
    inst.components.locomotor.pathcaps = {allowocean = true}

    inst:AddComponent("follower")

    inst:AddComponent("eater")
    inst.components.eater:SetDiet({FOODTYPE.MEAT}, {FOODTYPE.MEAT})
    inst.components.eater:SetCanEatHorrible()
    inst.components.eater.strongstomach = true -- can eat monster meat!

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(TUNING.SNAKE_HEALTH)
    inst.components.health.poison_damage_scale = 0 -- immune to poison

    inst:AddComponent("combat")
    inst.components.combat:SetDefaultDamage(TUNING.SNAKE_DAMAGE)
    inst.components.combat:SetAttackPeriod(TUNING.SNAKE_ATTACK_PERIOD)
    inst.components.combat:SetRetargetFunction(3, Retarget)
    inst.components.combat:SetKeepTargetFunction(KeepTarget)
    inst.components.combat:SetHurtSound("dontstarve_DLC002/creatures/snake/hurt")
    inst.components.combat:SetRange(2, 3)

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetChanceLootTable("snake")
    inst.components.lootdropper.numrandomloot = math.random(0, 1)

    inst:AddComponent("inspectable")

    inst:AddComponent("sanityaura")
    inst.components.sanityaura.aurafn = SanityAura

    inst:AddComponent("sleeper")
    inst.components.sleeper:SetNocturnal(true)

    inst:AddComponent("amphibiouscreature")
    inst.components.amphibiouscreature:SetEnterWaterFn(OnEnterWater)
    inst.components.amphibiouscreature:SetExitWaterFn(OnExitWater)

    MakeMediumFreezableCharacter(inst, "body")
    MakeMediumBurnableCharacter(inst) --, "body")
    MakeHauntablePanic(inst)

    inst:SetBrain(brain)
    inst:SetStateGraph("SGsnake")

    inst:ListenForEvent("attacked", OnAttacked)
    inst:ListenForEvent("onattackother", OnAttackOther)
    inst:ListenForEvent("newcombattarget", OnNewTarget)

    return inst
end

return Prefab("snake_amphibious", fn, assets, prefabs)
