local assets =
{
    Asset("ANIM", "anim/antman_basic.zip"),
    Asset("ANIM", "anim/antman_attacks.zip"),
    Asset("ANIM", "anim/antman_actions.zip"),

    Asset("ANIM", "anim/antman_translucent_build.zip"),
}

local prefabs =
{
    "monstermeat",
    "chitin",
}

local function GenerateAntmanName()
    return STRINGS.NAMES.ANTNAMES_PREFIX..math.random(100000,999999)
end

local MAX_TARGET_SHARES = 5
local SHARE_TARGET_DIST = 30

local function SetEatType(inst, food_type)
    if food_type == 1 then
        inst.components.eater:SetDiet({FOODTYPE.VEGGIE, FOODTYPE.RAW}, {FOODTYPE.VEGGIE, FOODTYPE.RAW})
    elseif food_type == 2 then
        inst.components.eater:SetDiet({FOODTYPE.SEEDS, FOODTYPE.RAW}, {FOODTYPE.SEEDS, FOODTYPE.RAW})
    elseif food_type == 3 then
        inst.components.eater:SetDiet({FOODTYPE.WOOD, FOODTYPE.ROUGHAGE, FOODTYPE.RAW}, {FOODTYPE.WOOD, FOODTYPE.ROUGHAGE, FOODTYPE.RAW})
    elseif food_type == 4 then
        inst.components.eater:SetDiet({FOODTYPE.MEAT, FOODTYPE.RAW}, {FOODTYPE.MEAT, FOODTYPE.RAW})
    end
end

local function speech_override_fn(inst, speech)
    if not ThePlayer or ThePlayer:HasTag("antlingual") then
        return speech
    else
        return GetRandomItem(STRINGS.ANT_TALK_UNTRANSLATED)
    end
end

local function OnTalk(inst, script)
    if IsPlayerInAntDisguise(ThePlayer) then
        inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/crickant/pick_up")
    else
       inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/crickant/abandon")
    end
end

local function GetStatus(inst)
    if inst.components.follower.leader then
        return "FOLLOWER"
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

    if inst.components.eater:CanEat(item) then
        if (item.components.edible.foodtype == FOODTYPE.MEAT or item.components.edible.foodtype == FOODTYPE.HORRIBLE)
           and inst.components.follower.leader
           and inst.components.follower:GetLoyaltyPercent() > 0.9 then
            return false
        end

        if (item.components.edible.foodtype == FOODTYPE.VEGGIE or item.components.edible.foodtype == FOODTYPE.RAW) then
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

    return false
end

local function OnGetItemFromPlayer(inst, giver, item)
    --I eat food
    if inst.components.eater:CanEat(item) then
        --meat makes us friends
        if inst.components.eater:CanEat(item) then
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

local function OnAttackedByDecidRoot(inst, attacker)
    local fn = function(dude) return dude:HasTag("ant") end

    local x, y, z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, SHARE_TARGET_DIST / 2)

    if not ents or not next(ents) then
        return
    end

    local num_helpers = 0
    for _, v in pairs(ents) do
        if v ~= inst and v.components.combat and not (v.components.health and v.components.health:IsDead()) and fn(v) then
            if v:PushEvent("suggest_tree_target", {tree = attacker}) then
                num_helpers = num_helpers + 1
            end
        end
        if num_helpers >= MAX_TARGET_SHARES then
            break
        end
    end
end

local function OnAttacked(inst, data)
    local attacker = data.attacker
    inst:ClearBufferedAction()

    if attacker and attacker.prefab == "deciduous_root" and attacker.owner then
        OnAttackedByDecidRoot(inst, attacker.owner)
    elseif attacker and attacker.prefab ~= "deciduous_root" then
        inst.components.combat:SetTarget(attacker)
        inst.components.combat:ShareTarget(attacker, SHARE_TARGET_DIST, function(ent)
            return ent:HasTag("ant")
        end, MAX_TARGET_SHARES)
    end
end

local RETARGET_DIST = 16
local ATTACK_ONSIGHT_DISTSQ = 4 * 4
local RETARGET_ONE_OF_TAGS = {"monster", "player"}

local function RetargetFn(inst)
    return FindEntity(inst, RETARGET_DIST, function(ent)
        if not inst.components.combat:CanTarget(ent) or IsPlayerInAntDisguise(ent) then
            return
        end

        if ent:HasTag("monster") then
            return ent
        else
            if ent.components.inventory and ent:GetDistanceSqToInst(inst) < ATTACK_ONSIGHT_DISTSQ then
                return ent
            end
        end
    end, nil, nil, RETARGET_ONE_OF_TAGS)
end

local function KeepTargetFn(inst, target)
    --give up on dead guys, or guys in the dark
    return (inst.components.combat:CanTarget(target))
end

local function ShouldSleepTest(inst)
    if inst.components.follower and inst.components.follower.leader then
        local fire = FindEntity(inst, 6, function(ent)
            return ent.components.burnable and ent.components.burnable:IsBurning()
        end, {"campfire"})

        return DefaultSleepTest(inst) and fire
    else
        return DefaultSleepTest(inst)
    end
end

local function TransformToWarrior(inst, from_limbo_or_asleep)
    if from_limbo_or_asleep then
        local home = inst.components.homeseeker and inst.components.homeseeker:GetHome()
        local warrior = ReplacePrefab(inst, "antman_warrior")
        warrior:AddTag("aporkalypse_cleanup")
        if home then
            home.components.childspawner:TakeOwnership(warrior)
        end
    else
        inst.sg:GoToState("transform")
    end
end

local function OnIsAporkalypse(inst, isaporkalypse)
    if isaporkalypse then
        TransformToWarrior(inst, inst:IsAsleep())
    end
end

local function OnSave(inst, data)
    data.eattype = inst.eattype
end

local function OnLoad(inst, data)
    if not data then
        return
    end

    inst.eattype = data.eattype
    SetEatType(inst, inst.eattype)
end

local brain = require("brains/antbrain")

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddDynamicShadow()
    inst.entity:AddLightWatcher()
    inst.entity:AddNetwork()

    MakeCharacterPhysics(inst, 50, 0.5)

    inst.AnimState:SetBank("antman")
    inst.AnimState:SetBuild("antman_translucent_build")
    inst.AnimState:PlayAnimation("idle_loop", true)
    inst.AnimState:Hide("hat")

    inst.DynamicShadow:SetSize(1.5, 0.75)

    inst.Transform:SetFourFaced()
    inst.Transform:SetScale(1.15, 1.15, 1.15)

    inst:AddComponent("talker")
    inst.components.talker.ontalkfn = OnTalk -- ontalkfn runs on client
    inst.components.talker.fontsize = 35
    inst.components.talker.font = TALKINGFONT
    inst.components.talker.offset = Vector3(0, -400, 0)
    inst.components.talker:StopIgnoringAll()
    inst.components.talker:MakeChatter()

    inst:AddTag("character")
    inst:AddTag("ant")
    inst:AddTag("insect")
    inst:AddTag("scarytoprey")

    inst.speech_override_fn = speech_override_fn

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(TUNING.ANTMAN_HEALTH)

    inst:AddComponent("inventory")

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetLoot({})
    inst.components.lootdropper:AddRandomLoot("monstermeat", 3)
    inst.components.lootdropper:AddRandomLoot("chitin", 1)
    inst.components.lootdropper.numrandomloot = 1

    inst:AddComponent("knownlocations")

    inst:AddComponent("sleeper")
    inst.components.sleeper:SetResistance(2)
    inst.components.sleeper:SetSleepTest(ShouldSleepTest)
    inst.components.sleeper:SetWakeTest(DefaultWakeTest)

    inst:AddComponent("trader")
    inst.components.trader:Enable()
    inst.components.trader:SetAcceptTest(ShouldAcceptItem)
    inst.components.trader.onaccept = OnGetItemFromPlayer
    inst.components.trader.onrefuse = OnRefuseItem
    inst.components.trader.deleteitemonaccept = false

    inst:AddComponent("sanityaura")
    inst.components.sanityaura.aurafn = CalcSanityAura

    inst:AddComponent("inspectable")
    inst.components.inspectable.getstatus = GetStatus

    inst:AddComponent("locomotor") -- locomotor must be constructed before the stategraph
    inst.components.locomotor.runspeed = TUNING.ANTMAN_RUN_SPEED --5
    inst.components.locomotor.walkspeed = TUNING.ANTMAN_WALK_SPEED --3

    inst:AddComponent("follower")
    inst.components.follower.maxfollowtime = TUNING.ANTMAN_LOYALTY_MAXTIME

    inst:AddComponent("combat")
    inst.components.combat:SetDefaultDamage(TUNING.ANTMAN_DAMAGE)
    inst.components.combat:SetAttackPeriod(TUNING.ANTMAN_ATTACK_PERIOD)
    inst.components.combat:SetKeepTargetFunction(KeepTargetFn)
    inst.components.combat:SetRetargetFunction(3, RetargetFn)
    inst.components.combat:SetTarget(nil)
    inst.components.combat.hiteffectsymbol = "antman_torso"

    inst:AddComponent("named")
    inst.components.named:SetName(GenerateAntmanName())

    inst:AddComponent("eater")
    inst.components.eater:SetCanEatHorrible()
    inst.components.eater:SetStrongStomach(true)
    inst.eattype = math.random(4)
    SetEatType(inst, inst.eattype)

    MakeHauntablePanic(inst)
    MakeMediumBurnableCharacter(inst, "antman_torso")
    MakeMediumFreezableCharacter(inst, "antman_torso")
    MakePoisonableCharacter(inst, "antman_torso")

    inst:SetBrain(brain)
    inst:SetStateGraph("SGant")

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad

    inst:ListenForEvent("attacked", OnAttacked)
    inst:ListenForEvent("suggest_tree_target", function(inst, data)
        if data and data.tree and inst:GetBufferedAction().action ~= ACTIONS.CHOP then
            inst.tree_target = data.tree
        end
    end)

    inst:WatchWorldState("isaporkalypse", OnIsAporkalypse)
    inst:DoTaskInTime(0, function() -- needs a delay otherwise ants spawned during aporkalypse would transforme at (0,0,0)
        OnIsAporkalypse(inst, TheWorld.state.isaporkalypse)
    end)

    return inst
end

return Prefab("antman", fn, assets, prefabs)
