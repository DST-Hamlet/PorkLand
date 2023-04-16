local assets =
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

local brain = require("brains/rabid_beetlebrain")

local function ShouldSleep(inst)
    return not TheWorld.state.isday and StandardSleepChecks(inst)
end

local function OnDropped(inst)
    inst.components.lootdropper:SetChanceLootTable('rabid_beetle')
    inst.sg:GoToState("idle")
end

local function OnPickedUp(inst)
    inst.components.lootdropper:SetChanceLootTable('rabid_beetle_inventory')
end

local CANT_TAGS = {"FX", "NOCLICK", "INLIMBO", "wall", "rabid_beetle", "glowfly", "cocoon", "structure"}
local function RetargetFn(inst)
    return FindEntity(inst, TUNING.RABID_BEETLE_TARGET_DIST, function(guy)
        return inst.components.combat:CanTarget(guy)
    end, nil, CANT_TAGS)
end

local function KeepTarget(inst, target)
    return inst.components.combat:CanTarget(target) and
        inst:IsValid() and target:IsValid() and
        inst:IsNear(target, TUNING.RABID_BEETLE_FOLLOWER_TARGET_KEEP)
end

local function OnNewTarget(inst, data)
    if inst.components.sleeper:IsAsleep() then
        inst.components.sleeper:WakeUp()
    end
end

local SHARE_TARGET_DIST = 30
local function OnAttacked(inst, data)
    if data and data.attacker then
        inst.components.combat:SetTarget(data.attacker)
        inst.components.combat:ShareTarget(data.attacker, SHARE_TARGET_DIST, function(dude) return dude:HasTag("rabid_beetle") and not dude.components.health:IsDead() end, 5)
    end
end

local function OnAttackOther(inst, data)
    if data and data.target then
        inst.components.combat:ShareTarget(data.target, SHARE_TARGET_DIST, function(dude) return dude:HasTag("rabid_beetle") and not dude.components.health:IsDead() end, 5)
    end
end

local function OnTimerDone(inst, data)
    if data and data.name == "endlife" then
        inst.components.health:Kill()
    end
end

local function OnChangeArea(inst, data)
    if data and data.tags and table.contains(data.tags, "Gas_Jungle") then
    	if inst.components.poisonable then
            inst.components.poisonable:Poison(true, nil, 30)
        end
    end
end

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddDynamicShadow()
    inst.entity:AddNetwork()

    inst:AddTag("scarytoprey")
    inst:AddTag("monster")
    inst:AddTag("animal")
    inst:AddTag("insect")
    inst:AddTag("hostile")
    inst:AddTag("rabid_beetle")
    inst:AddTag("canbetrapped")
    inst:AddTag("smallcreature")

    MakeCharacterPhysics(inst, 5, .5)

    inst.DynamicShadow:SetSize(2.5, 1.5)

    inst.Transform:SetFourFaced()
    inst.Transform:SetScale(0.6, 0.6, 0.6)

    inst.AnimState:SetBank("rabid_beetle")
    inst.AnimState:SetBuild("rabid_beetle")
    inst.AnimState:PlayAnimation("idle")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("drownable")
    inst:AddComponent("areaaware")
    inst:AddComponent("inspectable")
    -- inst:AddComponent("follower")

    -- locomotor must be constructed before the stategraph!
    inst:AddComponent("locomotor")
    inst.components.locomotor.runspeed = TUNING.RABID_BEETLE_SPEED
    inst.components.locomotor:SetAllowPlatformHopping(true)

    inst:AddComponent("embarker")
    inst.components.embarker.embark_speed = inst.components.locomotor.runspeed + 2

    inst:AddComponent("sanityaura")
    inst.components.sanityaura.aura = -TUNING.SANITYAURA_MED

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetChanceLootTable('rabid_beetle')

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(TUNING.RABID_BEETLE_HEALTH)
    inst.components.health.murdersound = "dontstarve_DLC003/creatures/enemy/rabid_beetle/death"

    inst:AddComponent("eater")
    -- inst.components.eater:SetCarnivore()
    inst.components.eater:SetDiet({FOODTYPE.MEAT}, {FOODTYPE.MEAT})
    inst.components.eater:SetCanEatHorrible()
    inst.components.eater:SetStrongStomach(true)  -- can eat monster meat!

    inst:AddComponent("sleeper")
    inst.components.sleeper:SetResistance(3)
    inst.components.sleeper.testperiod = GetRandomWithVariance(6, 2)
    inst.components.sleeper:SetSleepTest(ShouldSleep)

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem:SetOnDroppedFn(OnDropped)
    inst.components.inventoryitem:SetOnPutInInventoryFn(OnPickedUp)
    inst.components.inventoryitem.canbepickedup = false
    inst.components.inventoryitem.canbepickedupalive = false
    inst.components.inventoryitem.nobounce = true

    inst:AddComponent("combat")
    inst.components.combat:SetDefaultDamage(TUNING.RABID_BEETLE_DAMAGE)
    inst.components.combat:SetAttackPeriod(TUNING.RABID_BEETLE_ATTACK_PERIOD)
    inst.components.combat:SetRetargetFunction(3, RetargetFn)
    inst.components.combat:SetKeepTargetFunction(KeepTarget)
    inst.components.combat:SetRange(2)
    inst.components.combat:SetHurtSound("dontstarve_DLC003/creatures/enemy/rabid_beetle/hurt")

    inst:AddComponent("timer")
    inst.components.timer:StartTimer("endlife", TUNING.TOTAL_DAY_TIME + (3 * math.random() - 2) * TUNING.SEG_TIME)

    inst:SetStateGraph("SGrabid_beetle")
    inst:SetBrain(brain)

    inst:ListenForEvent("newcombattarget", OnNewTarget)
    inst:ListenForEvent("attacked", OnAttacked)
    inst:ListenForEvent("onattackother", OnAttackOther)
    inst:ListenForEvent("timerdone", OnTimerDone)
    inst:ListenForEvent("changearea", OnChangeArea)

    MakeHauntablePanic(inst)
    MakePoisonableCharacter(inst, "bottom")
    MakeMediumFreezableCharacter(inst, "bottom")
    MakeMediumBurnableCharacter(inst, "bottom")

    return inst
end

return Prefab("rabid_beetle", fn, assets, prefabs)
