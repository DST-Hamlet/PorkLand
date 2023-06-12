require "brains/flytrapbrain"
require "stategraphs/SGflytrap"

local brain = require "brains/flytrapbrain"

local assets = {
	Asset("ANIM", "anim/venus_flytrap_sm_build.zip"),
	Asset("ANIM", "anim/venus_flytrap_lg_build.zip"),
	Asset("ANIM", "anim/venus_flytrap_build.zip"),
	Asset("ANIM", "anim/venus_flytrap.zip"),
}

local prefabs = {
	"plantmeat",
	"vine",
	"nectar_pod",
}

SetSharedLootTable('mean_flytrap', {
    {'plantmeat',   1.0},
    {'vine',        0.5},
    {'nectar_pod',  0.3},
})

local function OnNewTarget(inst, data)
	inst.keeptargetevenifnofood = nil
	if inst.components.sleeper ~= nil and inst.components.sleeper:IsAsleep() then
		inst.components.sleeper:WakeUp()
	end
end

local function FindFood(inst,guy)
	if guy.components.inventory ~= nil then
		return guy.components.inventory:FindItem(function(item)
            return inst.components.eater:CanEat(item)
		end)
	end
end

local function retargetfn(inst)
	local dist = TUNING.FLYTRAP_TARGET_DIST
	local CANT_TAGS = {"FX", "NOCLICK","INLIMBO", "wall", "flytrap", "structure", "aquatic"}
	return FindEntity(inst, dist, function(guy)
		if (guy:HasTag("plantkin") or guy:HasTag("chess")) and (guy:GetDistanceSqToInst(inst) > TUNING.FLYTRAP_TARGET_DIST*TUNING.FLYTRAP_TARGET_DIST or not FindFood(inst,guy)) then
			return false
		end
		return inst.components.combat:CanTarget(guy)
	end, nil, CANT_TAGS)
end

local function KeepTarget(inst, target)
	if not inst.keeptargetevenifnofood and target:HasTag("plantkin") and not FindFood(inst,target) then
		return false
	end
	return inst.components.combat:CanTarget(target) and inst:GetDistanceSqToInst(target) <= (TUNING.FLYTRAP_KEEP_TARGET_DIST*TUNING.FLYTRAP_KEEP_TARGET_DIST) and not target:HasTag("aquatic")
end

local function OnAttacked(inst, data)
	inst.components.combat:SetTarget(data.attacker)
	--inst.components.combat:ShareTarget(data.attacker, SHARE_TARGET_DIST, function(dude) return dude:HasTag("flytrap")and not dude.components.health:IsDead() end, 5)
	inst.keeptargetevenifnofood = true
end

local function OnAttackOther(inst, data)
	--inst.components.combat:ShareTarget(data.target, SHARE_TARGET_DIST, function(dude) return dude:HasTag("flytrap") and not dude.components.health:IsDead() end, 5)
end

local function DoReturn(inst)
	if inst.components.homeseeker ~= nil then
		inst.components.homeseeker:ForceGoHome()
	end
end

local function OnEntitySleep(inst)
	if TheWorld.state.isday then
		DoReturn(inst)
	end
end

local function TransformChild(inst, instant)
	if instant then
		local scale = 1.2
		inst.Transform:SetScale(scale, scale, scale)
		inst.AnimState:SetBuild("venus_flytrap_build")
	else
		inst.new_build = "venus_flytrap_build"
		inst.start_scale = 1

		inst.inc_scale = (1.20 - 1) /5
		inst.sg:GoToState("grow")
	end

	inst:RemoveTag("usefastrun")

	inst.components.combat:SetDefaultDamage(TUNING.FLYTRAP_TEEN_DAMAGE)
	inst.components.health:SetMaxHealth(TUNING.FLYTRAP_TEEN_HEALTH)
	inst.components.locomotor.runspeed = TUNING.FLYTRAP_TEEN_SPEED

	inst.components.health:DoDelta(50)
end

local function TransformTeen(inst, instant)
	if instant then
		local scale = 1.4
		inst.Transform:SetScale(scale, scale, scale)
		inst.AnimState:SetBuild("venus_flytrap_lg_build")
	else
		inst.new_build = "venus_flytrap_lg_build"
		inst.start_scale = 1.20

		inst.inc_scale = (1.40 - 1.20) / 5
		inst.sg:GoToState("grow")
	end

	inst:RemoveTag("usefastrun")

	inst.components.combat:SetDefaultDamage(TUNING.FLYTRAP_DAMAGE)
	inst.components.health:SetMaxHealth(TUNING.FLYTRAP_HEALTH)
	inst.components.locomotor.runspeed = TUNING.FLYTRAP_SPEED
	inst.components.health:DoDelta(50)
end

local function TransformAdult(inst)
	local adult = SpawnPrefab("adult_flytrap")
	adult.Transform:SetPosition(inst.Transform:GetWorldPosition())
	adult.OnSpawn(adult)
	inst:Remove()
end

local function OnEat(inst, food)
	if inst.CurrentTransform < 4 then
        inst.growtask = inst:DoTaskInTime(0.5, function()
            inst:DoTransform()
            inst.growtask:Cancel()
            inst.growtask = nil
        end)
	end
end

local function DoTransform(inst, instant)
	if inst.CurrentTransform < 4 then
		inst.CurrentTransform = inst.CurrentTransform + 1
	end

	if inst.CurrentTransform == 2 then
		inst:TransformChild(instant)
	elseif inst.CurrentTransform == 3 then
		inst:TransformTeen(instant)
	elseif inst.CurrentTransform == 4 then
		inst:TransformAdult(instant)
	end
end

local function OnSave(inst, data)
	if inst.CurrentTransform ~= nil then
		data.CurrentTransform = inst.CurrentTransform
	end
end

local function OnLoad(inst, data)
	if data ~= nil and data.CurrentTransform ~= nil then
		inst.CurrentTransform  = data.CurrentTransform -1
	 	DoTransform(inst, true)
	end
end

local function SanityAura(inst, observer)
    return not observer:HasTag("plantkin") and -TUNING.SANITYAURA_SMALL or 0
end

local function ShouldSleep(inst)
    return TheWorld.state.isday
           and not (inst.components.combat ~= nil and inst.components.combat.target)
           and not (inst.components.homeseeker ~= nil and inst.components.homeseeker:HasHome() )
           and not (inst.components.burnable ~= nil and inst.components.burnable:IsBurning() )
           and not (inst.components.follower ~= nil and inst.components.follower.leader)
           and not (inst.components.freezable ~= nil and inst.components.freezable:IsFrozen())
end

local function ShouldWake(inst)
    return TheWorld.state.isnight
           or (inst.components.combat ~= nil and inst.components.combat.target)
           or (inst.components.homeseeker ~= nil and inst.components.homeseeker:HasHome() )
           or (inst.components.burnable ~= nil and inst.components.burnable:IsBurning() )
           or (inst.components.follower ~= nil and inst.components.follower.leader)
end

local function fn()
	local inst = CreateEntity()
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddPhysics()
	inst.entity:AddSoundEmitter()
	inst.entity:AddDynamicShadow()
    inst.entity:AddNetwork()

	inst.DynamicShadow:SetSize(2.5,1.5)
	inst.Transform:SetFourFaced()

	inst:AddTag("character")
	inst:AddTag("scarytoprey")
	inst:AddTag("monster")
	inst:AddTag("flytrap")
	inst:AddTag("hostile")
	inst:AddTag("animal")
	inst:AddTag("usefastrun")

	MakeCharacterPhysics(inst, 10, .5)

	inst.AnimState:Hide("dirt")
	inst.AnimState:SetBank("venus_flytrap")
	inst.AnimState:SetBuild("venus_flytrap_sm_build")
	inst.AnimState:PlayAnimation("idle")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

	inst:AddComponent("follower")
	inst:AddComponent("inspectable")
	inst:AddComponent("knownlocations")

	inst:AddComponent("locomotor")
	inst.components.locomotor.runspeed = TUNING.FLYTRAP_CHILD_SPEED

	inst:AddComponent("health")
	inst.components.health:SetMaxHealth(TUNING.FLYTRAP_CHILD_HEALTH)

	inst:AddComponent("lootdropper")
	inst.components.lootdropper:SetChanceLootTable('mean_flytrap')

	inst:AddComponent("sanityaura")
	inst.components.sanityaura.aurafn = SanityAura

    inst:AddComponent("sleeper")
    inst.components.sleeper:SetResistance(2)
    inst.components.sleeper:SetSleepTest(ShouldSleep)
    inst.components.sleeper:SetWakeTest(ShouldWake)

	inst:AddComponent("eater")
	inst.components.eater:SetDiet({FOODTYPE.MEAT}, {FOODTYPE.MEAT})
	inst.components.eater:SetCanEatHorrible()
	inst.components.eater.oneatfn = OnEat
	inst.components.eater.strongstomach = true

    inst:AddComponent("combat")
	inst.components.combat:SetDefaultDamage(TUNING.FLYTRAP_CHILD_DAMAGE)
	inst.components.combat:SetAttackPeriod(TUNING.FLYTRAP_ATTACK_PERIOD)
	inst.components.combat:SetRetargetFunction(3, retargetfn)
	inst.components.combat:SetKeepTargetFunction(KeepTarget)
	inst.components.combat:SetRange(2,3)

	inst:ListenForEvent("newcombattarget", OnNewTarget)

	inst:SetStateGraph("SGflytrap")
	inst:SetBrain(brain)

	inst.OnEntitySleep = OnEntitySleep

	inst.OnSave = OnSave
	inst.OnLoad = OnLoad

	inst.TransformChild = TransformChild
	inst.TransformTeen = TransformTeen
	inst.TransformAdult = TransformAdult
	inst.DoTransform = DoTransform
	inst.CurrentTransform = 1

	inst:ListenForEvent("attacked", OnAttacked)
	inst:ListenForEvent("onattackother", OnAttackOther)

    MakeHauntablePanic(inst)
	MakeMediumFreezableCharacter(inst, "stem")
	MakeMediumBurnableCharacter(inst, "stem")

	return inst
end

return Prefab("mean_flytrap", fn, assets, prefabs)
