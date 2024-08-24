local WAKE_TO_FOLLOW_DISTANCE = 14
local SLEEP_NEAR_LEADER_DISTANCE = 7

local assets =
{
    Asset("ANIM", "anim/ro_bin.zip"),
    Asset("ANIM", "anim/ro_bin_water.zip"),
    Asset("ANIM", "anim/ro_bin_build.zip"),
}

local prefabs =
{
    "ro_bin_gizzard_stone",
    "die_fx",
    "chesterlight",
    "sparklefx",
}

local function ShouldWakeUp(inst)
    return DefaultWakeTest(inst) or not inst.components.follower:IsNearLeader(WAKE_TO_FOLLOW_DISTANCE)
end

local function ShouldSleep(inst)
    return DefaultSleepTest(inst)
        and not inst.sg:HasStateTag("open")
        and inst.components.follower:IsNearLeader(SLEEP_NEAR_LEADER_DISTANCE)
        and TheWorld.state.moonphase ~= "full" -- leftover stuff from chester?
end

local function ShouldKeepTarget(ifnst, target)
    return false -- chester can't attack, and won't sleep if he has a target *ro bin
end

local function OnOpen(inst)
    if not inst.components.health:IsDead() then
        inst.sg:GoToState("open")
    end
end

local function OnClose(inst)
    if not inst.components.health:IsDead() then
        inst.sg:GoToState("close")
    end
end

-- eye bone was killed/destroyed
local function OnStopFollowing(inst)
    inst:RemoveTag("companion")
end

local function OnStartFollowing(inst)
    inst:AddTag("companion")
end

local brain = require("brains/chesterbrain")

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddDynamicShadow()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeAmphibiousCharacterPhysics(inst, 1, 0.5)

    inst.AnimState:SetBank("ro_bin")
    inst.AnimState:SetBuild("ro_bin_build")

    inst.DynamicShadow:SetSize(2, 1.5)

    inst.MiniMapEntity:SetIcon("ro_bin.tex")

    inst.Transform:SetFourFaced()

    inst:AddTag("companion")
    inst:AddTag("character")
    inst:AddTag("scarytoprey")
    inst:AddTag("chester")
    inst:AddTag("ro_bin")
    inst:AddTag("notraptrigger")
    inst:AddTag("cattoy")
    inst:AddTag("amphibious")
    inst:AddTag("noauradamage")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("combat")
    inst.components.combat.hiteffectsymbol = "robin_body"
    inst.components.combat:SetKeepTargetFunction(ShouldKeepTarget)

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(TUNING.CHESTER_HEALTH)
    inst.components.health:StartRegen(TUNING.CHESTER_HEALTH_REGEN_AMOUNT, TUNING.CHESTER_HEALTH_REGEN_PERIOD)

    inst:AddComponent("inspectable")
	inst.components.inspectable:RecordViews()

    inst:AddComponent("locomotor")
    inst.components.locomotor.walkspeed = 5
    inst.components.locomotor.runspeed = 10 * 0.7

    inst:AddComponent("follower")

    inst:ListenForEvent("stopfollowing", OnStopFollowing)
    inst:ListenForEvent("startfollowing", OnStartFollowing)

    inst:AddComponent("knownlocations")

    inst:AddComponent("container")
    inst.components.container:WidgetSetup("chester")
    inst.components.container.onopenfn = OnOpen
    inst.components.container.onclosefn = OnClose

    inst:AddComponent("sleeper")
    inst.components.sleeper:SetResistance(3)
    inst.components.sleeper.testperiod = GetRandomWithVariance(6, 2)
    inst.components.sleeper:SetSleepTest(ShouldSleep)
    inst.components.sleeper:SetWakeTest(ShouldWakeUp)

    MakeMediumBurnableCharacter(inst, "robin_body")
    MakePoisonableCharacter(inst)
    MakeHauntablePanic(inst)
    MakeAmphibious(inst, "ro_bin", "ro_bin")

    inst:SetBrain(brain)
    inst:SetStateGraph("SGro_bin")

    inst:DoTaskInTime(0, function(inst)
        -- We somehow got a ro bin without a gizzard stone. Kill it! Kill it with fire!
        if not TheSim:FindFirstEntityWithTag("ro_bin_gizzard_stone") then
            inst:Remove()
        end
    end)

    return inst
end

return Prefab("ro_bin", fn, assets, prefabs)
