require "brains/rabid_beetlebrain"
require "stategraphs/SGrabid_beetle"

local assets=
{
	Asset("ANIM", "anim/rabid_beetle.zip"),
}

local prefabs =
{
	"chitin",
    "lightbulb",
}

SetSharedLootTable('rabid_beetle',
{
    {'chitin', 0.2},
    {'lightbulb', 0.08},
})

SetSharedLootTable('rabid_beetle_inventory',
{
    {'lightbulb', 1},
    {'chitin', 0.6},
})

local WAKE_TO_FOLLOW_DISTANCE = 8
local SLEEP_NEAR_HOME_DISTANCE = 10
local SHARE_TARGET_DIST = 30

local function ShouldWakeUp(inst)
    return DefaultWakeTest(inst) or (inst.components.follower and inst.components.follower.leader and not inst.components.follower:IsNearLeader(WAKE_TO_FOLLOW_DISTANCE))
end

local function ShouldSleep(inst)
    return not TheWorld.state.isday
    and not (inst.components.combat ~= nil and inst.components.combat.target)
    and not (inst.components.burnable ~= nil and inst.components.burnable:IsBurning() )
    and (not inst.components.homeseeker ~= nil or inst:IsNear(inst.components.homeseeker.home, SLEEP_NEAR_HOME_DISTANCE))
end

local function OnNewTarget(inst, data)
    if inst.components.sleeper:IsAsleep() then
        inst.components.sleeper:WakeUp()
    end
end

local function RetargetFn(inst)
    local dist = TUNING.RABID_BEETLE_TARGET_DIST
    local CANT_TAGS = {"FX", "NOCLICK","INLIMBO", "wall", "rabid_beetle","glowfly", "cocoon", "structure", "aquatic"}
    return FindEntity(inst, dist, function(guy)
		local shouldtarget = inst.components.combat:CanTarget(guy)
        return shouldtarget
    end, nil, CANT_TAGS)
end

local function KeepTarget(inst, target)
    local shouldkeep = inst.components.combat:CanTarget(target) and inst:IsNear(target, TUNING.RABID_BEETLE_FOLLOWER_TARGET_KEEP)
    return shouldkeep
end

local function OnAttacked(inst, data)
    inst.components.combat:SetTarget(data.attacker)
    inst.components.combat:ShareTarget(data.attacker, SHARE_TARGET_DIST, function(dude) return dude:HasTag("rabid_beetle") and not dude.components.health:IsDead() end, 5)
end

local function OnAttackOther(inst, data)
    inst.components.combat:ShareTarget(data.target, SHARE_TARGET_DIST, function(dude) return dude:HasTag("rabid_beetle") and not dude.components.health:IsDead() end, 5)
end

local function DoReturn(inst)
    if inst.components.homeseeker ~= nil and inst.components.homeseeker:HasHome()  then
        if inst.components.homeseeker.home.components.childspawner then
            inst.components.homeseeker.home.components.childspawner:GoHome(inst)
        end
    end
end

local function OnEntitySleep(inst)
    if not TheWorld.state.isday then
        DoReturn(inst)
    end
end

local function StartLifespan(inst, time)
    if not time then
        time = TUNING.TOTAL_DAY_TIME + (math.random()*3*TUNING.SEG_TIME) - (2*TUNING.SEG_TIME)
    end
    if inst.task then
        inst.task:Cancel()
        inst.task = nil
    end
    inst.task, inst.taskinfo = inst:ResumeTask(time, function()
        inst.components.health:Kill()
    end)
end

local function OnSave(inst, data)
    if inst.taskinfo ~= nil then
        data.timeleft = inst:TimeRemainingInTask(inst.taskinfo)
    end
end

local function OnLoad(inst, data)
    if data.timeleft ~= nil then
        StartLifespan(inst, data.timeleft)
    end
end

local function OnLongUpdate(inst, dt)
    if inst.taskinfo ~= nil then
        local timeleft = inst:TimeRemainingInTask(inst.taskinfo)
        timeleft = math.max(timeleft - dt,0)
        if timeleft then
            StartLifespan(inst, timeleft)
        end
    end
end

local function OnDropped(inst)
    inst.components.lootdropper:SetChanceLootTable('rabid_beetle')
    inst.sg:GoToState("idle")

    if inst.brain ~= nil then
        inst.brain:Start()
    end
    if inst.sg ~= nil then
        inst.sg:Start()
    end
end

local function OnPickedUp(inst)
    inst.components.lootdropper:SetChanceLootTable('rabid_beetle_inventory')
end

local function fncommon()
	local inst = CreateEntity()
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddDynamicShadow()
    inst.entity:AddNetwork()

    inst.DynamicShadow:SetSize( 2.5, 1.5 )
    inst.Transform:SetFourFaced()

	inst:AddTag("scarytoprey")
    inst:AddTag("monster")
    inst:AddTag("animal")
    inst:AddTag("insect")
    inst:AddTag("hostile")
    inst:AddTag("rabid_beetle")
    inst:AddTag("canbetrapped")
    inst:AddTag("smallcreature")

    MakeCharacterPhysics(inst, 5, .5)

    inst.Transform:SetScale(0.6,0.6,0.6)

    inst.AnimState:SetBank("rabid_beetle")
    inst.AnimState:SetBuild("rabid_beetle")
    inst.AnimState:PlayAnimation("idle")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")
    inst:AddComponent("follower")

    -- 需不需要上船呢？
    inst:AddComponent("locomotor")
    inst.components.locomotor.runspeed = TUNING.RABID_BEETLE_SPEED

    inst:AddComponent("sanityaura")
    inst.components.sanityaura.aura = -TUNING.SANITYAURA_MED

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetChanceLootTable('rabid_beetle')

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(TUNING.RABID_BEETLE_HEALTH)
    inst.components.health.murdersound = "pl/creatures/enemy/rabid_beetle/death"

    inst:AddComponent("eater")
    -- inst.components.eater:SetCarnivore()
    inst.components.eater:SetDiet({FOODTYPE.MEAT}, {FOODTYPE.MEAT})
	inst.components.eater:SetCanEatHorrible()
    inst.components.eater.strongstomach = true -- can eat monster meat!

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem:SetOnDroppedFn(OnDropped)
    inst.components.inventoryitem:SetOnPutInInventoryFn(OnPickedUp)
    inst.components.inventoryitem.canbepickedup = false

    inst:AddComponent("combat")
    inst.components.combat:SetDefaultDamage(TUNING.RABID_BEETLE_DAMAGE)
    inst.components.combat:SetAttackPeriod(TUNING.RABID_BEETLE_ATTACK_PERIOD)
    inst.components.combat:SetRetargetFunction(3, RetargetFn)
    inst.components.combat:SetKeepTargetFunction(KeepTarget)
    inst.components.combat:SetRange(2)
    inst.components.combat:SetHurtSound("pl/creatures/enemy/rabid_beetle/hurt")

    inst:AddComponent("sleeper")
    inst.components.sleeper:SetResistance(3)
    inst.components.sleeper.testperiod = GetRandomWithVariance(6, 2)
    inst.components.sleeper:SetSleepTest(ShouldSleep)
    inst.components.sleeper:SetWakeTest(ShouldWakeUp)

    inst:SetStateGraph("SGrabid_beetle")
    local brain = require "brains/rabid_beetlebrain"
    inst:SetBrain(brain)

    inst.OnEntitySleep = OnEntitySleep
    inst.OnSave = OnSave
    inst.OnLoad = OnLoad
    inst.OnLongUpdate = OnLongUpdate

    MakeHauntablePanic(inst)
    MakePoisonableCharacter(inst)
    MakeMediumFreezableCharacter(inst, "bottom")
    MakeMediumBurnableCharacter(inst, "bottom")

    inst:ListenForEvent("newcombattarget", OnNewTarget)
    inst:ListenForEvent("attacked", OnAttacked)
    inst:ListenForEvent("onattackother", OnAttackOther)

    StartLifespan(inst)

    return inst
end

return Prefab("rabid_beetle", fncommon, assets, prefabs)
