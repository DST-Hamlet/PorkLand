local assets =
{
    Asset("ANIM", "anim/pig_bandit.zip"),
    Asset("ANIM", "anim/townspig_basic.zip"),
    Asset("ANIM", "anim/townspig_actions.zip"),
    Asset("ANIM", "anim/townspig_attacks.zip"),
    Asset("ANIM", "anim/townspig_sneaky.zip"),
}

local prefabs =
{
    "meat",
    "monstermeat",
    "poop",
    "tophat",
    "strawhat",
    "pigskin",
    "pigbanditexit",
    "banditmap",
    "bandittreasure",
    "bandithat",
}

local function OnTalk(inst, script)
    inst.SoundEmitter:PlaySound("dontstarve/pig/grunt")
end

local function OnAttacked(inst, data)
    inst:ClearBufferedAction()
    inst.attacked = true
    local attacker = data and data.attacker
    inst.components.combat:SetTarget(attacker)
end

local function FindOincs(inst)
    if inst.components.inventory then
        return inst.components.inventory:GetItemsWithTag("oinc")
    end
end

local RETARGET_DIST = 16

local function Retarget(inst)
    return FindEntity(inst, RETARGET_DIST, function(ent)
        if inst.components.combat:CanTarget(ent) and ent.components.inventory and (ent:HasTag("player") or ent.prefab == "pigman") then
            local oinks = FindOincs(ent)
            return #oinks > 0
        end

        return false
    end)
end

local function KeepTarget(inst, target)
    return inst.components.combat:CanTarget(target)
end

local function OnSave(inst, data)
    if inst.attacked then
        data.attacked = inst.attacked
    end
end

local function OnLoad(inst, data)
    if data and data.attacked then
        inst.attacked = data.attacked
    end
end

local function OnDeath(inst)
    TheWorld:PushEvent("bandit_death")
end

local function OnHitOther(inst, other, damage)
    local oincs = FindOincs(other)

    while oincs and (#oincs > 0) do
        for i, oinc in ipairs(oincs) do
            inst.components.thief:StealItem(other, oinc, false)
        end

        oincs = FindOincs(other)
    end
end

local function OnStolenItem(inst, victim, item)
    local vx, vy, vz = item.Physics:GetVelocity()
    item.components.inventoryitem:Launch(Vector3(vx, vy, vz):GetNormalized() * (12 + math.random() * 3))
end

local function OnEntitySleep(inst)
    if inst.escapetask then
        inst.escapetask:Cancel()
        inst.escapetask = nil
    end
    inst.escapetask = inst:DoTaskInTime(20, function() TheWorld:PushEvent("bandit_escaped") end)
end

local function OnEntityWake(inst)
    if inst.escapetask then
        inst.escapetask:Cancel()
        inst.escapetask = nil
    end
end

local brain = require("brains/pigbanditbrain")

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddDynamicShadow()
    inst.entity:AddLightWatcher()
    inst.entity:AddNetwork()

    MakeCharacterPhysics(inst, 50, 0.5)

    inst.AnimState:SetBank("townspig")
    inst.AnimState:SetBuild("pig_bandit")
    inst.AnimState:PlayAnimation("idle", true)
    inst.AnimState:Hide("hat")
    inst.AnimState:Hide("ARM_carry")

    inst.DynamicShadow:SetSize(1.5, 0.75)

    inst.Transform:SetFourFaced()

    inst:AddComponent("talker")
    inst.components.talker.ontalk = OnTalk
    inst.components.talker.fontsize = 35
    inst.components.talker.font = TALKINGFONT
    inst.components.talker.offset = Vector3(0, -400, 0)

    inst:AddTag("character")
    inst:AddTag("pig")
    inst:AddTag("scarytoprey")
    inst:AddTag("monster") -- this is a cheap way to get the pigs to attack on sight.
    inst:AddTag("sneaky")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("locomotor") -- locomotor must be constructed before the stategraph
    inst.components.locomotor.runspeed = TUNING.PIG_BANDIT_RUN_SPEED
    inst.components.locomotor.walkspeed = TUNING.PIG_BANDIT_WALK_SPEED

    inst:AddComponent("eater")
    inst.components.eater:SetDiet({ FOODGROUP.OMNI })
    inst.components.eater:SetCanEatHorrible()
    inst.components.eater:SetCanEatRaw()
    inst.components.eater:SetStrongStomach(true) -- can eat monster meat!

    inst:AddComponent("combat")
    inst.components.combat:SetDefaultDamage(TUNING.PIG_BANDIT_DAMAGE)
    inst.components.combat:SetAttackPeriod(TUNING.PIG_BANDIT_ATTACK_PERIOD)
    inst.components.combat:SetRetargetFunction(3, Retarget)
    inst.components.combat:SetKeepTargetFunction(KeepTarget)
    inst.components.combat.hiteffectsymbol = "torso"
    inst.components.combat:SetRange(4)
    -- inst.components.combat.hiteffectsymbol = "chest"
    inst.components.combat.onhitotherfn = OnHitOther

    inst:AddComponent("thief")
    inst.components.thief:SetOnStolenFn(OnStolenItem)

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(TUNING.PIG_HEALTH)

    inst:AddComponent("inventory")

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetLoot({"bandithat"})
    inst.components.lootdropper:AddRandomLoot("meat", 3)
    inst.components.lootdropper:AddRandomLoot("pigskin", 1)
    inst.components.lootdropper.numrandomloot = 1

    inst:AddComponent("sleeper")
    inst.components.sleeper.onlysleepsfromitems = true

    inst:AddComponent("inspectable")

    inst:AddComponent("uniqueidentity")

    MakeMediumFreezableCharacter(inst, "torso")
    MakeMediumBurnableCharacter(inst, "torso")
    MakePoisonableCharacter(inst, "torso")
    MakeHauntablePanic(inst)

    inst:SetBrain(brain)
    inst:SetStateGraph("SGpigbandit")

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad

    inst:ListenForEvent("attacked", OnAttacked)
    inst:ListenForEvent("death", OnDeath)

    inst.OnEntitySleep = OnEntitySleep
    inst.OnEntityWake = OnEntityWake

    return inst
end

return Prefab("pigbandit", fn, assets, prefabs)
