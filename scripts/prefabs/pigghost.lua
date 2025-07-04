local assets =
{
    Asset("ANIM", "anim/player_ghost_withhat.zip"),
    Asset("ANIM", "anim/ghost_build.zip"),
    Asset("ANIM", "anim/ghost_pig_build.zip"),
}

local prefabs =
{
}

local function AbleToAcceptTest(inst, item)
    return false, item.prefab == "reviver" and "GHOSTHEART" or nil
end

local function OnDeath(inst)
    inst.components.aura:Enable(false)
end

local function AuraTest(inst, target)
    if inst.components.combat:TargetIs(target) or (target.components.combat.target ~= nil and target.components.combat:TargetIs(inst)) then
        return true
    end

    return not target:HasTag("ghostlyfriend") and not target:HasTag("abigail")
end

local function OnAttacked(inst, data)
    if data.attacker == nil then
        inst.components.combat:SetTarget(nil)
    elseif not data.attacker:HasTag("noauradamage") then
       inst.components.combat:SetTarget(data.attacker)
    end
end

local function KeepTargetFn(inst, target)
    if target and inst:GetDistanceSqToInst(target) < TUNING.GHOST_FOLLOW_DSQ then
        return true
    end

    inst.brain.followtarget = nil

    return false
end

local function OnIsAporkalypse(inst, isaporkalypse)
    if isaporkalypse then
        return
    end

    if inst:HasTag("aporkalypse_cleanup") then
        if inst:IsAsleep() then
            inst:Remove()
        else
            inst.sg:GoToState("dissipate")
        end
    end
end

local function OnEntitySleep(inst)
    if inst:HasTag("aporkalypse_cleanup") and not TheWorld.state.isaporkalypse then
        inst:Remove()
    end
end

local function OnSave(inst, data)
    data.aporkalypse_cleanup = inst:HasTag("aporkalypse_cleanup")
end

local function OnLoad(inst, data)
    if data and data.aporkalypse_cleanup then
        inst:AddTag("aporkalypse_cleanup")
    end
end

local function OnRemove(inst)
    inst.SoundEmitter:KillSound("howl")
end

local brain = require "brains/ghostbrain"

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddLight()
    inst.entity:AddNetwork()

    MakeGhostPhysics(inst, 0.5, 0.5)

    inst.AnimState:SetBank("ghost")
    inst.AnimState:SetBuild("ghost_pig_build")
    inst.AnimState:PlayAnimation("idle", true)
    inst.AnimState:SetBloomEffectHandle("shaders/anim_bloom_ghost.ksh")
    inst.AnimState:SetLightOverride(TUNING.GHOST_LIGHT_OVERRIDE)

    inst.Light:SetIntensity(0.6)
    inst.Light:SetRadius(0.5)
    inst.Light:SetFalloff(0.6)
    inst.Light:Enable(true)
    inst.Light:SetColour(180 / 255, 195 / 255, 225 / 255)

    inst:DoTaskInTime(0, function()
        inst.SoundEmitter:PlaySound("dontstarve/ghost/ghost_howl_LP", "howl")
    end)

    inst:AddTag("monster")
    inst:AddTag("hostile")
    inst:AddTag("ghost")
    inst:AddTag("flying")
    inst:AddTag("noauradamage")

    --trader (from trader component) added to pristine state for optimization
    inst:AddTag("trader")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("locomotor")
    inst.components.locomotor.walkspeed = TUNING.GHOST_SPEED
    inst.components.locomotor.runspeed = TUNING.GHOST_SPEED
    inst.components.locomotor.directdrive = true
    inst.components.locomotor.pathcaps = {ignorewalls = true, ignorecreep = true, allowocean = true}

    inst:AddComponent("sanityaura")
    inst.components.sanityaura.aura = -TUNING.SANITYAURA_MED

    inst:AddComponent("inspectable")

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(TUNING.GHOST_HEALTH)

    inst:AddComponent("combat")
    inst.components.combat.defaultdamage = TUNING.GHOST_DAMAGE
    inst.components.combat.playerdamagepercent = TUNING.GHOST_DMG_PLAYER_PERCENT
    inst.components.combat:SetKeepTargetFunction(KeepTargetFn)

    inst:AddComponent("aura")
    inst.components.aura.radius = TUNING.GHOST_RADIUS
    inst.components.aura.tickperiod = TUNING.GHOST_DMG_PERIOD
    inst.components.aura.auratestfn = AuraTest

    --Added so you can attempt to give hearts to trigger flavour text when the action fails
    inst:AddComponent("trader")
    inst.components.trader:SetAbleToAcceptTest(AbleToAcceptTest)

    inst:SetBrain(brain)
    inst:SetStateGraph("SGghost")

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad

    inst.OnRemove = OnRemove

    inst.OnEntitySleep = OnEntitySleep

    inst:ListenForEvent("death", OnDeath)
    inst:ListenForEvent("attacked", OnAttacked)
    inst:WatchWorldState("isaporkalypse", OnIsAporkalypse)

    return inst
end

local function OnEntityWake_Spawner(inst)
    if TheWorld.state.isaporkalypse then
        inst.components.childspawner:ReleaseAllChildren()
    end
end

local function OnChildSpawned(inst, child)
    child:AddTag("aporkalypse_cleanup")
end

local function spawner_fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddNetwork()

    inst:AddTag("NOBLOCK")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("childspawner")
    inst.components.childspawner.childname = "pigghost"
    inst.components.childspawner.spawnradius = TUNING.ROOM_SMALL_DEPTH / 2
    inst.components.childspawner:SetRegenPeriod(TUNING.PIGGHOST_REGEN_TIME)
    inst.components.childspawner:SetSpawnPeriod(TUNING.PIGGHOST_RELEASE_TIME, TUNING.PIGGHOST_RELEASE_TIME)
    inst.components.childspawner:SetMaxChildren(TUNING.PIGGHOST_MAXCHILDREN)
    inst.components.childspawner:SetSpawnedFn(OnChildSpawned)
    inst.components.childspawner.canspawnfn = function() return TheWorld.state.isaporkalypse end
    inst.components.childspawner:StartSpawning()

    inst.OnEntityWake = OnEntityWake_Spawner

    return inst
end

return Prefab("pigghost", fn, assets, prefabs),
       Prefab("pigghost_spawner", spawner_fn, {}, {})
