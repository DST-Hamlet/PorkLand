require "brains/gnatbrain"
require "stategraphs/SGgnat"

local assets=
{
	Asset("ANIM", "anim/gnat.zip"),
}

local prefabs =
{

}

local function didplayerseebugsdie(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
	local player = FindClosestPlayerInRangeSq( x, y, z, 10*10, true)
	if inst:GetDistanceSqToInst(player) < 10*10 then
		player:DoTaskInTime(0.5, function()
			player.components.talker:Say(GetString(player.prefab, "ANNOUNCE_GNATS_DIED"))
		end)
	end
end

local function keeptargetfn(inst, target)
   return target
          and target.components.combat
          and target.components.health
          and not target.components.health:IsDead()
          and not (inst.components.follower and inst.components.follower.leader == target)
          and not (inst.components.follower and inst.components.follower.leader:HasTag("player") and target:HasTag("companion"))
end

local function NormalRetarget(inst)
    local targetDist = 5
    local notags = {"FX", "NOCLICK","INLIMBO", "monster"}
    return FindEntity(inst, targetDist,
        function(guy)
            if inst.components.combat:CanTarget(guy)
               and not (inst.components.follower and inst.components.follower.leader == guy)
               and not (inst.components.follower and inst.components.follower.leader:HasTag("player") and guy:HasTag("companion")) then
                return (guy:HasTag("character") and not guy:HasTag("monster"))
            end
    end, nil, notags)
end

local function OnGasChange(inst, onGas)
	if onGas then
		inst:DoTaskInTime(1, function()
				inst.components.health:Kill()
				didplayerseebugsdie(inst)
			end
		)
	end
end

local function bite(inst)
	if inst.components.infester.target then
		inst.bufferedaction = BufferedAction(inst, inst.components.infester.target, ACTIONS.ATTACK)
		inst:PushEvent("doattack")
	end
end

local function findlight(inst)
    local targetDist = 15
    local notags = {"FX", "NOCLICK","INLIMBO"}
	local light = FindEntity(inst, targetDist,
        function(guy)
            if guy.Light and guy.Light:IsEnabled() and guy:HasTag("lightsource") then
                return true
            end
    end, nil, notags)

    return light
end

local function stopinfesttest(inst)
	if  TheWorld.state.isdusk or TheWorld.state.isnight then
		local target = findlight(inst)
		if target and inst:GetDistanceSqToInst(target) > 5*5 then
			return target
		end
	end
end

local function OnUninfest(inst)
    if not (
		inst.components.homeseeker and
		inst.components.homeseeker.home and
		inst.components.homeseeker.home:IsValid()
	)
    then
		inst.components.knownlocations:RememberLocation("home", inst:GetPosition())
	end
end

local function makehome(act)
	local home = SpawnPrefab("gnatmound")
	local pos = Vector3(act.doer.Transform:GetWorldPosition())
	home.Transform:SetPosition(pos.x,pos.y,pos.z)
	home.components.workable.workleft = 1
	home.rebuildfn(home)
	home.components.childspawner:TakeOwnership(act.doer)
	home.components.childspawner.childreninside = home.components.childspawner.childreninside -1
	act.doer:PushEvent("takeoff")

	act.doer.makehome = nil
end

local function fn(Sim)
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddDynamicShadow()
    inst.entity:AddNetwork()
	inst.DynamicShadow:SetSize( 2, .6 )

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

	----------

	inst:AddTag("gnat")
	inst:AddTag("flying")
	inst:AddTag("insect")
	inst:AddTag("animal")
	inst:AddTag("smallcreature")
	inst:AddTag("avoidonhit")
	inst:AddTag("no_durability_loss_on_hit")
    inst:AddTag("hostile")


    inst:AddTag("burnable") -- needs this to be frozen by flingomatic

    inst:AddTag("lastresort") -- for auto attacking

	MakePoisonableCharacter(inst)
	MakeCharacterPhysics(inst, 1, .25)
	inst.Transform:SetFourFaced()

	inst.Physics:SetCollisionGroup(COLLISION.FLYERS)
	inst.Physics:ClearCollisionMask()
    inst.Physics:CollidesWith(COLLISION.WORLD)
	--inst.Physics:CollidesWith(COLLISION.INTWALL)

	inst.AnimState:SetBuild("gnat")

	------------

	inst.AnimState:SetBank("gnat")
	inst.AnimState:PlayAnimation("idle_loop")
	inst.AnimState:SetRayTestOnBB(true);

	------------

	inst:AddComponent("locomotor") -- locomotor must be constructed before the stategraph
	inst.components.locomotor:EnableGroundSpeedMultiplier(false)
	inst.components.locomotor:SetTriggersCreep(false)
	inst.components.locomotor.walkspeed = TUNING.GNAT_WALK_SPEED
    inst.components.locomotor.runspeed = TUNING.GNAT_RUN_SPEED

	inst:SetStateGraph("SGgnat")

	------------------

	inst:AddComponent("health")
	inst.components.health:SetMaxHealth(1)
	inst.components.health.invincible = true

	------------------

	inst:AddComponent("combat")
	inst.components.combat.hiteffectsymbol = "fx_puff"
    inst.components.combat:SetKeepTargetFunction(keeptargetfn)

    inst.components.combat:SetDefaultDamage(1)
    inst.components.combat:SetAttackPeriod(10)
    inst.components.combat:SetRetargetFunction(1, NormalRetarget)

	------------------

	inst:AddComponent("knownlocations")

	------------------

	inst:AddComponent("sanityaura")
    inst.components.sanityaura.aura = -TUNING.SANITYAURA_TINY * 2

    ------------------

	MakeTinyFreezableCharacter(inst, "fx_puff")

	------------------

	inst:AddComponent("inspectable")

	-----------------

	inst:AddComponent("infester")
	inst.components.infester.bitefn = bite
	inst.components.infester.stopinfesttestfn = stopinfesttest
	inst.components.infester.onuninfestfn = OnUninfest
	------------------

	inst:AddComponent("lootdropper")

	------------------

	inst:AddComponent("tiletracker")
	inst.components.tiletracker:SetOnGasChangeFn(OnGasChange)
	inst.components.tiletracker:Start()
	inst.OnGasChange = OnGasChange

	------------------

    inst:AddComponent("timer")

    ------------------

	inst:ListenForEvent("freeze", function()
		if inst.components.freezable then
			inst.components.health.invincible = false
		end
	end)

	inst:ListenForEvent("unfreeze", function()
		if inst.components.freezable then
			inst.components.health.invincible = true
		end
	end)

	inst.special_action = makehome

	local brain = require "brains/gnatbrain"
	inst:SetBrain(brain)

	inst.findlight = findlight

	return inst
end

return Prefab( "forest/common/gnat", fn, assets, prefabs)
