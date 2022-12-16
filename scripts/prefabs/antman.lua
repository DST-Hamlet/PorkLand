require "brains/antbrain"
require "stategraphs/SGant"

local assets =
{
	Asset("ANIM", "anim/antman_basic.zip"),
	Asset("ANIM", "anim/antman_attacks.zip"),
	Asset("ANIM", "anim/antman_actions.zip"),

    Asset("ANIM", "anim/antman_translucent_build.zip"),
	--Asset("ANIM", "anim/antman_build.zip"),
}

local prefabs =
{
    "monstermeat",
    "chitin",
}

local MAX_TARGET_SHARES = TUNING.PEAGAWK_RELEASE_TIME
local SHARE_TARGET_DIST = TUNING.MIN_POGNAP_INTERVAL

local aporkalypse = GetAporkalypse()

local function setEatType(inst,eattype)
    if eattype == 1 then
        inst.components.eater:SetVegetarian()
    elseif eattype == 2 then
        inst.components.eater:SetBird()
    elseif eattype == 3 then
        inst.components.eater:SetBeaver()
    elseif eattype == 4 then
        inst.components.eater:SetCarnivore()
    end
end

local function ontalk(inst, script)
    if inst.is_complete_disguise(ThePlayer) then
        inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/crickant/pick_up")
    else
	   inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/crickant/abandon")
    end
end

local function SpringMod(amt)
    if TheWorld and TheWorld.state.issummer then
        return amt --* TUNING.SPRING_COMBAT_MOD
    else
        return amt
    end
end

local function CalcSanityAura(inst, observer)
    if inst.components.follower and inst.components.follower.leader == observer then
        return TUNING.SANITYAURA_SMALL
    end
    return 0
end

local function ShouldAcceptItem(inst, item)
    if inst.components.sleeper:IsAsleep() then
        return false
    end

    if item.components.equippable and item.components.equippable.equipslot == EQUIPSLOTS.HEAD then
        return true
    end
    if item.components.edible then

        if (item.components.edible.foodtype == "MEAT" or item.components.edible.foodtype == "HORRIBLE")
           and inst.components.follower.leader
           and inst.components.follower:GetLoyaltyPercent() > 0.9 then
            return false
        end

        if (item.components.edible.foodtype == "VEGGIE" or item.components.edible.foodtype == "RAW") then
			local last_eat_time = inst.components.eater:TimeSinceLastEating()
			if last_eat_time and last_eat_time < TUNING.PIG_MIN_POOP_PERIOD then
				return false
			end

            if inst.components.inventory:Has(item.prefab, 1) then
                return false
            end
		end

        return true
    end
end

local function OnGetItemFromPlayer(inst, giver, item)
    --I eat food
    if item.components.edible then
        --meat makes us friends
        if inst.components.eater:CanEat(item) then
      --  if item.components.edible.foodtype == "MEAT" or item.components.edible.foodtype == "HORRIBLE" then
            if inst.components.combat.target and inst.components.combat.target == giver then
                inst.components.combat:SetTarget(nil)
            elseif giver.components.leader then
				inst.SoundEmitter:PlaySound("dontstarve/common/makeFriend")
				giver.components.leader:AddFollower(inst)
                inst.components.follower:AddLoyaltyTime(item.components.edible:GetHunger() * TUNING.ANTMAN_LOYALTY_PER_HUNGER)
            end
        end
        if inst.components.sleeper:IsAsleep() then
            inst.components.sleeper:WakeUp()
        end
    end

    --I wear hats
    if item.components.equippable and item.components.equippable.equipslot == EQUIPSLOTS.HEAD then
        local current = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HEAD)
        if current then
            inst.components.inventory:DropItem(current)
        end

        inst.components.inventory:Equip(item)
        inst.AnimState:Show("hat")
    end
end

local function OnRefuseItem(inst, item)
    inst.sg:GoToState("refuse")
    if inst.components.sleeper:IsAsleep() then
        inst.components.sleeper:WakeUp()
    end
end

local function OnEat(inst, food)
end

local function OnAttackedByDecidRoot(inst, attacker)
    local fn = function(dude) return dude:HasTag("antman") end

    local x, y, z = inst.Transform:GetWorldPosition()
    local ents = nil
    if TheWorld and TheWorld.state.iswinter then
        ents = TheSim:FindEntities(x, y, z, (SHARE_TARGET_DIST * TUNING.SPRING_COMBAT_MOD) / 2)
    else
        ents = TheSim:FindEntities(x, y, z, SHARE_TARGET_DIST / 2)
    end

    if ents then
        local num_helpers = 0
        for k, v in pairs(ents) do
            if v ~= inst and v.components.combat and not (v.components.health and v.components.health:IsDead()) and fn(v) then
                if v:PushEvent("suggest_tree_target", {tree=attacker}) then
                    num_helpers = num_helpers + 1
                end
            end
            if num_helpers >= MAX_TARGET_SHARES then
                break
            end
        end
    end
end

local function OnAttacked(inst, data)
    --print(inst, "OnAttacked")
    local attacker = data.attacker
    inst:ClearBufferedAction()

    if attacker.prefab == "deciduous_root" and attacker.owner then
        OnAttackedByDecidRoot(inst, attacker.owner)
    elseif attacker.prefab ~= "deciduous_root" then
        inst.components.combat:SetTarget(attacker)
        inst.components.combat:ShareTarget(attacker, SHARE_TARGET_DIST, function(dude) return dude:HasTag("ant") end, MAX_TARGET_SHARES)
    end
end

local function OnNewTarget(inst, data)
end

local builds = {"antman_translucent_build"}-- {"antman_build"}

local function is_complete_disguise(target)
    return target:HasTag("has_antmask") and target:HasTag("has_antsuit")
end

local function NormalRetargetFn(inst)
    return FindEntity(inst, TUNING.PIG_TARGET_DIST,
        function(guy)
            if guy.components.health and not guy.components.health:IsDead() and inst.components.combat:CanTarget(guy) and not is_complete_disguise(guy) then
                if guy:HasTag("monster") then return guy end
                if guy:HasTag("player") and guy.components.inventory and guy:GetDistanceSqToInst(inst) < TUNING.ANTMAN_ATTACK_ON_SIGHT_DIST*TUNING.ANTMAN_ATTACK_ON_SIGHT_DIST and not guy:HasTag("ant_disguise") then return guy end
            end
        end)
end

local function NormalKeepTargetFn(inst, target)
    --give up on dead guys, or guys in the dark, or werepigs
    return inst.components.combat:CanTarget(target)
           and (not target.LightWatcher or target.LightWatcher:IsInLight())
           and not (target.sg and target.sg:HasStateTag("transform") )
end

local function NormalShouldSleep(inst)
    if inst.components.follower and inst.components.follower.leader then
        local fire = FindEntity( inst, 6,
            function(ent)
                return ent.components.burnable and ent.components.burnable:IsBurning()
            end,
        {"campfire"} )

        return DefaultSleepTest(inst) and fire and (not inst.LightWatcher or inst.LightWatcher:IsInLight())
    else
        return DefaultSleepTest(inst)
    end
end

local function TransformToWarrior(inst, from_limbo_or_asleep)
    if from_limbo_or_asleep then
        local warrior = SpawnPrefab("antman_warrior")
        warrior.Transform:SetPosition(  inst.Transform:GetWorldPosition() )
        warrior:AddTag("aporkalypse_cleanup")
		-- re-register us with the childspawner and interior
		-- ReplaceEntity(inst, warrior)
        inst:Remove()
    else
        inst.sg:GoToState("transform")
    end
end

local function suggest_tree_target(inst,data)
    if data and data.tree and inst:GetBufferedAction() ~= ACTIONS.CHOP then
        inst.tree_target = data.tree
    end
end

local function getstatus(inst)
    if inst.components.follower.leader ~= nil then
        return "FOLLOWER"
    end
end

local function beginaporkalypse(inst)
    if not inst:IsInLimbo() then
        if inst:IsAsleep() then
            TransformToWarrior(inst, true)
        else
            TransformToWarrior(inst, false)
        end
    end
end

local function CheckForAporkalypse(inst, from_limbo)
    if aporkalypse and aporkalypse:IsActive() then
        inst:DoTaskInTime(.2, function(inst)
            TransformToWarrior(inst, from_limbo)
        end)
    end
end

local function exitlimbo(inst)
    CheckForAporkalypse(true)
end

local function onsave(inst, data)
    if data then
        inst.build = data.build or builds[1]

        inst.combatTargetWasDisguisedOnExit = data.combatTargetWasDisguisedOnExit
        inst.AnimState:SetBuild(inst.build)
        inst.eattype = data.eattype
        setEatType(inst, inst.eattype)
    end
end

local function onload(inst, data)
    if data then
        inst.build = data.build or builds[1]

        inst.combatTargetWasDisguisedOnExit = data.combatTargetWasDisguisedOnExit
        inst.AnimState:SetBuild(inst.build)
        inst.eattype = data.eattype
        setEatType(inst, inst.eattype)
    end
end

local function SetNormalAnt(inst)

end

local function common()
	local inst = CreateEntity()
    inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddDynamicShadow()
    inst.entity:AddNetwork()

	inst.DynamicShadow:SetSize(1.5, .75)
    inst.Transform:SetFourFaced()

    inst.Transform:SetScale(1.15, 1.15, 1.15)

    inst.entity:AddLightWatcher()

    MakeCharacterPhysics(inst, 50, .5)

    inst:AddTag("character")
    inst:AddTag("ant")
    inst:AddTag("insect")
    inst:AddTag("scarytoprey")

    inst.build = builds[math.random(#builds)]

    inst.AnimState:SetBank("antman")
    inst.AnimState:SetBuild(inst.build)
    inst.AnimState:PlayAnimation("idle_loop")
    inst.AnimState:Hide("hat")

    inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

    inst:AddComponent("inventory")
    inst:AddComponent("knownlocations")

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(TUNING.ANTMAN_HEALTH)

    inst:AddComponent("inspectable")
    inst.components.inspectable.getstatus = getstatus

    inst:AddComponent("sanityaura")
    inst.components.sanityaura.aurafn = CalcSanityAura

    inst:AddComponent("follower")
    inst.components.follower.maxfollowtime = TUNING.ANTMAN_LOYALTY_MAXTIME

    inst:AddComponent("named")
    inst.components.named.possiblenames = STRINGS.ANTNAMES
    inst.components.named:PickNewName()

    inst:AddComponent("locomotor") -- locomotor must be constructed before the stategraph
    inst.components.locomotor.runspeed = TUNING.ANTMAN_RUN_SPEED --5
    inst.components.locomotor.walkspeed = TUNING.ANTMAN_WALK_SPEED --3

    inst:AddComponent("trader")
    inst.components.trader:SetAcceptTest(ShouldAcceptItem)
    inst.components.trader.onaccept = OnGetItemFromPlayer
    inst.components.trader.onrefuse = OnRefuseItem

    inst:AddComponent("sleeper")
    inst.components.sleeper:SetSleepTest(NormalShouldSleep)
    inst.components.sleeper:SetWakeTest(DefaultWakeTest)
    inst.components.sleeper:SetResistance(2)

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetLoot({})
    inst.components.lootdropper:AddRandomLoot("monstermeat", 3)
    inst.components.lootdropper:AddRandomLoot("chitin", 1)
    inst.components.lootdropper.numrandomloot = 1

    inst:AddComponent("eater")
    inst.eattype = math.random(4)
    setEatType(inst,inst.eattype)
	inst.components.eater:SetCanEatHorrible()
    -- table.insert(inst.components.eater.foodprefs, "RAW")
    -- table.insert(inst.components.eater.ablefoods, "RAW")
    inst.components.eater.strongstomach = true -- can eat monster meat!
    inst.components.eater:SetOnEatFn(OnEat)

    inst:AddComponent("combat")
    inst.components.combat.hiteffectsymbol = "antman_torso"
    inst.components.combat:SetDefaultDamage(TUNING.ANTMAN_DAMAGE)
    inst.components.combat:SetAttackPeriod(TUNING.ANTMAN_ATTACK_PERIOD)
    inst.components.combat:SetKeepTargetFunction(NormalKeepTargetFn)
    inst.components.combat:SetRetargetFunction(3, NormalRetargetFn)
    inst.components.combat:SetTarget(nil)

    inst:AddComponent("talker")
    inst.components.trader:Enable()
    inst.components.talker.ontalk = ontalk
    inst.components.talker.fontsize = 35
    inst.components.talker.font = TALKINGFONT
    -- inst.components.talker.colour = Vector3(133/255, 140/255, 167/255)
    inst.components.talker.offset = Vector3(0, -400, 0)
    inst.components.talker:StopIgnoringAll()

    local brain = require "brains/antbrain"
    inst:SetBrain(brain)
    inst:SetStateGraph("SGant")

    MakeHauntablePanic(inst)
    MakePoisonableCharacter(inst)
    MakeMediumBurnableCharacter(inst, "antman_torso")
    MakeMediumFreezableCharacter(inst, "antman_torso")

    inst.OnSave = onsave
    inst.OnLoad =onload
    inst.combatTargetWasDisguisedOnExit = false
    inst.is_complete_disguise = is_complete_disguise

    inst:ListenForEvent("suggest_tree_target", suggest_tree_target)
    inst:ListenForEvent("attacked", OnAttacked)
    inst:ListenForEvent("newcombattarget", OnNewTarget)
    inst:ListenForEvent("beginaporkalypse", beginaporkalypse , TheWorld)
    inst:ListenForEvent("exitlimbo", exitlimbo)

    CheckForAporkalypse(true)
    return inst
end

return Prefab("antman", common, assets, prefabs)
