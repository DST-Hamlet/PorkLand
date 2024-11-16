local brain = require("brains/pl_frogbrain")

local poisonassets =
{
    Asset("ANIM", "anim/frog.zip"),
    Asset("ANIM", "anim/frog_water.zip"),
    Asset("ANIM", "anim/frog_treefrog_build.zip"),
}

local prefabs =
{
    "froglegs",
    "frogsplash",
    "venomgland",
    "froglegs_poison",
}

SetSharedLootTable("frog_poison", {
    {"froglegs_poison", 1},
    -- {"venomgland",    0.5}, Remove gland because it wouldn't drop any in Hamlet due to a bug
})

local POISON_SOUNDS = {
    attack_spit = "dontstarve_DLC003/creatures/enemy/frog_poison/attack_spit",
    attack_voice = "dontstarve_DLC003/creatures/enemy/frog_poison/attack_spit",
    die = "dontstarve_DLC003/creatures/enemy/frog_poison/death",
    grunt = "dontstarve_DLC003/creatures/enemy/frog_poison/grunt",
    walk = "dontstarve/frog/walk",
    splat = "dontstarve/frog/splat",
    wake = "dontstarve/frog/wake",
}

local function OnHitOther(inst, other)
    inst.components.thief:StealItem(other)
end

local RETARGET_MUST_TAGS = {"_combat", "_health"}
local RETARGET_CANT_TAGS = {"merm", "FX", "NOCLICK", "INLIMBO", "hippopotamoose"}
local function Retarget(inst)
    if not inst.components.health:IsDead() and not inst.components.sleeper:IsAsleep() then
        return FindEntity(inst, TUNING.FROG_TARGET_DIST, function(ent)
            if ent.components.combat and ent.components.health and not ent.components.health:IsDead() then
                return ent.components.inventory ~= nil or ent:HasTag("insect")
            end
        end, RETARGET_MUST_TAGS, RETARGET_CANT_TAGS)
    end
end

local function ShouldSleep(inst)
    if inst.components.knownlocations:GetLocation("home") ~= nil or inst:HasTag("aporkalypse_cleanup") then
        return false -- frogs either go to their home, or just sit on the ground.
    end

    -- Homeless frogs will sleep at night.
    return TheWorld.state.isnight
end

local function ShouldSilent(inst)
    return (inst.components.freezable and inst.components.freezable:IsFrozen())
        or (inst.components.sleeper and inst.components.sleeper:IsAsleep())
        or inst.sg:HasStateTag("falling")
end

local function OnAttacked(inst, data)
    inst.components.combat:SetTarget(data.attacker)
    inst.components.combat:ShareTarget(data.attacker, 30, function(ent) return ent:HasTag("frog") and not ent.components.health:IsDead() end, 5)
end

local function OnGoingHome(inst)
    SpawnPrefab("frogsplash").Transform:SetPosition(inst.Transform:GetWorldPosition())

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

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddDynamicShadow()
    inst.entity:AddNetwork()

    MakeAmphibiousCharacterPhysics(inst, 10, 0.3)

    inst.DynamicShadow:SetSize(1.5, 0.75)
    inst.Transform:SetFourFaced()

    inst.AnimState:SetBank("frog")
    inst.AnimState:SetBuild("frog_treefrog_build")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("animal")
    inst:AddTag("prey")
    inst:AddTag("hostile")
    inst:AddTag("smallcreature")
    inst:AddTag("frog")
    inst:AddTag("canbetrapped")
    inst:AddTag("duskok")
    inst:AddTag("scarytoprey")

    inst.sounds = POISON_SOUNDS

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("locomotor") -- locomotor must be constructed before the stategraph
    inst.components.locomotor.walkspeed = 4
    inst.components.locomotor.runspeed = 8
    inst.components.locomotor:SetAllowPlatformHopping(true)
    inst.components.locomotor.pathcaps = {allowocean = true}

    -- -- boat hopping enable.
    -- inst.components.locomotor:SetAllowPlatformHopping(true)
    -- inst:AddComponent("embarker")
    inst:AddComponent("drownable")

    inst:SetBrain(brain)
    inst:SetStateGraph("SGpl_frog")

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(TUNING.FROG_HEALTH)

    inst:AddComponent("combat")
    inst.components.combat:SetDefaultDamage(TUNING.FROG_DAMAGE)
    inst.components.combat:SetAttackPeriod(TUNING.FROG_ATTACK_PERIOD)
    inst.components.combat:SetRetargetFunction(3, Retarget)
    inst.components.combat.onhitotherfn = OnHitOther

    inst:AddComponent("thief")

    inst:AddComponent("eater")

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetChanceLootTable("frog_poison")

    inst:AddComponent("knownlocations")
    inst:AddComponent("inspectable")

    inst:AddComponent("sleeper")
    inst.components.sleeper:SetSleepTest(ShouldSleep)

    MakeAmphibious(inst, "frog", "frog_water", ShouldSilent)
    inst:ListenForEvent("attacked", OnAttacked)
    inst:ListenForEvent("goinghome", OnGoingHome)

    MakeTinyFreezableCharacter(inst, "frogsack")
    MakeSmallBurnableCharacter(inst, "frogsack")
    MakeHauntablePanic(inst)

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad

    return inst
end

return  Prefab("frog_poison", fn, poisonassets, prefabs)
