local assets=
{
    Asset("ANIM", "anim/venus_flytrap_sm_build.zip"),
    Asset("ANIM", "anim/venus_flytrap_ml_build.zip"),
    Asset("ANIM", "anim/venus_flytrap_build.zip"),
    Asset("ANIM", "anim/venus_flytrap.zip"),
}

local prefabs =
{
    "plantmeat",
    "vine",
    "nectar_pod",
    "adult_flytrap",
}

SetSharedLootTable("mean_flytrap",
{
    {"plantmeat",   1.0},
    {"vine",        0.5},
    {"nectar_pod",  0.3},
})

local function findfood(inst, target)
    if not target.components.inventory then
        return
    end

    return target.components.inventory:FindItem(function(item)
        return inst.components.eater:CanEat(item)
    end)
end

local RETARGET_DIST = 8
local RETARGET_NO_TAGS = {"FX", "NOCLICK", "INLIMBO", "wall", "flytrap", "structure", "aquatic", "notarget"}

local function RetargetFn(inst)
    return FindEntity(inst, RETARGET_DIST, function(ent)
        if (ent:HasTag("plantkin") and not findfood(inst, ent)) then
            return false
        end

        return inst.components.combat:CanTarget(ent)
    end, nil, RETARGET_NO_TAGS)
end

local KEEP_TAGET_DIST = 15
local function KeepTargetFn(inst, target)
    if not inst.keeptargetevenifnofood
        and (target:HasTag("plantkin") and not findfood(inst,target)) then
        return false
    end

    return inst.components.combat:CanTarget(target) and inst:GetDistanceSqToInst(target) <= KEEP_TAGET_DIST * KEEP_TAGET_DIST and not target:HasTag("aquatic")
end

local function OnAttacked(inst, data)
    inst.components.combat:SetTarget(data.attacker)
    inst.keeptargetevenifnofood = true
end

local function OnNewTarget(inst, data)
    inst.keeptargetevenifnofood = nil
    if inst.components.sleeper and inst.components.sleeper:IsAsleep() then
        inst.components.sleeper:WakeUp()
    end
end

local growth_stages = {
    [2] = {
        scale = 1.2,
        start_scale = 1,
        new_build = "venus_flytrap_build",
        name = "FLYTRAP_TEEN_",
    },
    [3] = {
        scale = 1.4,
        start_scale = 1.2,
        new_build = "venus_flytrap_ml_build",
        name = "FLYTRAP_",
    }
}

local function SetStage(inst, stage, instant)
    if inst.components.health and inst.components.health:IsDead() then
        return
    end

    if not stage then
        return
    end

    if stage <= 1 then
        return
    end

    if stage >= 4 then
        ReplacePrefab(inst, "adult_flytrap")
        return
    end

    if instant then
        local scale = growth_stages[stage].scale
        inst.Transform:SetScale(scale, scale, scale)
        inst.AnimState:SetBuild(growth_stages[stage].new_build)
    else
        inst.new_build = growth_stages[stage].new_build
        inst.start_scale = growth_stages[stage].start_scale

        inst.inc_scale = (growth_stages[stage].scale - growth_stages[stage].start_scale) / 5
        inst.sg:GoToState("grow")
    end

    inst:RemoveTag("usefastrun")

    inst.components.combat:SetDefaultDamage(TUNING[growth_stages[stage].name .. "DAMAGE"])
    inst.components.health:SetMaxHealth(TUNING[growth_stages[stage].name .. "HEALTH"])
    inst.components.locomotor.runspeed = TUNING[growth_stages[stage].name .. "SPEED"]

    inst.components.health:DoDelta(50)
end

local function OnEat(inst, food)
    -- If we're not an adult
    if inst.stage < 4 then
        inst:DoTaskInTime(0.5, function()
            inst.stage = inst.stage + 1
            SetStage(inst, inst.stage)
        end)
    end
end

local function OnEntitySleep(inst)
    if TheWorld.state.isday then
        if inst.components.homeseeker then -- #FIXME no homeseeker?
            inst.components.homeseeker:ForceGoHome()
        end
    end
end

local function OnSave(inst, data)
    if inst.stage then
        data.stage = inst.stage
    end
end

local function OnLoad(inst, data)
    if not data then
        return
    end

    inst.stage = data.stage or 1
    SetStage(inst, inst.stage, true)
end

local function SanityAura(inst, observer)
    return not observer:HasTag("plantkin") and -TUNING.SANITYAURA_SMALL or 0
end

local function ShouldSleep(inst)
    return NocturnalSleepTest(inst)
    and not (inst:GetBufferedAction() and inst:GetBufferedAction().action == ACTIONS.EAT)
end

local function ShouldWake(inst)
    return NocturnalWakeTest(inst)
end

local brain = require("brains/flytrapbrain")

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddDynamicShadow()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("venus_flytrap")
    inst.AnimState:SetBuild("venus_flytrap_sm_build")
    inst.AnimState:PlayAnimation("idle")
    inst.AnimState:Hide("dirt")

    inst.DynamicShadow:SetSize(2.5, 1.5)

    inst.Transform:SetFourFaced()

    inst:AddTag("character")
    inst:AddTag("scarytoprey")
    inst:AddTag("monster")
    inst:AddTag("flytrap")
    inst:AddTag("hostile")
    inst:AddTag("animal")
    inst:AddTag("usefastrun")
    inst:AddTag("plantcreature")

    MakeCharacterPhysics(inst, 10, .5)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("follower")

    inst:AddComponent("knownlocations")

    inst:AddComponent("inspectable")

    inst:AddComponent("locomotor") -- locomotor must be constructed before the stategraph
    inst.components.locomotor.runspeed = TUNING.FLYTRAP_CHILD_SPEED

    inst:AddComponent("eater")
    inst.components.eater:SetDiet({FOODTYPE.MEAT}, {FOODTYPE.MEAT})
    inst.components.eater:SetCanEatHorrible()
    inst.components.eater:SetCanEatRaw()
    inst.components.eater:SetStrongStomach(true) -- can eat monster meat!
    inst.components.eater:SetOnEatFn(OnEat)

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(TUNING.FLYTRAP_CHILD_HEALTH)

    inst:AddComponent("combat")
    inst.components.combat:SetDefaultDamage(TUNING.FLYTRAP_CHILD_DAMAGE)
    inst.components.combat:SetAttackPeriod(TUNING.FLYTRAP_ATTACK_PERIOD)
    inst.components.combat:SetRetargetFunction(3, RetargetFn)
    inst.components.combat:SetKeepTargetFunction(KeepTargetFn)
    inst.components.combat:SetRange(2, 3)

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetChanceLootTable("mean_flytrap")

    inst:AddComponent("sanityaura")
    inst.components.sanityaura.aurafn = SanityAura

    inst:AddComponent("sleeper")
    inst.components.sleeper:SetResistance(2)
    inst.components.sleeper:SetSleepTest(ShouldSleep)
    inst.components.sleeper:SetWakeTest(ShouldWake)

    inst:SetBrain(brain)
    inst:SetStateGraph("SGflytrap")

    MakeHauntablePanic(inst)
    MakeMediumFreezableCharacter(inst, "stem")
    MakeMediumBurnableCharacter(inst, "stem")

    inst:ListenForEvent("newcombattarget", OnNewTarget)
    inst:ListenForEvent("attacked", OnAttacked)

    inst.stage = 1
    inst.OnEntitySleep = OnEntitySleep
    inst.OnSave = OnSave
    inst.OnLoad = OnLoad

    return inst
end

return Prefab("mean_flytrap", fn, assets, prefabs)
