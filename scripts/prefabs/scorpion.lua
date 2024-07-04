local assets =
{
    Asset("ANIM", "anim/scorpion_basic.zip"),
    Asset("ANIM", "anim/scorpion_build.zip"),
}

local prefabs =
{
    "chitin",
    "monstermeat",
    "venomgland",
    "stinger",
}

SetSharedLootTable( "scorpion",
{
    {"monstermeat",  1.0},
    {"chitin",       0.3},
    {"venomgland",   0.3},
    {"stinger",      0.3},
})


local RETARGET_DIST = 4
local RETARGET_NO_TAGS = {"INLIMBO"}
local RETARGET_ONE_OF_TAGS = {"character", "pig"}
local SHARE_TARGET_DIST = 30
local SHARD_TARGET_COUNT = 5

local function RetargetFn(inst)
    return FindEntity(inst, RETARGET_DIST, function(ent)
        return inst.components.combat:CanTarget(ent) and ent:HasTag("character") or ent:HasTag("pig")
    end, nil, RETARGET_NO_TAGS, RETARGET_ONE_OF_TAGS)
end

local function KeepTargetFn(inst, target)
   return target and target.components.combat
        and target.components.health and not target.components.health:IsDead()
end

local function OnAttacked(inst, data)
    inst.components.combat:SetTarget(data.attacker)
    inst.components.combat:ShareTarget(data.target, SHARE_TARGET_DIST, function(ent)
        return ent:HasTag("scorpion") and not ent.components.health:IsDead()
    end, SHARD_TARGET_COUNT)
end

local brain = require("brains/scorpionbrain")

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddLightWatcher()
    inst.entity:AddDynamicShadow()
    inst.entity:AddNetwork()

    inst.DynamicShadow:SetSize(1.5, 0.5)
    inst.Transform:SetFourFaced()

    inst:AddTag("monster")
    inst:AddTag("animal")
    inst:AddTag("insect")
    inst:AddTag("hostile")
    inst:AddTag("scarytoprey")
    inst:AddTag("scorpion")
    inst:AddTag("canbetrapped")

    MakeCharacterPhysics(inst, 10, 0.5)
    MakePoisonableCharacter(inst)

    inst.AnimState:SetBank("scorpion")
    inst.AnimState:SetBuild("scorpion_build")
    inst.AnimState:PlayAnimation("idle")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    -- locomotor must be constructed before the stategraph!
    inst:AddComponent("locomotor")
    inst.components.locomotor.walkspeed = TUNING.SCORPION_WALK_SPEED
    inst.components.locomotor.runspeed = TUNING.SCORPION_RUN_SPEED

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetChanceLootTable("scorpion")

    inst:AddComponent("follower")

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(TUNING.SCORPION_HEALTH)

    inst:AddComponent("combat")
    inst.components.combat.hiteffectsymbol = "scorpion_body"
    inst.components.combat:SetKeepTargetFunction(KeepTargetFn)
    inst.components.combat:SetDefaultDamage(TUNING.SCORPION_DAMAGE)
    inst.components.combat:SetAttackPeriod(TUNING.SCORPION_ATTACK_PERIOD)
    inst.components.combat:SetRetargetFunction(1, RetargetFn)
    inst.components.combat:SetHurtSound("dontstarve/creatures/spider/hit_response")
    inst.components.combat:SetRange(TUNING.SCORPION_ATTACK_RANGE, TUNING.SCORPION_ATTACK_RANGE)

    inst:AddComponent("sleeper")
    inst.components.sleeper:SetResistance(2)
    inst.components.sleeper:SetSleepTest(function() return false end)
    inst.components.sleeper:SetWakeTest(function() return true end)

    inst:AddComponent("knownlocations")

    inst:AddComponent("eater")
    inst.components.eater:SetDiet({FOODTYPE.MEAT}, {FOODTYPE.MEAT})
    inst.components.eater:SetCanEatHorrible()
    inst.components.eater.strongstomach = true -- can eat monster meat!

    inst:AddComponent("inspectable")

    inst:AddComponent("sanityaura")
    inst.components.sanityaura.aura = -TUNING.SANITYAURA_SMALL

    MakeMediumBurnableCharacter(inst, "scorpion_body")
    MakeMediumFreezableCharacter(inst, "scorpion_body")
    inst.components.burnable.flammability = TUNING.SCORPION_FLAMMABILITY

    inst:SetBrain(brain)
    inst:SetStateGraph("SGscorpion")

    inst:ListenForEvent("attacked", OnAttacked)

    return inst
end

return Prefab("scorpion", fn, assets, prefabs)
