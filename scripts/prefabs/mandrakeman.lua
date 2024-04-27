local assets =
{
    Asset("ANIM", "anim/elderdrake_basic.zip"),
    Asset("ANIM", "anim/elderdrake_actions.zip"),
    Asset("ANIM", "anim/elderdrake_attacks.zip"),
    Asset("ANIM", "anim/elderdrake_build.zip"),
}

local prefabs =
{
    "livinglog",
}

SetSharedLootTable("mandrakeman", {
    {"livinglog", 1.0},
    {"livinglog", 1.0},
})

local function GetStatus(inst)
    if inst.components.follower.leader then
        return "FOLLOWER"
    end
end

local function ontalk(inst, script)
    inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/elderdrake/dissy")
end

local function CalcSanityAura(inst, observer)
    if inst.components.follower and inst.components.follower.leader == observer then
        return TUNING.SANITYAURA_SMALL
    end

    return 0
end

local function ShouldAcceptItem(inst, item)
    if inst:HasTag("grumpy") then
        return false
    end

    if item.components.equippable and item.components.equippable.equipslot == EQUIPSLOTS.HEAD then
        return true
    end

    if inst.components.eater:CanEat(item) then
        return not (inst.components.eater:PrefersToEat(item)
            and inst.components.follower.leader
            and inst.components.follower:GetLoyaltyPercent() > 0.9)
    end

    return false
end

local function OnGetItemFromPlayer(inst, giver, item)
    --I eat food
    if inst.components.eater:CanEat(item) then
        if inst.components.eater:PrefersToEat(item) then
            if inst.components.combat.target and inst.components.combat.target == giver then
                inst.components.combat:SetTarget(nil)
            elseif giver.components.leader then
                inst.SoundEmitter:PlaySound("dontstarve/common/makeFriend")
                giver.components.leader:AddFollower(inst)
                inst.components.follower:AddLoyaltyTime(TUNING.RABBIT_CARROT_LOYALTY)
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

local MAX_TARGET_SHARES = 5
local SHARE_TARGET_DIST = 30
local DEFEND_HOME_DIST = 30
local RETARGET_DIST = 10
local RETARGET_MUST_TAGS = {"character", "player"}
local RETARGET_NO_TAGS = {"mandrakeman", "playerghost", "FX", "NOCLICK", "DECOR", "INLIMBO"}

local function OnAttacked(inst, data)
    inst.components.combat:SetTarget(data.attacker)
    inst.components.combat:ShareTarget(data.attacker, SHARE_TARGET_DIST, function(ent) return ent:HasTag("mandrakeman") end, MAX_TARGET_SHARES)
end

local function OnNewTarget(inst, data)
    inst.components.combat:ShareTarget(data.target, SHARE_TARGET_DIST, function(ent) return ent:HasTag("mandrakeman") end, MAX_TARGET_SHARES)
end

local function RetargetFn(inst)
    local defense_target = inst
    local home = inst.components.homeseeker and inst.components.homeseeker.home
    if home and inst:GetDistanceSqToInst(home) < DEFEND_HOME_DIST * DEFEND_HOME_DIST then
        defense_target = home
    end

    local invader = FindEntity(defense_target or inst, RETARGET_DIST, function(ent)
        return inst:HasTag("grumpy")
    end, RETARGET_MUST_TAGS, RETARGET_NO_TAGS)

    return invader
end

local function KeepTargetFn(inst, target)
    local home = inst.components.homeseeker and inst.components.homeseeker.home
    if home then
        return home:GetDistanceSqToInst(target) < DEFEND_HOME_DIST * DEFEND_HOME_DIST
            and home:GetDistanceSqToInst(inst) < DEFEND_HOME_DIST * DEFEND_HOME_DIST
    end

    return inst.components.combat:CanTarget(target)
end

local function GetGiveUpString(combatcmp, target)
    return "MANDRAKEMAN_GIVEUP", math.random(#STRINGS.MANDRAKEMAN_GIVEUP)
end

local function GetBattleCryString(combatcmp, target)
    local strtbl =
        target and
        target.components.inventory and
        target.components.inventory:FindItem(function(item) return item:HasTag("mandrake") end) and
        "MANDRAKEMAN_MANDRAKE_BATTLECRY" or
        "MANDRAKEMAN_BATTLECRY"
    return strtbl, math.random(#STRINGS[strtbl])
end

local function OnDeath(inst, data)
    inst.SoundEmitter:PlaySound("dontstarve/creatures/mandrake/death")
    local x, y, z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, TUNING.MANDRAKE_SLEEP_RANGE, {"sleeper"})
    for _, v in pairs(ents) do
        if v.components.sleeper then
            v.components.sleeper:AddSleepiness(10, TUNING.MANDRAKE_SLEEP_TIME)
        end
    end
end

local function transform(inst, grumpy)
    if grumpy then
        inst.AnimState:Show("head_angry")
        inst.AnimState:Hide("head_happy")
        inst:AddTag("grumpy")
    else
        inst.AnimState:Hide("head_angry")
        inst.AnimState:Show("head_happy")
        inst.sg:GoToState("happy")
        inst:RemoveTag("grumpy")
    end
end

local function OnPhaseChange(inst)
    if TheWorld.state.phase == "night" and (TheWorld.state.moonphase == "full" or TheWorld.state.moonphase == "blood") then
        if inst:HasTag("grumpy") then
            inst:DoTaskInTime(1 + math.random(), function() transform(inst, false) end )
        end
    else
        if not inst:HasTag("grumpy") then
            inst:DoTaskInTime(1 + math.random(), function() transform(inst,true) end )
        end
    end
end

local function OnEntityWake(inst)
    OnPhaseChange(inst)
end

local function OnEntitySleep(inst)
    if inst.checktask then
        inst.checktask:Cancel()
        inst.checktask = nil
    end
end

local brain = require("brains/bunnymanbrain")

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddDynamicShadow()
    inst.entity:AddLightWatcher()
    inst.entity:AddNetwork()

    inst.AnimState:SetBuild("elderdrake_build")
    inst.AnimState:SetBank("elderdrake")
    inst.AnimState:PlayAnimation("idle_loop")
    inst.AnimState:Hide("hat")
    inst.AnimState:Hide("head_happy")

    inst.DynamicShadow:SetSize(1.5, 0.75)

    inst.Transform:SetFourFaced()
    inst.Transform:SetScale(1.25, 1.25, 1.25)

    inst:AddTag("character")
    inst:AddTag("mandrakeman")
    inst:AddTag("scarytoprey")
    inst:AddTag("grumpy")
    inst:AddTag("trader") -- trader (from trader component) added to pristine state for optimization
    inst:AddTag("_named") -- Sneak these into pristine state for optimization

    MakeCharacterPhysics(inst, 50, 0.5)

    inst:AddComponent("talker")
    inst.components.talker.ontalk = ontalk -- OnTalk ? ontalkfn?
    inst.components.talker.fontsize = 24
    inst.components.talker.font = TALKINGFONT
    inst.components.talker.offset = Vector3(0, -500, 0)
    inst.components.talker:MakeChatter()

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    -- Remove these tags so that they can be added properly when replicating components below
    inst:RemoveTag("_named")

    inst:AddComponent("inventory")

    inst:AddComponent("knownlocations")

    inst:AddComponent("locomotor") -- locomotor must be constructed before the stategraph
    inst.components.locomotor.runspeed = TUNING.MANDRAKEMAN_RUN_SPEED
    inst.components.locomotor.walkspeed = TUNING.MANDRAKEMAN_WALK_SPEED

    inst:AddComponent("eater")
    inst.components.eater:SetDiet({FOODTYPE.VEGGIE}, {FOODTYPE.VEGGIE})
    inst.components.eater:SetCanEatRaw()

    inst:AddComponent("combat")
    inst.components.combat.hiteffectsymbol = "elderdrake_torso"
    inst.components.combat.panic_thresh = TUNING.MANDRAKEMAN_PANIC_THRESH
    inst.components.combat.GetBattleCryString = GetBattleCryString
    inst.components.combat.GetGiveUpString = GetGiveUpString
    inst.components.combat:SetDefaultDamage(TUNING.MANDRAKEMAN_DAMAGE)
    inst.components.combat:SetAttackPeriod(TUNING.MANDRAKEMAN_ATTACK_PERIOD)
    inst.components.combat:SetKeepTargetFunction(KeepTargetFn)
    inst.components.combat:SetRetargetFunction(3, RetargetFn)

    inst:AddComponent("named")
    inst.components.named.possiblenames = STRINGS.MANDRAKEMANNAMES
    inst.components.named:PickNewName()

    inst:AddComponent("follower")
    inst.components.follower.maxfollowtime = TUNING.PIG_LOYALTY_MAXTIME

    inst:AddComponent("health")
    inst.components.health:StartRegen(TUNING.MANDRAKEMAN_HEALTH_REGEN_AMOUNT, TUNING.MANDRAKEMAN_HEALTH_REGEN_PERIOD)
    inst.components.health:SetMaxHealth(TUNING.MANDRAKEMAN_HEALTH)

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetChanceLootTable("mandrakeman")

    inst:AddComponent("trader")
    inst.components.trader:SetAcceptTest(ShouldAcceptItem)
    inst.components.trader.onaccept = OnGetItemFromPlayer
    inst.components.trader.onrefuse = OnRefuseItem
    inst.components.trader:Enable()

    inst:AddComponent("sanityaura")
    inst.components.sanityaura.aurafn = CalcSanityAura

    inst:AddComponent("sleeper")
    inst.components.sleeper:SetResistance(2)
    inst.components.sleeper:SetNocturnal(true)

    inst:AddComponent("inspectable")
    inst.components.inspectable.getstatus = GetStatus

    inst:SetBrain(brain)
    inst:SetStateGraph("SGmandrakeman")

    MakeMediumFreezableCharacter(inst, "elderdrake_torso")
    MakeMediumBurnableCharacter(inst, "elderdrake_torso")
    MakePoisonableCharacter(inst, "elderdrake_torso")
    MakeHauntablePanic(inst)

    inst:ListenForEvent("attacked", OnAttacked)
    inst:ListenForEvent("newcombattarget", OnNewTarget)
    inst:ListenForEvent("death", OnDeath)

    inst:WatchWorldState("phase", OnPhaseChange)
    OnPhaseChange(inst)

    inst.OnEntityWake = OnEntityWake
    inst.OnEntitySleep = OnEntitySleep

    return inst
end


return Prefab("mandrakeman", fn, assets, prefabs)
