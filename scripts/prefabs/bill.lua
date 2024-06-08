local assets =
{
    Asset("ANIM", "anim/bill_agro_build.zip"),
    Asset("ANIM", "anim/bill_calm_build.zip"),
    Asset("ANIM", "anim/bill_basic.zip"),
    Asset("ANIM", "anim/bill_water.zip"),
}

local prefabs =
{
    "bill_quill",
}

local brain = require("brains/billbrain")

SetSharedLootTable( "bill",
{
    {"meat",            1.00},
    {"bill_quill",      1.00},
    {"bill_quill",      1.00},
    {"bill_quill",      0.33},
})

local function CanEat(item)
    return item:HasTag("billfood")
end

local THEIF_MUST_TAGS = {"player"}
local THEIF_NO_TAGS = {"playerghost"}
local function UpdateAggro(inst)
    local lotus_theif = FindClosestEntity(inst, TUNING.BILL_TARGET_DIST, true, THEIF_MUST_TAGS, THEIF_NO_TAGS, nil, function(player, _inst)
        return player.components.inventory:FindItem(CanEat) ~= nil
    end)

    -- If the threat level changes then modify the build.
    inst.AnimState:SetBuild(lotus_theif and "bill_agro_build" or "bill_calm_build")
end

local function KeepTarget(inst, target)
    return inst.components.combat:CanTarget(target) and (target:HasTag("player") and not target:HasTag("playerghost"))
end

local function OnAttacked(inst, data)
    local attacker = data and data.attacker
    inst.components.combat:SetTarget(attacker)
    inst.components.combat:ShareTarget(attacker, 20, function(ent) return ent:HasTag("platapine") end, 2)
end

local function OnItemGet(inst, data)
    if data.item and data.item:IsValid() then
        -- Remove lotus flower when bill picks a lotus.
        -- This is not needed for DS because Pickable:Pick skips loot dropping if picker has no inventory
        data.item:Remove()
    end
end

local function OnTimerDone(inst, data)
    if data.name == "tumble" then
        inst.can_tumble = true -- Lets get ready to tumble!
    end
end

local function OnSave(inst)
    return {
        can_tumble = inst.can_tumble,
    }
end

local function OnLoad(inst, data)
    if not data then
        return
    end

    inst.can_tumble = data.can_tumble or false
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddPhysics()
    inst.entity:AddSoundEmitter()
    inst.entity:AddDynamicShadow()
    inst.entity:AddNetwork()

    MakeAmphibiousCharacterPhysics(inst, 1, 0.5)

    inst.AnimState:SetBank("bill")
    inst.AnimState:SetBuild("bill_calm_build")
    inst.AnimState:PlayAnimation("idle", true)
    inst.DynamicShadow:SetSize(1, 0.75)
    inst.Transform:SetFourFaced()

    inst:AddTag("scarytoprey")
    inst:AddTag("monster")
    inst:AddTag("hostile")
    inst:AddTag("platapine")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.can_tumble = false

    inst:AddComponent("inspectable")

    inst:AddComponent("inventory")

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetChanceLootTable("bill")

    inst:AddComponent("locomotor")
    inst.components.locomotor.runspeed = TUNING.BILL_RUN_SPEED
    inst.components.locomotor.pathcaps = {allowocean = true}

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(TUNING.BILL_HEALTH)

    inst:AddComponent("sleeper")

    inst:AddComponent("eater")
    inst.components.eater:SetPrefersEatingTag("billfood")

    inst:AddComponent("knownlocations")

    inst:AddComponent("combat")
    inst.components.combat:SetDefaultDamage(TUNING.BILL_DAMAGE)
    inst.components.combat:SetAttackPeriod(TUNING.BILL_ATTACK_PERIOD)
    inst.components.combat:SetRange(2, 3)
    inst.components.combat:SetKeepTargetFunction(KeepTarget)
    inst.components.combat.hiteffectsymbol = "body"

    inst:AddComponent("timer")
    inst.components.timer:StartTimer("tumble", 4)

    inst:SetBrain(brain)
    inst:SetStateGraph("SGbill")

    MakeAmphibious(inst, "bill", "bill_water", function() return true end)
    MakeHauntablePanic(inst)
    MakePoisonableCharacter(inst)
    MakeSmallBurnableCharacter(inst, "body")
    MakeTinyFreezableCharacter(inst, "body")

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad

    inst:DoPeriodicTask(1, UpdateAggro)

    inst:ListenForEvent("attacked", OnAttacked)
    inst:ListenForEvent("itemget", OnItemGet)
    inst:ListenForEvent("timerdone", OnTimerDone)

    inst.can_tumble = false

    return inst
end

return Prefab("bill", fn, assets, prefabs)
