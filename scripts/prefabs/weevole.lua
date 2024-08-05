local assets =
{
    Asset("ANIM", "anim/weevole.zip"),
}

local prefabs =
{
    "weevole_carapace",
    "monstermeat",
}

SetSharedLootTable("weevole_loot",
{
    {'weevole_carapace', 1},
    {'monstermeat',   0.25},
})

local brain = require("brains/weevolebrain")

local function KeepTarget(inst, target)
    return target ~= nil
        and target.components.combat ~= nil
        and target.components.health ~= nil
        and not target.components.health:IsDead()
end

local RETARGET_CANT_TAGS = {"FX", "NOCLICK","INLIMBO", "wall", "weevole", "structure"}
local function Retarget(inst)
    return FindEntity(inst, TUNING.WEEVOLE_TARGET_DIST, function(guy) return inst.components.combat:CanTarget(guy) end, nil, RETARGET_CANT_TAGS)
end

local function OnAttacked(inst, data)
    if data then
        inst.components.combat:SetTarget(data.attacker)
        inst.components.combat:ShareTarget(data.attacker, TUNING.WEEVOLE_SHARE_TARGET_RANGE, function(dude)
            return dude:HasTag("weevole") and not dude.components.health:IsDead()
        end, TUNING.WEEVOLE_SHARE_MAX_NUM)
    end
end

local function OnFlyIn(inst)
    inst.DynamicShadow:Enable(false)
    inst.components.health:SetInvincible(true)
    local x, _, z = inst.Transform:GetWorldPosition()
    inst.Transform:SetPosition(x, 15, z)
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddDynamicShadow()
    inst.entity:AddNetwork()

    MakeCharacterPhysics(inst, 10, .5)

    inst.DynamicShadow:SetSize(1.5, .5)
    inst.Transform:SetSixFaced()

    inst:AddTag("scarytoprey")
    inst:AddTag("monster")
    inst:AddTag("insect")
    inst:AddTag("hostile")
    inst:AddTag("canbetrapped")
    inst:AddTag("smallcreature")
    inst:AddTag("weevole")
    inst:AddTag("animal")

    inst.AnimState:SetBank("weevole")
    inst.AnimState:SetBuild("weevole")
    inst.AnimState:PlayAnimation("idle")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")
    inst:AddComponent("knownlocations")

    -- locomotor must be constructed before the stategraph!
    inst:AddComponent("locomotor")
    inst.components.locomotor:SetSlowMultiplier(1)
    inst.components.locomotor:SetTriggersCreep(false)
    inst.components.locomotor.pathcaps = {ignorecreep = true}
    inst.components.locomotor.walkspeed = TUNING.WEEVOLE_WALK_SPEED
    inst.components.locomotor:SetAllowPlatformHopping(true)  -- boat hopping enable.

    inst:AddComponent("embarker")
    inst:AddComponent("drownable")

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetChanceLootTable("weevole_loot")

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(TUNING.WEEVOLE_HEALTH)

    inst:AddComponent("eater")
    inst.components.eater:SetDiet({FOODTYPE.WOOD, FOODTYPE.SEEDS, FOODTYPE.ROUGHAGE})
    inst.components.eater:SetCanEatRaw()

    inst:AddComponent("combat")
    inst.components.combat.hiteffectsymbol = "body"
    inst.components.combat:SetKeepTargetFunction(KeepTarget)
    inst.components.combat:SetRetargetFunction(3, Retarget)
    inst.components.combat:SetDefaultDamage(TUNING.WEEVOLE_DAMAGE)
    inst.components.combat:SetAttackPeriod(GetRandomMinMax(TUNING.WEEVOLE_PERIOD_MIN, TUNING.WEEVOLE_PERIOD_MAX))
    inst.components.combat:SetRange(TUNING.WEEVOLE_ATTACK_RANGE, TUNING.WEEVOLE_HIT_RANGE)

    inst:SetStateGraph("SGweevole")
    inst:SetBrain(brain)

    MakeHauntablePanic(inst)
    MakePoisonableCharacter(inst)
    MakeSmallBurnableCharacter(inst, "body")
    MakeSmallFreezableCharacter(inst, "body")

    inst:ListenForEvent("fly_in", OnFlyIn) -- matches enter_loop logic so it does not happen a frame late
    inst:ListenForEvent("attacked", OnAttacked)

    return inst
end

return Prefab("weevole", fn, assets, prefabs)
