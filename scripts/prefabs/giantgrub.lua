require "stategraphs/SGgiantgrub"
require "brains/giantgrubbrain"

local assets =
{
	Asset("ANIM", "anim/giant_grub.zip")
}

local prefabs = {
    "monstermeat"
}

local sounds = {
    rabbit = "dontstarve/rabbit/scream_short"
}

local SEE_VICTIM_DIST = 10

local function IsCompleteDisguise(target)
   return target:HasTag("has_antmask") and target:HasTag("has_antsuit")
end

local function IsPreferedTarget(target)
	return IsCompleteDisguise(target) or target.prefab == "antman"
end

-- local function RetargetFn(inst)
-- 	local instPos = Vector3(inst.Transform:GetWorldPosition())
--     local entsNearby = TheSim:FindEntities(instPos.x, instPos.y, instPos.z, SEE_VICTIM_DIST)
--     local playerIsPossibleTarget = false

--     for k, v in pairs(entsNearby) do
--     	if inst.components.combat:CanTarget(v) and (v.prefab ~= "giantgrub") and v:HasTag("player") then
--     		if v:HasTag("player") then
--     			playerIsPossibleTarget = true
--     		end

--     		if IsPreferedTarget(v) then
-- 	    		return v
-- 	    	end
--     	end
--     end

--     if playerIsPossibleTarget then
--     	return GetPlayer()
--     end

--     if #entsNearby > 0 then
--     	return entsNearby[1]
--     end

--     return nil
-- end

local RETARGET_MUST_TAGS = { "_combat", "_health" }
local RETARGET_CANT_TAGS = { "playerghost", "FX", "INLIMBO", "NOCLICK", "notarget", "playerghost", "wall"}
local RETARGET_ONEOF_TAGS = { "character", "monster", "antman"}
local function RetargetFn(inst)
    return FindEntity(
        inst,
        SEE_VICTIM_DIST,
        function(target)
            if target:HasTag("giantgrub") then
                return nil
            end
            if IsPreferedTarget(target) then
                return target
            end
            return inst.components.combat:CanTarget(target)
        end,
        RETARGET_MUST_TAGS,
        RETARGET_CANT_TAGS,
        RETARGET_ONEOF_TAGS
    )
    or nil
end

local function KeepTarget(inst, target)
    return inst.components.combat:CanTarget(target) and target:HasTag("player")
end

local function SetState(inst, state)
	--"under" or "above" 两个状态
    inst.State = string.lower(state)
    if inst.State == "under" then
        ChangeToUndergroundCharacterPhysics(inst)
    elseif inst.State == "above" then
        ChangeToCharacterPhysics(inst)
    end
end

local function RememberKnownLocation(inst)
    local pos = Vector3(inst.Transform:GetWorldPosition())
    if inst:IsValid() then
        inst.components.knownlocations:RememberLocation("home", pos, true)
    end
end

local function IsState(inst, state)
    return inst.State == string.lower(state)
end

local function CanBeAttacked(inst, attacker)
	return inst.State == "above"
end

local function OnSleep(inst)
    inst.SoundEmitter:KillAllSounds()
end

local function OnRemove(inst)
    inst.SoundEmitter:KillAllSounds()
end

local function fn()
	local inst = CreateEntity()
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
    inst.entity:AddDynamicShadow()
    inst.entity:AddNetwork()

	inst.DynamicShadow:SetSize(1, 0.75)
	inst.Transform:SetFourFaced()
	inst.Transform:SetScale(3, 3, 3)

	MakeCharacterPhysics(inst, 1, 0.5)

	inst.AnimState:SetBank("giant_grub")
    inst.AnimState:SetBuild("giant_grub")
    inst.AnimState:PlayAnimation("idle", true)

	inst:AddTag("scarytoprey")
    inst:AddTag("monster")
    inst:AddTag("hostile")
    inst:AddTag("giantgrub")

    inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("inspectable")

	inst:AddComponent("locomotor")
	inst.components.locomotor.walkspeed = TUNING.GIANT_GRUB_WALK_SPEED

	inst:AddComponent("health")
	inst.components.health:SetMaxHealth(TUNING.GIANT_GRUB_HEALTH)

	inst:AddComponent("lootdropper")
	inst.components.lootdropper:SetLoot({"monstermeat"})

	inst:AddComponent("sleeper")
    inst.components.sleeper:SetSleepTest(DefaultSleepTest)
    inst.components.sleeper:SetWakeTest(DefaultWakeTest)

    inst:AddComponent("groundpounder")
  	inst.components.groundpounder.destroyer = true
	inst.components.groundpounder.damageRings = 2
	inst.components.groundpounder.destructionRings = 0
	inst.components.groundpounder.numRings = 2

	inst:AddComponent("combat")
	inst.components.combat:SetDefaultDamage(TUNING.GIANT_GRUB_DAMAGE)
	inst.components.combat:SetAttackPeriod(TUNING.GIANT_GRUB_ATTACK_PERIOD)
	inst.components.combat:SetRange(TUNING.GIANT_GRUB_ATTACK_RANGE, TUNING.GIANT_GRUB_ATTACK_RANGE)
	inst.components.combat:SetRetargetFunction(3, RetargetFn)
	inst.components.combat:SetKeepTargetFunction(KeepTarget)
	inst.components.combat.canbeattackedfn = CanBeAttacked
	inst.components.combat.hiteffectsymbol = "chest"

    inst:AddComponent("knownlocations")
    -- inst.components.knownlocations:RememberLocation("home", Vector3(0, 0, 0))
	inst:DoTaskInTime(FRAMES, RememberKnownLocation)

	inst:SetStateGraph("SGgiantgrub")
    local brain = require "brains/giantgrubbrain"
	inst:SetBrain(brain)
	inst.data = {}

    inst.CanGroundPound = true
	inst.attackUponSurfacing = false

    SetState(inst, "under")
    inst.SetState = SetState
    inst.IsState = IsState
    inst.sound = sounds
	inst.OnEntitySleep = OnSleep
    inst.OnRemoveEntity = OnRemove
    inst:ListenForEvent("enterlimbo", OnRemove)

    MakePoisonableCharacter(inst)
	MakeSmallBurnableCharacter(inst, "chest")
	MakeTinyFreezableCharacter(inst, "chest")

	return inst
end

return Prefab("giantgrub", fn, assets, prefabs)
