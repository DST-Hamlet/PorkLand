local assets = {
    Asset("SOUND", "sound/maxwell.fsb"),

    Asset("ANIM", "anim/waxwell_minion_spawn.zip"),
    Asset("ANIM", "anim/waxwell_minion_appear.zip"),
    Asset("ANIM", "anim/splash_weregoose_fx.zip"),
    Asset("ANIM", "anim/splash_water_drop.zip"),

    Asset("ANIM", "anim/lavaarena_shadow_lunge.zip"),
    Asset("ANIM", "anim/waxwell_minion_idle.zip"),

    Asset("ANIM", "anim/swap_nightmaresword_shadow.zip")
}

-- hackable?
for _, toolname in ipairs({"swap_axe", "swap_pickaxe", "swap_shovel"}) do
    table.insert(assets, Asset("ANIM", "anim/" .. toolname .. ".zip"))
end

local prefabs = {
    "shadowstrike_slash_fx",
    "shadowstrike_slash2_fx"
}

local function DropAggro(inst)
	local leader = inst.components.follower:GetLeader()
	if leader ~= nil and
		(	(leader.components.health ~= nil and leader.components.health:IsDead()) or
			(leader.sg ~= nil and leader.sg:HasStateTag("hiding")) or
			not inst:IsNear(leader, TUNING.SHADOWWAXWELL_PROTECTOR_TRANSFER_AGGRO_RANGE) or
			not leader.entity:IsVisible() or
			leader:HasTag("playerghost")
		) then
		--dead, hiding, or too far
		leader = nil
	end
	--nil leader will just drop target
	inst:PushEvent("transfercombattarget", leader)
end

local function DoRemove(inst)
	if inst.components.inventory ~= nil then
		inst.components.inventory:DropEverything(true)
	end
	inst:Remove()
end

local function OnSeekOblivion(inst)
	if inst:IsAsleep() then
		DoRemove(inst)
		return
	end
	inst.components.timer:StopTimer("obliviate")
	if inst.components.health == nil then
		inst.sg:GoToState("quickdespawn")
	elseif inst.components.health:IsInvincible() then
		--reschedule
		inst.components.timer:StartTimer("obliviate", .5)
	else
		inst:StopBrain()
		inst:SetBrain(nil)
		inst.components.health:Kill()
	end
end

local function OnAttacked(inst, data)
    if data.attacker ~= nil then
        if data.attacker.components.petleash ~= nil and
            data.attacker.components.petleash:IsPet(inst) then
            data.attacker.components.petleash:DespawnPet(inst)
        elseif data.attacker.components.combat ~= nil then
            inst.components.combat:SuggestTarget(data.attacker)
        end
    end
end

local function OnDancingPlayerData(inst, data)
    if data == nil then
        return
    end

    local player = data.inst
    if player == nil or player ~= inst.components.follower:GetLeader() then
        return
    end

    inst._brain_dancedata = data.dancedata
end

local RETARGET_MUST_TAGS = { "_combat" }
local RETARGET_CANT_TAGS = { "playerghost", "INLIMBO" }
local function RetargetFn(inst)
    local leader = inst.components.follower:GetLeader()
    return leader ~= nil
        and FindEntity(leader, TUNING.SHADOWWAXWELL_TARGET_DIST, function(guy)
            return guy ~= inst and (guy.components.combat:TargetIs(leader) or guy.components.combat:TargetIs(inst)) and inst.components.combat:CanTarget(guy)
        end,
        RETARGET_MUST_TAGS,
        RETARGET_CANT_TAGS) or nil
end

local function KeepTargetFn(inst, target)
    return inst.components.follower:IsNearLeader(14) and inst.components.combat:CanTarget(target)
end

--------------------------------------------------------------------------

local function OnRippleAnimOver(inst)
	if inst.pool.invalid then
		inst:Remove()
	else
		inst:Hide()
		table.insert(inst.pool, inst)
	end
end

local function CreateRipple(pool)
	local inst
	if #pool > 0 then
		inst = table.remove(pool)
		inst:Show()
	else
		inst = CreateEntity()

		inst:AddTag("FX")
		inst:AddTag("NOCLICK")
		--[[Non-networked entity]]
		inst.entity:SetCanSleep(false)
		inst.persists = false

		inst.entity:AddTransform()
		inst.entity:AddAnimState()

		inst.AnimState:SetBank("splash_weregoose_fx")
		inst.AnimState:SetBuild("splash_water_drop")
		inst.AnimState:SetLayer(LAYER_WORLD_BACKGROUND)
		inst.AnimState:SetOceanBlendParams(TUNING.OCEAN_SHADER.EFFECT_TINT_AMOUNT)

		inst.pool = pool
		inst:ListenForEvent("animover", OnRippleAnimOver)
	end

	inst.AnimState:PlayAnimation(math.random() < .5 and "no_splash" or "no_splash2")
	local scale = .6 + math.random() * .2
	inst.AnimState:SetScale(math.random() < .5 and -scale or scale, scale)

	return inst
end

local function TryRipple(inst, map)
	if not (inst:HasTag("moving") or
			inst.AnimState:IsCurrentAnimation("appear") or
			inst.AnimState:IsCurrentAnimation("disappear") or
			inst.AnimState:IsCurrentAnimation("lunge_pst")
		) then
		local x, y, z = inst.Transform:GetWorldPosition()
		if map:IsOceanAtPoint(x, 0, z) then
			CreateRipple(inst.ripple_pool).Transform:SetPosition(x, 0, z)
		end
	end
end

local function OnRemoveEntity(inst)
	for i, v in ipairs(inst.ripple_pool) do
		v:Remove()
	end
	inst.ripple_pool.invalid = true
end

--------------------------------------------------------------------------

local brain = require("brains/waxwell_minionbrain")

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    inst:SetPhysicsRadiusOverride(.5)
    MakeGhostPhysics(inst, 1, inst.physicsradiusoverride)

    inst.Transform:SetFourFaced(inst)

    inst.AnimState:SetBank("wilson")
    inst.AnimState:SetBuild("waxwell")
    inst.AnimState:OverrideSymbol("fx_wipe", "wilson_fx", "fx_wipe")
    inst.AnimState:PlayAnimation("minion_spawn")
    inst.AnimState:SetMultColour(0, 0, 0, .5)
    inst.AnimState:UsePointFiltering(true)

    inst.AnimState:AddOverrideBuild("waxwell_minion_spawn")
	inst.AnimState:AddOverrideBuild("waxwell_minion_appear")
	inst.AnimState:AddOverrideBuild("lavaarena_shadow_lunge")

    inst.AnimState:Hide("ARM_carry")
    inst.AnimState:Hide("HAT")
    inst.AnimState:Hide("HAIR_HAT")

    inst:AddTag("scarytoprey")
    inst:AddTag("shadowminion")
    inst:AddTag("NOBLOCK")

    inst:SetPrefabNameOverride("shadowwaxwell")

    --Dedicated server does not need to spawn the local fx
    if not TheNet:IsDedicated() then
        inst.ripple_pool = {}
        inst:DoPeriodicTask(.6, TryRipple, math.random() * .6, TheWorld.Map)
        inst.OnRemoveEntity = OnRemoveEntity
    end

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("locomotor")
    inst.components.locomotor.runspeed = TUNING.SHADOWWAXWELL_SPEED
    inst.components.locomotor:SetTriggersCreep(false)
    inst.components.locomotor.pathcaps = { ignorecreep = true }
    inst.components.locomotor:SetSlowMultiplier(.6)

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(TUNING.WILSON_HEALTH * 0.5)
    inst.components.health:StartRegen(1, 1)
    inst.components.health.nofadeout = true

    inst:AddComponent("combat")
    inst.components.combat:SetRange(2)
    inst.components.combat:SetDefaultDamage(27)
    inst.components.combat:SetAttackPeriod(TUNING.WILSON_ATTACK_PERIOD)
    inst.components.combat:SetRetargetFunction(2, RetargetFn) --Look for leader's target.
    inst.components.combat:SetKeepTargetFunction(KeepTargetFn) --Keep attacking while leader is near.
    inst.components.combat.hiteffectsymbol = "torso"

    inst:AddComponent("follower")
    inst.components.follower:KeepLeaderOnAttacked()
    inst.components.follower.keepdeadleader = true
    inst.components.follower.keepleaderduringminigame = true

    inst._current_task = nil
    inst._queued_task = nil


    inst:ListenForEvent("attacked", OnAttacked)
    inst:ListenForEvent("death", DropAggro)
    inst:ListenForEvent("seekoblivion", OnSeekOblivion)
    inst:ListenForEvent("dancingplayerdata", function(world, data) OnDancingPlayerData(inst, data) end, TheWorld)

    inst:SetBrain(brain)
    inst:SetStateGraph("SGshadowwaxwell")

    inst.DropAggro = DropAggro

    return inst
end

return Prefab("waxwell_minion", fn, assets, prefabs)

