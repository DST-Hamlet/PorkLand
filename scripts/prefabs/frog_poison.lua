require "brains/frogbrain"
require "stategraphs/SGfrog"

local assets=
{
	Asset("ANIM", "anim/frog.zip"),
	Asset("ANIM", "anim/frog_build.zip"),
	Asset("ANIM", "anim/frog_yellow_build.zip"),	
	Asset("SOUND", "sound/frog.fsb"),
}

local poisonassets=
{
	Asset("ANIM", "anim/frog.zip"),
	Asset("ANIM", "anim/frog_water.zip"),	
	Asset("ANIM", "anim/frog_treefrog_build.zip"),
	Asset("SOUND", "sound/frog.fsb"),
}

local prefabs =
{
	"froglegs",
	"splash",
	"venomgland",
	"froglegs_poison",
}

local sounds = {
	base = {
		grunt = "dontstarve/frog/grunt",
		walk = "dontstarve/frog/walk",
		spit = "dontstarve/frog/attack_spit",
		voice = "dontstarve/frog/attack_voice",
		splat = "dontstarve/frog/splat",
		die = "dontstarve/frog/die",	
		wake = "dontstarve/frog/wake",
	},
	poison = {
		grunt = "dontstarve_DLC003/creatures/enemy/frog_poison/grunt",
		walk = "dontstarve/frog/walk",
		spit = "dontstarve_DLC003/creatures/enemy/frog_poison/attack_spit",
		voice = "dontstarve_DLC003/creatures/enemy/frog_poison/attack_spit",		
		splat = "dontstarve/frog/splat",
		die = "dontstarve_DLC003/creatures/enemy/frog_poison/death",
		wake = "dontstarve/frog/wake",
	},	
}
local function retargetfn(inst)
	if not inst.components.health:IsDead() and not inst.components.sleeper:IsAsleep() then
		local notags = {"FX", "NOCLICK","INLIMBO"}
		return FindEntity(inst, TUNING.FROG_TARGET_DIST, function(guy) 
			if guy.components.combat and guy.components.health and not guy.components.health:IsDead() then
				return guy.components.inventory ~= nil
			end
		end, nil, notags)
	end
end

local function retargetpoisonfrogfn(inst)
	if not inst.components.health:IsDead() and not inst.components.sleeper:IsAsleep() then
		local notags = {"FX", "NOCLICK","INLIMBO"}
		return FindEntity(inst, TUNING.FROG_TARGET_DIST, function(guy) 
			if guy.components.combat and guy.components.health and not guy.components.health:IsDead() and not guy:HasTag("hippopotamoose") then
				return guy.components.inventory ~= nil or guy:HasTag("insect") 
			end
		end, nil, notags)
	end
end

local function ShouldSleep(inst)
    if inst.components.knownlocations:GetLocation("home") ~= nil or inst:HasTag("aporkalypse_cleanup") then
        return false
    end

    -- Homeless frogs will sleep at night.
    return TheWorld.state.isnight
end

local function OnAttacked(inst, data)
	inst.components.combat:SetTarget(data.attacker)
	inst.components.combat:ShareTarget(data.attacker, 30, function(dude) return dude:HasTag("frog") and not dude.components.health:IsDead() end, 5)
end

local function OnGoingHome(inst)
	local fx = SpawnPrefab("splash")
	local pos = inst:GetPosition()
	fx.Transform:SetPosition(pos.x, pos.y, pos.z)

	--local splash = PlayFX(Vector3(inst.Transform:GetWorldPosition() ), "splash", "splash", "splash")
	inst.SoundEmitter:PlaySound("dontstarve/frog/splash")
end
local function OnSave(inst, data)
    if inst:HasTag("aporkalypse_cleanup") then
        data.aporkalypse_cleanup = true
    end
end

local function OnLoad(inst, data) 
	if data and data.aporkalypse_cleanup then
		inst:AddTag("aporkalypse_cleanup")
	end
end

local function OnWaterChangeCommon(inst)
	local onwater = inst.components.amphibiouscreature.in_water
	--TODO add the other speed changes
	if onwater then
		inst.components.locomotor.walkspeed = 3
	else		
		inst.components.locomotor.walkspeed = 4
	end
	if not inst.sg:HasStateTag("falling") then
		local noanim = inst:GetTimeAlive() < 1
		inst.sg:GoToState(onwater and "submerge" or "emerge", noanim)
	end
end



local function OnEnterWater(inst)
    inst.DynamicShadow:Enable(false)
    OnWaterChangeCommon(inst)
end

local function OnExitWater(inst)
    inst.DynamicShadow:Enable(true)
    OnWaterChangeCommon(inst)
end

local function commonfn(Sim)
	local inst = CreateEntity()
	local trans = inst.entity:AddTransform()
	local anim = inst.entity:AddAnimState()
    inst.entity:AddNetwork()
	local physics = inst.entity:AddPhysics()
	local sound = inst.entity:AddSoundEmitter()
	local shadow = inst.entity:AddDynamicShadow()
	
	shadow:SetSize( 1.5, .75 )
	inst.Transform:SetFourFaced()

	inst.AnimState:SetBank("frog")
	inst.AnimState:SetBuild("frog_build")
	

    inst.entity:SetPristine()

	if not TheWorld.ismastersim then
        return inst
    end
	inst.AnimState:PlayAnimation("idle")

	MakeCharacterPhysics(inst, 1, .3)
	 
	inst:AddComponent("locomotor") -- locomotor must be constructed before the stategraph
	inst.components.locomotor.walkspeed = 4
	inst.components.locomotor.runspeed = 8

	inst:SetStateGraph("SGfrog")

	inst:AddTag("animal")
	inst:AddTag("prey")
	inst:AddTag("smallcreature")
	inst:AddTag("frog")
	inst:AddTag("canbetrapped")    

	local brain = require "brains/frogbrain"
	inst:SetBrain(brain)

	inst:AddComponent("sleeper")
	inst.components.sleeper:SetSleepTest(ShouldSleep)
	
	inst:AddComponent("health")
	inst.components.health:SetMaxHealth(TUNING.FROG_HEALTH)

	inst:AddComponent("lootdropper")
	inst.components.lootdropper:SetLoot({"froglegs"})
	
	inst:AddComponent("combat")
	inst.components.combat:SetDefaultDamage(TUNING.FROG_DAMAGE)
	inst.components.combat:SetAttackPeriod(TUNING.FROG_ATTACK_PERIOD)
	inst.components.combat:SetRetargetFunction(3, retargetfn)

	inst.components.combat.onhitotherfn = function(inst, other, damage) inst.components.thief:StealItem(other) end
	
	inst:AddComponent("thief")
	
	MakeTinyFreezableCharacter(inst, "frogsack")
	MakeSmallBurnableCharacter(inst, "frogsack")

	inst.sounds = sounds.base
	
	inst:AddComponent("knownlocations")
	inst:AddComponent("inspectable")

	inst:ListenForEvent("attacked", OnAttacked)
	inst:ListenForEvent("goinghome", OnGoingHome)
	
	return inst
end

local function poisonfn(Sim)
	local inst = commonfn(Sim)

	MakeAmphibiousCharacterPhysics(inst, 1, .3)
	--inst.entity:AddAnimState()
	--inst.AnimState:SetBank("frog")
	inst.AnimState:SetBuild("frog_treefrog_build")

    inst:AddComponent("amphibiouscreature")
	local bank = "frog"
	inst.components.amphibiouscreature:SetBanks(bank, bank.."_water")
    inst.components.amphibiouscreature:SetEnterWaterFn(OnEnterWater)
    inst.components.amphibiouscreature:SetExitWaterFn(OnExitWater)
	inst.components.locomotor.pathcaps = { allowocean = true }
	inst.AnimState:PlayAnimation("idle")
	local brain = require "brains/frogbrain"
	inst:SetBrain(brain)
	inst.sg:GoToState("idle")
	inst:AddTag("duskok")
	inst:AddTag("eatsbait")
	inst:AddTag("scarytoprey")

	inst.components.lootdropper:SetLoot({"froglegs_poison"})
	inst.components.lootdropper:AddRandomLoot("venomgland", 0.5)

	inst:AddComponent("eater")

	inst.components.combat:SetRetargetFunction(3, retargetpoisonfrogfn)
	
	inst.sounds = sounds.poison

	inst.OnSave = OnSave
	inst.OnLoad = OnLoad

	inst.OnEntityWake = OnEntityWake
    inst.OnEntitySleep = OnEntitySleep   

	return inst
end

return Prefab( "forest/animals/frog", commonfn, assets, prefabs),
Prefab( "forest/animals/frog_poison", poisonfn, poisonassets, prefabs)