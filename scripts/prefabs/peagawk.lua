local assets =
{
    Asset("ANIM", "anim/peagawk.zip"),
    Asset("ANIM", "anim/eyebush.zip"),
    -- Asset("SOUND", "sound/perd.fsb"),
}

local prefabs =
{
    "drumstick",
    "peagawkfeather",
}

local loot =
{
    "drumstick",
    "drumstick",
    "peagawkfeather",
}

local brain = require("brains/peagawkbrain")

local anim_to_bush = {
    [1] = 2,
    [2] = 1,
    [3] = 4,
    [4] = 3,
    [5] = 6,
    [6] = 5,
    [7] = 7,
}

local function refreshart(inst)
    for i = 1, TUNING.PEAGAWK_TAIL_FEATHERS_MAX do
        if inst.feathers < i then
            inst.AnimState:Hide("perd_tail_" .. i)
            inst.AnimState:Hide("eye_" .. anim_to_bush[i])
            inst.AnimState:Hide("plume_" .. anim_to_bush[i])
        else
            inst.AnimState:Show("perd_tail_" .. i)
            inst.AnimState:Show("eye_" .. anim_to_bush[i])
            inst.AnimState:Show("plume_" .. anim_to_bush[i])
        end
    end

    inst:DoTaskInTime(0.1, function()
        if inst.feathers > 0 then
            inst.components.pickable.canbepicked = true
            inst.components.pickable.hasbeenpicked = false
        end
    end)
end

local function TransformToBush(inst, ignore_state)
    inst.AnimState:SetBank("eyebush")
    inst.AnimState:SetBuild("eyebush")
    inst.components.inspectable.nameoverride = "peagawk_bush"

    if not ignore_state then
        inst.sg:GoToState("idle")
    end

    inst.is_bush = true
end

local function TransformToAnimal(inst, ignore_state)
    inst.AnimState:SetBank("peagawk")
    inst.AnimState:SetBuild("peagawk")
    inst.components.inspectable.nameoverride = nil

    if not ignore_state then
        inst.sg:GoToState("appear")
    end

    inst.is_bush = false
end

local function canbepicked(self)
    return self.inst.feathers and self.inst.feathers >= 1 and self.canbepicked
end

local function OnPicked(inst, picker, _loot)
    if inst.components.sleeper.isasleep then
        inst.components.sleeper:WakeUp()
    elseif inst.is_bush then
        inst.AnimState:PlayAnimation("picked", false)
    end

    inst.feathers = inst.feathers - 1
    refreshart(inst)
end

local function OnRegen(inst, data)
    if data and data.name and string.find(data.name, "regen") then
        inst.feathers = inst.feathers + 1
        refreshart(inst)
    end
end

local function StartRegenTimer(inst, regentime)
    if inst.feathers < TUNING.PEAGAWK_TAIL_FEATHERS_MAX then
        local timer = inst.components.timer
        local longest_timeleft = 0
        for name, data in pairs(timer.timers) do
            local timeleft = timer:GetTimeLeft(name)
            if string.find(name, "regen") and timeleft > longest_timeleft then
                longest_timeleft = timeleft
            end
        end
        timer:StartTimer("regen" .. GetTime(), longest_timeleft + regentime)
    end
end

local SLEEP_NEAR_ENEMY_DISTANCE = 14
local function ShouldSleep(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    return DefaultSleepTest(inst) and not IsAnyPlayerInRange(x, y, z, SLEEP_NEAR_ENEMY_DISTANCE)
end

local function OnSave(inst, data)
    data.feathers = inst.feathers
end

local function OnLoad(inst, data)
    if data then
        inst.feathers = data.feathers
    end

    refreshart(inst)
end

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddDynamicShadow()
    inst.entity:AddNetwork()

    inst.DynamicShadow:SetSize(1.5, .75)
    inst.Transform:SetFourFaced()

    MakeCharacterPhysics(inst, 50, .5)

    inst.AnimState:SetBank("peagawk")
    inst.AnimState:SetBuild("peagawk")
    inst.AnimState:Hide("hat")

    inst:AddTag("character")
    inst:AddTag("berrythief")
    inst:AddTag("smallcreature")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.is_bush = false
    inst.feathers = TUNING.PEAGAWK_TAIL_FEATHERS_MAX
    inst.TransformToBush = TransformToBush
    inst.TransformToAnimal = TransformToAnimal

    inst:AddComponent("locomotor")
    inst.components.locomotor.runspeed = TUNING.PEAGAWK_RUN_SPEED
    inst.components.locomotor.walkspeed = TUNING.PEAGAWK_WALK_SPEED

    inst:SetStateGraph("SGpeagawk")
    inst:SetBrain(brain)

    inst:AddComponent("timer")
    inst:ListenForEvent("timerdone", OnRegen)

    inst:AddComponent("pickable")
    inst.components.pickable.useexternaltimer = true
    inst.components.pickable:SetUp("peagawkfeather", TUNING.PEAGAWK_FEATHER_REGROW_TIME)
    inst.components.pickable.CanBePicked = canbepicked
    inst.components.pickable.onpickedfn = OnPicked
    inst.components.pickable.startregentimer = StartRegenTimer
    -- these are useless, just prevent collapse , use timer
    inst.components.pickable.stopregentimer = function() end
    inst.components.pickable.pauseregentimer = function() end
    inst.components.pickable.resumeregentimer = function() end
    inst.components.pickable.getregentimertime = function () return 0 end
    inst.components.pickable.setregentimertime = function() end
    inst.components.pickable.regentimerexists = function() return false end

    inst:AddComponent("eater")
    inst.components.eater:SetDiet({FOODTYPE.VEGGIE}, {FOODTYPE.VEGGIE})  -- Vegetarian
    inst.components.eater:SetCanEatRaw()

    inst:AddComponent("sleeper")
    inst.components.sleeper:SetSleepTest(ShouldSleep)

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(TUNING.PERD_HEALTH)

    inst:AddComponent("combat")
    inst.components.combat.hiteffectsymbol = "pig_torso"
    inst.components.combat:SetDefaultDamage(TUNING.PERD_DAMAGE)
    inst.components.combat:SetAttackPeriod(TUNING.PERD_ATTACK_PERIOD)

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetLoot(loot)

    inst:AddComponent("inventory")
    inst:AddComponent("inspectable")

    MakeHauntablePanic(inst)
    MakePoisonableCharacter(inst)
    MakeMediumBurnableCharacter(inst, "pig_torso")
    MakeMediumFreezableCharacter(inst, "pig_torso")

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad

    return inst
end

return Prefab("peagawk", fn, assets, prefabs)
