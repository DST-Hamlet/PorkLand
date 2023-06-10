require "brains/snakebrain"
require "stategraphs/SGsnake"

local trace = function() end

local assets=
{
	Asset("ANIM", "anim/snake_build.zip"),
	Asset("ANIM", "anim/snake_yellow_build.zip"),
	Asset("ANIM", "anim/snake_basic.zip"),
	Asset("ANIM", "anim/snake_water.zip"),
	Asset("ANIM", "anim/snake_scaly_build.zip"),
	Asset("ANIM", "anim/dragonfly_fx.zip"),
	Asset("SOUND", "sound/hound.fsb"),
}

local prefabs =
{
	"monstermeat",
	"snakeskin",
	"venomgland",
	"obsidian",
	"ash",
	"charcoal",
	--"vomitfire_fx",
	"firesplash_fx",
	"firering_fx",
	"lavaspit",
	"snakeoil",
}

local sounds = {
	default = {
		idle = "dontstarve_DLC002/creatures/snake/idle",
		pre_attack = "dontstarve_DLC002/creatures/snake/pre-attack",
		attack = "dontstarve_DLC002/creatures/snake/attack",
		hurt = "dontstarve_DLC002/creatures/snake/hurt",
		taunt = "dontstarve_DLC002/creatures/snake/taunt",
		death = "dontstarve_DLC002/creatures/snake/death",
		sleep = "dontstarve_DLC002/creatures/snake/sleep",
		move = "dontstarve_DLC002/creatures/snake/move",
	},
	amphibious = {
		idle = "dontstarve_DLC002/creatures/snake/idle",
		pre_attack = "dontstarve_DLC002/creatures/snake/pre-attack",
		attack = "dontstarve_DLC002/creatures/snake/attack",
		hurt = "dontstarve_DLC002/creatures/snake/hurt",
		taunt = "dontstarve_DLC002/creatures/snake/taunt",
		death = "dontstarve_DLC002/creatures/snake/death",
		sleep = "dontstarve_DLC002/creatures/snake/sleep",
		move = "dontstarve_DLC002/creatures/snake/move",
	},
}

local SHARE_TARGET_DIST = 30

local function ShouldSleep(inst)
	local near_home_dist = 40
	local has_home_near = inst.components.homeseeker and
					 inst.components.homeseeker.home and
					 inst.components.homeseeker.home:IsValid() and
					 inst:GetDistanceSqToInst(inst.components.homeseeker.home) < near_home_dist*near_home_dist

    return
		TheWorld.state.isday
        and not (inst.components.combat and inst.components.combat.target)
        and not (inst.components.burnable and inst.components.burnable:IsBurning() )
        and not (inst.components.freezable and inst.components.freezable:IsFrozen() )
        and not (inst.components.teamattacker and inst.components.teamattacker.inteam)
        and not inst.sg:HasStateTag("busy")
        and not has_home_near
		and not inst:HasTag("attackingbreeder")
end

local function OnNewTarget(inst, data)
	if inst.components.sleeper:IsAsleep() then
		inst.components.sleeper:WakeUp()
	end
end


local function retargetfn(inst)
	local dist = TUNING.SNAKE_TARGET_DIST
	local notags = {"FX", "NOCLICK","INLIMBO", "wall", "snake", "structure"}
	return FindEntity(inst, dist, function(guy)
		return  inst.components.combat:CanTarget(guy) and (not guy:HasTag("aquatic") or inst:HasTag("snake_amphibious"))
	end, nil, notags)
end

local function KeepTarget(inst, target)
	return inst.components.combat:CanTarget(target) and inst:GetDistanceSqToInst(target) <= (TUNING.SNAKE_KEEP_TARGET_DIST*TUNING.SNAKE_KEEP_TARGET_DIST) and (not target:HasTag("aquatic") or inst:HasTag("snake_amphibious"))
end

local function OnAttacked(inst, data)
	inst.components.combat:SetTarget(data.attacker)
	inst.components.combat:ShareTarget(data.attacker, SHARE_TARGET_DIST, function(dude) return dude:HasTag("snake")and not dude.components.health:IsDead() end, 5)
end

local function OnAttackOther(inst, data)
	inst.components.combat:ShareTarget(data.target, SHARE_TARGET_DIST, function(dude) return dude:HasTag("snake") and not dude.components.health:IsDead() end, 5)
end

local function DoReturn(inst)
	--print("DoReturn", inst)
	if inst.components.homeseeker then
		inst.components.homeseeker:ForceGoHome()
	end
end

local function OnDay(inst)
	--print("OnNight", inst)
	if inst:IsAsleep() then
		DoReturn(inst)
	end
end


local function OnEntitySleep(inst)
	--print("OnEntitySleep", inst)
	if GetClock():IsDay() then
		DoReturn(inst)
	end
end

local function OnSave(inst, data)
end

local function OnLoad(inst, data)
end

local function SanityAura(inst, observer)

    if observer.prefab == "webber" then
        return 0
    end

    return -TUNING.SANITYAURA_SMALL
end

local function OnWaterChange(inst, onwater)
    if onwater then
        inst.onwater = true
        inst.DynamicShadow:Enable(false)
    else
        inst.onwater = false
        inst.DynamicShadow:Enable(true)
    end

	local noanim = inst:GetTimeAlive() < 1
	inst.sg:GoToState(onwater and "submerge" or "emerge", noanim)
end

local function OnEntityWake(inst)
	if inst.components.tiletracker then
		inst.components.tiletracker:Start()
	end
end

local function OnEntitySleep(inst)
	if inst.components.tiletracker then
		inst.components.tiletracker:Stop()
	end
end

local function fn(Sim)
	local inst = CreateEntity()
	local trans = inst.entity:AddTransform()
	local anim = inst.entity:AddAnimState()
	local physics = inst.entity:AddPhysics()
	local sound = inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()
	--local shadow = inst.entity:AddDynamicShadow()
	--shadow:SetSize( 2.5, 1.5 )
	inst.Transform:SetFourFaced()

	inst:AddTag("scarytoprey")
	inst:AddTag("monster")
	inst:AddTag("hostile")
	inst:AddTag("snake")
	inst:AddTag("animal")
	inst:AddTag("canbetrapped")

	MakeCharacterPhysics(inst, 10, .5)

	anim:SetBank("snake")
	anim:SetBuild("snake_build")
	anim:PlayAnimation("idle")
	inst.AnimState:SetRayTestOnBB(true)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

	inst:AddComponent("knownlocations")

	inst:AddComponent("locomotor") -- locomotor must be constructed before the stategraph
	inst.components.locomotor.runspeed = TUNING.SNAKE_SPEED

	inst:SetStateGraph("SGsnake")

	local brain = require "brains/snakebrain"
	inst:SetBrain(brain)

	inst:AddComponent("follower")

    inst:AddComponent("eater")
    inst.components.eater:SetDiet({ FOODTYPE.MEAT }, { FOODTYPE.MEAT })
    inst.components.eater:SetCanEatHorrible()
    inst.components.eater:SetStrongStomach(true) -- can eat monster meat!
    inst.components.eater:SetCanEatRawMeat(true)

	inst.components.eater.strongstomach = true -- can eat monster meat!

	inst:AddComponent("health")
	inst.components.health:SetMaxHealth(TUNING.SNAKE_HEALTH)
	inst.components.health.poison_damage_scale = 0 -- immune to poison


	inst:AddComponent("combat")
	inst.components.combat:SetDefaultDamage(TUNING.SNAKE_DAMAGE)
	inst.components.combat:SetAttackPeriod(TUNING.SNAKE_ATTACK_PERIOD)
	inst.components.combat:SetRetargetFunction(3, retargetfn)
	inst.components.combat:SetKeepTargetFunction(KeepTarget)
	inst.components.combat:SetHurtSound("dontstarve_DLC002/creatures/snake/hurt")
	inst.components.combat:SetRange(2,3)

	inst:AddComponent("lootdropper")
	inst.components.lootdropper:AddRandomLoot("monstermeat", 1.00)
	inst.components.lootdropper:AddRandomLoot("snakeskin", 0.50)
	inst.components.lootdropper:AddRandomLoot("snakeoil", 0.01)
	inst.components.lootdropper.numrandomloot = math.random(0,1)

	inst:AddComponent("inspectable")

	inst:AddComponent("sanityaura")
	inst.components.sanityaura.aurafn = SanityAura

	inst:AddComponent("sleeper")
	inst.components.sleeper:SetNocturnal(true)
	--inst.components.sleeper:SetResistance(1)
	-- inst.components.sleeper.testperiod = GetRandomWithVariance(6, 2)
	-- inst.components.sleeper:SetWakeTest(ShouldWakeUp)
	inst.components.sleeper:SetSleepTest(ShouldSleep)
	inst:ListenForEvent("newcombattarget", OnNewTarget)

	-- inst:ListenForEvent( "dusktime", function() OnNight( inst ) end, GetWorld())
	-- inst:ListenForEvent( "nighttime", function() OnNight( inst ) end, GetWorld())
	-- inst:ListenForEvent( "daytime", function() OnDay( inst ) end, GetWorld())
	inst.OnEntitySleep = OnEntitySleep

	inst.OnSave = OnSave
	inst.OnLoad = OnLoad


	inst.OnEntityWake = OnEntityWake
	inst.OnEntitySleep = OnEntitySleep

	inst:ListenForEvent("attacked", OnAttacked)
	inst:ListenForEvent("onattackother", OnAttackOther)

	MakeMediumFreezableCharacter(inst, "hound_body")

	return inst
end

local function commonfn(Sim)
	local inst = fn(Sim)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

	MakePoisonableCharacter(inst)
	MakeMediumBurnableCharacter(inst, "hound_body")
	inst.sounds = sounds.default
	return inst
end

local function poisonfn(Sim)
	local inst = fn(Sim)

	inst.AnimState:SetBuild("snake_yellow_build")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

	inst:AddTag("poisonous")
	inst.components.combat.poisonous = true
	inst.components.lootdropper:AddRandomLoot("venomgland", 1.00)
	inst.sounds = sounds.default
	MakeMediumBurnableCharacter(inst, "hound_body")

	return inst
end

local function firefn(Sim)
	local inst = fn(Sim)

	inst.AnimState:SetBuild("snake_yellow_build")
    inst:AddTag("lavaspitter")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

	inst.last_spit_time = nil
    inst.last_target_spit_time = nil
    inst.spit_interval = math.random(20,30)
    inst.num_targets_vomited = 0

	inst.components.health.fire_damage_scale = 0

	--inst:AddTag("poisonous")
	inst.components.lootdropper.numrandomloot = 3
	inst.components.lootdropper:AddRandomLoot("obsidian", .25)
	inst.components.lootdropper:AddRandomLoot("ash", .25)
	inst.components.lootdropper:AddRandomLoot("charcoal", .25)
	inst.sounds = sounds.default
	MakeLargePropagator(inst)
    inst.components.propagator.decayrate = 0

	return inst
end

local function amphibiousfn(Sim)
	local inst = fn(Sim)

	local shadow = inst.entity:AddDynamicShadow()
	inst:AddTag("amphibious")
	inst:AddTag("snake_amphibious")
    inst:AddTag("breederpredator")
	MakeFlyingCharacterPhysics(inst, 1, .5)
	inst.AnimState:SetBuild("snake_scaly_build")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

	inst:AddComponent("tiletracker")
	inst.components.tiletracker:SetOnWaterChangeFn(OnWaterChange)

	inst.sounds = sounds.amphibious

	MakeMediumBurnableCharacter(inst, "hound_body")

	return inst
end

return Prefab("monsters/snake", commonfn, assets, prefabs),
	   Prefab("monsters/snake_poison", poisonfn, assets, prefabs),
	   Prefab("monsters/snake_fire", firefn, assets, prefabs),
	   Prefab("monsters/snake_amphibious", amphibiousfn, assets, prefabs)
	  -- Prefab("monsters/deadsnake", fndefault, assets, prefabs),

