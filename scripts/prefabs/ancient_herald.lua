local assets =
{
    Asset("ANIM", "anim/ancient_spirit.zip"),
}

local prefabs =
{
    "ancient_remnant",
}

local function CalcSanityAura(inst, observer)
    if inst.components.combat.target then
        return -TUNING.SANITYAURA_HUGE
    else
        return -TUNING.SANITYAURA_LARGE
    end
end

local RETARGET_DIST = 30
local RETARGET_MUST_TAGS = {"player"}
local RETARGET_NO_TAGS = {"playerghost"}

local function RetargetFn(inst)
    return FindEntity(inst, RETARGET_DIST, function(ent)
        return inst.components.combat:CanTarget(ent)
    end, RETARGET_MUST_TAGS, RETARGET_NO_TAGS)
end

local function KeepTargetFn(inst, target)
    return inst.components.combat:CanTarget(target)
end

local function OnAttacked(inst, data)
    inst.components.combat:SetTarget(data.attacker)
end

local function OnSave(inst, data)
    data.aporkalypse_cleanup = inst:HasTag("aporkalypse_cleanup")
end

local function OnLoad(inst, data)
    if data and data.aporkalypse_cleanup then
        inst:AddTag("aporkalypse_cleanup")
    end
end

local function OnIsAporkalypse(inst, isaporkalypse)
    if not isaporkalypse and inst:HasTag("aporkalypse_cleanup") then
        if inst:IsAsleep() then
            inst:Remove() -- don't care about anim
        else
            inst.sg:GoToState("disappear")
        end
    end
end

local function PushMusic(inst)
    if ThePlayer == nil then
        inst._playingmusic = false
    elseif ThePlayer:IsNear(inst, inst._playingmusic and 40 or 20) then
        inst._playingmusic = true
        ThePlayer:PushEvent("triggeredevent", {name = "ancient_herald"})
    elseif inst._playingmusic and not ThePlayer:IsNear(inst, 50) then
        inst._playingmusic = false
    end
end

local function OnMixerDirty(inst, data)
    if inst.mixer:value() then
        TheMixer:PushMix("shadow")
    else
        TheMixer:PopMix("shadow")
    end
end

local function OnRemoveEntity_Client(inst)
    TheMixer:PopMix("shadow")
end

local brain = require("brains/ancientheraldbrain")

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddDynamicShadow()
    inst.entity:AddNetwork()

    MakeCharacterPhysics(inst, 1000, 0.5)
    if TheWorld:HasTag("porkland") then
        inst.Physics:ClearCollidesWith(COLLISION.LIMITS)
    end

    inst.AnimState:SetBank("ancient_spirit")
    inst.AnimState:SetBuild("ancient_spirit")
    inst.AnimState:PlayAnimation("idle", true)

    inst.Transform:SetScale(1.25, 1.25,1.25)
    inst.Transform:SetSixFaced()

    inst:AddTag("epic")
    inst:AddTag("monster")
    inst:AddTag("hostile")
    inst:AddTag("ancient")
    inst:AddTag("shadow")
    inst:AddTag("scarytoprey")
    inst:AddTag("largecreature")
    inst:AddTag("laser_immune")
    inst:AddTag("ancient_herald")
    inst:AddTag("shadow_aligned")

    inst.mixer = net_bool(inst.GUID, "antqueen.mixer", "mixerdirty")

    inst.entity:SetPristine()

    if not TheNet:IsDedicated() then
        inst._playingmusic = false
        inst:DoPeriodicTask(1, PushMusic, 0)
    end

    if not TheWorld.ismastersim then
        inst:ListenForEvent("mixerdirty", OnMixerDirty)

        inst.OnRemoveEntity = OnRemoveEntity_Client

        return inst
    end

    inst:AddComponent("locomotor") -- locomotor must be constructed before the stategraph
    inst.components.locomotor.walkspeed = TUNING.GHOST_SPEED
    inst.components.locomotor.runspeed = TUNING.GHOST_SPEED
    inst.components.locomotor.pathcaps = {ignorecreep = true, allowocean = true}

    inst:AddComponent("sanityaura")
    inst.components.sanityaura.aurafn = CalcSanityAura

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(TUNING.ANCIENT_HERALD_HEALTH)
    inst.components.health.destroytime = 3

    inst:AddComponent("combat")
    inst.components.combat:SetDefaultDamage(TUNING.ANCIENT_HERALD_DAMAGE)
    inst.components.combat:SetRetargetFunction(3, RetargetFn)
    inst.components.combat:SetKeepTargetFunction(KeepTargetFn)

    inst:AddComponent("lootdropper")
    -- for wheeler_tracker
    -- inst.components.lootdropper:AddExternalLoot("ancient_remnant")
    -- inst.components.lootdropper:AddExternalLoot("nightmarefuel")

    inst:AddComponent("inspectable")

    inst:AddComponent("knownlocations")

    inst:AddComponent("timer")

    inst:SetBrain(brain)
    inst:SetStateGraph("SGancientherald")

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad
    inst.OnRemoveEntity = OnRemoveEntity_Client

    inst:ListenForEvent("attacked", OnAttacked)
    inst:WatchWorldState("isaporkalypse", OnIsAporkalypse)
    OnIsAporkalypse(inst, TheWorld.state.isaporkalypse)

    return inst
end

return Prefab("ancient_herald", fn, assets, prefabs)
