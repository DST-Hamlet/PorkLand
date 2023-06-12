require "brains/spiderbrain"
require "stategraphs/SGscorpion"

local assets =
{
	Asset("ANIM", "anim/scorpion_basic.zip"),
	Asset("ANIM", "anim/scorpion_build.zip"),
	Asset("SOUND", "sound/spider.fsb"),
}
    
    
local prefabs =
{
	"chitin",
    "monstermeat",
    "venomgland",
    "stinger",
}

SetSharedLootTable( 'scorpion',
{
    {'monstermeat',  1.00},
    {'chitin',  0.3},
    {'venomgland',  0.3},
    {'stinger',  0.3},
})


local SHARE_TARGET_DIST = 30

local function NormalRetarget(inst)
    local targetDist = TUNING.SCORPION_TARGET_DIST
    if inst.components.knownlocations:GetLocation("investigate") then
        targetDist = TUNING.SCORPION_INVESTIGATETARGET_DIST
    end
    return FindEntity(inst, targetDist, 
        function(guy) 
            if inst.components.combat:CanTarget(guy) then
                return guy:HasTag("character") or guy:HasTag("pig")
            end
    end)
end

local function FindWarriorTargets(guy)
	return (guy:HasTag("character") or guy:HasTag("pig"))
               and inst.components.combat:CanTarget(guy)
               and not (inst.components.follower and inst.components.follower.leader == guy)
end

local function keeptargetfn(inst, target)
   return target
          and target.components.combat
          and target.components.health
          and not target.components.health:IsDead()
          and not (inst.components.follower and inst.components.follower.leader == target)
end

local function ShouldSleep(inst)
    return false
--[[    
    return GetClock():IsDay()
           and not (inst.components.combat and inst.components.combat.target)
           and not (inst.components.homeseeker and inst.components.homeseeker:HasHome() )
           and not (inst.components.burnable and inst.components.burnable:IsBurning() )
           and not (inst.components.follower and inst.components.follower.leader)
           ]]
end

local function ShouldWake(inst)
    return true
    --[[
    return GetClock():IsNight()
           or (inst.components.combat and inst.components.combat.target)
           or (inst.components.homeseeker and inst.components.homeseeker:HasHome() )
           or (inst.components.burnable and inst.components.burnable:IsBurning() )
           or (inst.components.follower and inst.components.follower.leader)
           or (inst:HasTag("spider_warrior") and FindEntity(inst, TUNING.SPIDER_WARRIOR_WAKE_RADIUS, function(...) return FindWarriorTargets(inst, ...) end ))
           ]]
end

--[[
local function DoReturn(inst)
	if inst.components.homeseeker and inst.components.homeseeker.home and inst.components.homeseeker.home.components.childspawner then
		inst.components.homeseeker.home.components.childspawner:GoHome(inst)
	end
end

local function StartDay(inst)
	if inst:IsAsleep() then
		DoReturn(inst)	
	end
end


local function OnEntitySleep(inst)
	if GetClock():IsDay() then
		DoReturn(inst)
	end
end
]]
--[[
local function SummonFriends(inst, attacker)
	local den = GetClosestInstWithTag("spiderden",inst, TUNING.SPIDER_SUMMON_WARRIORS_RADIUS)
	if den and den.components.combat and den.components.combat.onhitfn then
		den.components.combat.onhitfn(den, attacker)
	end
end
]]

local function OnAttacked(inst, data)
    inst.components.combat:SetTarget(data.attacker)
    inst.components.combat:ShareTarget(data.target, SHARE_TARGET_DIST, function(dude) return dude:HasTag("scorpion") and not dude.components.health:IsDead() end, 5)
end

local function StartNight(inst)
    inst.components.sleeper:WakeUp()
end

local function create_scorpion(Sim)
    
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddLightWatcher()
	inst.entity:AddNetwork()
    local shadow = inst.entity:AddDynamicShadow()
    shadow:SetSize( 1.5, .5 )
    inst.Transform:SetFourFaced()

    ----------
    
    inst:AddTag("monster")
    inst:AddTag("animal")    
    inst:AddTag("insect")
    inst:AddTag("hostile")
    inst:AddTag("scarytoprey")    
    inst:AddTag("scorpion")
    inst:AddTag("canbetrapped")    

    MakeCharacterPhysics(inst, 10, .5)
    -- MakePoisonableCharacter(inst)

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
    inst.components.lootdropper:SetChanceLootTable('scorpion')
    
    ---------------------            
    MakeMediumBurnableCharacter(inst, "scorpion_body")
    MakeMediumFreezableCharacter(inst, "scorpion_body")    
    inst.components.burnable.flammability = TUNING.SCORPION_FLAMMABILITY
    ---------------------       
    

    inst:AddComponent("follower")

    ------------------
    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(TUNING.SCORPION_HEALTH)
    -- inst.components.health:SetMaxHealth(200) -- 200 by default, I haven't added tuning stuff
    ------------------

    inst:AddComponent("combat")
    inst.components.combat.hiteffectsymbol = "scorpion_body"
    inst.components.combat:SetKeepTargetFunction(keeptargetfn)    
    inst.components.combat:SetDefaultDamage(TUNING.SCORPION_DAMAGE)
    inst.components.combat:SetAttackPeriod(TUNING.SCORPION_ATTACK_PERIOD)
    inst.components.combat:SetRetargetFunction(1, NormalRetarget)
    inst.components.combat:SetHurtSound("dontstarve/creatures/spider/hit_response")
    inst.components.combat:SetRange(TUNING.SCORPION_ATTACK_RANGE, TUNING.SCORPION_ATTACK_RANGE)
    ------------------
    
    inst:AddComponent("sleeper")
    inst.components.sleeper:SetResistance(2)
    inst.components.sleeper:SetSleepTest(ShouldSleep)
    inst.components.sleeper:SetWakeTest(ShouldWake)
    ------------------
    
    inst:AddComponent("knownlocations")
    ------------------
    
    inst:AddComponent("eater")
    -- inst.components.eater:SetCarnivore()
	inst.components.eater:SetDiet({ FOODTYPE.MEAT }, { FOODTYPE.MEAT })
    inst.components.eater:SetCanEatHorrible()
    -- inst.components.eater.strongstomach = true -- can eat monster meat!
	inst.components.eater:SetStrongStomach(true)
    
    ------------------
    
    inst:AddComponent("inspectable")
    
    ------------------
    
    inst:AddComponent("sanityaura")
    inst.components.sanityaura.aura = -TUNING.SANITYAURA_SMALL
    
    inst:SetStateGraph("SGscorpion")
    local brain = require "brains/spiderbrain"
    inst:SetBrain(brain)  
    inst:ListenForEvent("attacked", OnAttacked)


    return inst
end

return Prefab( "forest/monsters/scorpion", create_scorpion, assets, prefabs)