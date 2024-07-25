local assets =
{
    Asset("ANIM", "anim/pog_basic.zip"),
    Asset("ANIM", "anim/pog_actions.zip"),
    Asset("ANIM", "anim/pog_feral_build.zip"),
}

local prefabs =
{
    "smallmeat"
}

SetSharedLootTable("pog",
{
    {"smallmeat",             1.00},
})

local MAX_TARGET_SHARES = 5
local SHARE_TARGET_DIST = 30

local function OnAttacked(inst, data)
    if data and data.attacker then
        inst.components.combat:SetTarget(data.attacker)
        inst.components.combat:ShareTarget(data.attacker, SHARE_TARGET_DIST, function(ent) return ent:HasTag("pog") end, MAX_TARGET_SHARES)
    end
end

local function KeepTargetFn(inst, target)
    return (target and target.components.combat
        and (target.components.health and not target.components.health:IsDead())
        and (not target:HasTag("pog") or not (inst.components.follower and inst.components.follower:IsLeaderSame(target)))
        and not (inst.components.follower and inst.components.follower.leader == target))
end

local RETARGET_DIST = 25
local RETARGET_NO_TAGS = {"FX", "NOCLICK","INLIMBO", "wall", "pog", "structure"}
local RETARGET_ONE_OF_TASG = {"monster", "smallcreature"}

local function RetargetFn(inst)
    if TheWorld.state.isaporkalypse then
        local x, y, z = inst.Transform:GetWorldPosition()
        local player = FindClosestPlayerInRange(x, y, z, 15, true)
        if player then
            return player
        end
    end

    return FindEntity(inst, RETARGET_DIST, function(ent)
        return 	(ent.components.health and not ent.components.health:IsDead() and inst.components.combat:CanTarget(ent))
            and not (inst.components.follower and inst.components.follower:IsLeaderSame(ent))
        end, nil, RETARGET_NO_TAGS, RETARGET_ONE_OF_TASG)
end

local function SleepTest(inst)
    if (inst.components.follower and inst.components.follower.leader)
        or (inst.components.combat and inst.components.combat.target)
        or inst.components.playerprox:IsPlayerClose() then
        return false
    end

    if not inst.sg:HasStateTag("busy") and (not inst.last_wake_time or GetTime() - inst.last_wake_time >= inst.nap_interval) then
        inst.nap_length = math.random(TUNING.MIN_POGNAP_LENGTH, TUNING.MAX_POGNAP_LENGTH)
        inst.last_sleep_time = GetTime()
        return true
    end
end

local function WakeTest(inst)
    if not inst.last_sleep_time or GetTime() - inst.last_sleep_time >= inst.nap_length then
        inst.nap_interval = math.random(TUNING.MIN_POGNAP_INTERVAL, TUNING.MAX_POGNAP_INTERVAL)
        inst.last_wake_time = GetTime()
        return true
    end
end

local function ShouldAcceptItem(inst, item)
    if inst.components.health:IsDead() then
        return false
    end

    if item.components.edible then
        return inst.components.eater:CanEat(item)
    end

    return false
end

local function OnGetItemFromPlayer(inst, giver, item)
    if inst.components.sleeper:IsAsleep() then
        inst.components.sleeper:WakeUp()
    else
        if inst.components.combat.target and inst.components.combat.target == giver then
            inst.components.combat:SetTarget(nil)
            inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/catcoon/pickup")
        elseif giver.components.leader then
            inst.SoundEmitter:PlaySound("dontstarve/common/makeFriend")
            giver.components.leader:AddFollower(inst)
            inst.components.follower:AddLoyaltyTime(TUNING.POG_LOYALTY_PER_ITEM)
        end
    end
end

local function OnRefuseItem(inst, giver, item)
    if inst.components.sleeper:IsAsleep() then
        inst.components.sleeper:WakeUp()
    elseif not inst.sg:HasStateTag("busy") then
        inst:FacePoint(giver.Transform:GetWorldPosition())
        inst.sg:GoToState("refuse")
    end
end

local function OnAporkalypse(inst, isaporkalypse)
    if isaporkalypse then
        inst.AnimState:SetBuild("pog_feral_build")
    else
        inst.AnimState:SetBuild("pog_actions")
    end
end

local brain = require("brains/pogbrain")

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddDynamicShadow()
    inst.entity:AddNetwork()

    inst.DynamicShadow:SetSize(2, 0.75)

    inst.Transform:SetFourFaced()

    MakeCharacterPhysics(inst, 1, 0.5)
    MakePoisonableCharacter(inst)

    inst.AnimState:SetBank("pog")
    inst.AnimState:SetBuild("pog_actions")
    inst.AnimState:PlayAnimation("idle_loop")

    inst:AddTag("smallcreature")
    inst:AddTag("animal")
    inst:AddTag("pog")
    inst:AddTag("scarytoprey")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("combat")
    inst.components.combat:SetDefaultDamage(TUNING.POG_DAMAGE)
    inst.components.combat:SetRange(TUNING.POG_ATTACK_RANGE)
    inst.components.combat:SetAttackPeriod(TUNING.POG_ATTACK_PERIOD)
    inst.components.combat:SetKeepTargetFunction(KeepTargetFn)
    inst.components.combat:SetRetargetFunction(3, RetargetFn)
    inst.components.combat:SetHurtSound("dontstarve_DLC003/creatures/pog/hit")
    inst.components.combat.battlecryinterval = 20

    inst:AddComponent("eater")
    inst.components.eater:SetCanEatHorrible()
    inst.components.eater:SetDiet({FOODTYPE.MEAT, FOODTYPE.VEGGIE, FOODTYPE.GENERIC, FOODTYPE.INSECT, FOODTYPE.SEEDS, FOODTYPE.GOODIES})
    inst.components.eater:SetStrongStomach(true) -- can eat monster meat!

    inst:AddComponent("follower")
    inst.components.follower.maxfollowtime = TUNING.POG_LOYALTY_MAXTIME

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(TUNING.POG_HEALTH)

    inst:AddComponent("herdmember")
    inst.components.herdmember:SetHerdPrefab("pogherd")

    inst:AddComponent("inspectable")

    inst:AddComponent("inventory")

    inst:AddComponent("knownlocations")

    inst:AddComponent("locomotor")
    inst.components.locomotor.walkspeed = TUNING.POG_WALK_SPEED
    inst.components.locomotor.runspeed = TUNING.POG_RUN_SPEED

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetChanceLootTable("pog")

    inst:AddComponent("playerprox")
    inst.components.playerprox:SetDist(4, 6)
    inst.components.playerprox:SetOnPlayerNear(function(inst)
        inst:AddTag("can_beg")
        if inst.components.sleeper:IsAsleep() then
            inst.components.sleeper:WakeUp()
        end
    end)
    inst.components.playerprox:SetOnPlayerFar(function(inst)
        inst:RemoveTag("can_beg")
    end)

    inst:AddComponent("sleeper")
    inst.components.sleeper.testperiod = GetRandomWithVariance(6, 2)
    inst.last_sleep_time = nil
    inst.last_wake_time = GetTime()
    inst.nap_interval = math.random(TUNING.MIN_POGNAP_INTERVAL, TUNING.MAX_POGNAP_INTERVAL)
    inst.nap_length = math.random(TUNING.MIN_POGNAP_LENGTH, TUNING.MAX_POGNAP_LENGTH)
    inst.components.sleeper:SetWakeTest(WakeTest)
    inst.components.sleeper:SetSleepTest(SleepTest)

    inst:AddComponent("trader")
    inst.components.trader:SetAcceptTest(ShouldAcceptItem)
    inst.components.trader.onaccept = OnGetItemFromPlayer
    inst.components.trader.onrefuse = OnRefuseItem
    inst.components.trader.deleteitemonaccept = false

    MakeHauntablePanic(inst)
    MakeSmallBurnableCharacter(inst, "pog_chest", Vector3(1, 0, 1))
    MakeSmallFreezableCharacter(inst)

    inst:SetBrain(brain)
    inst:SetStateGraph("SGpog")

    inst:ListenForEvent("attacked", OnAttacked)
    inst:WatchWorldState("isaporkalypse", OnAporkalypse)
    OnAporkalypse(inst, TheWorld.state.isaporkalypse)

    return inst
end

return Prefab("pog", fn, assets, prefabs)
