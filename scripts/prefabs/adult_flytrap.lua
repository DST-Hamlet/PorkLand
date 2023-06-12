require "stategraphs/SGadultflytrap"

local assets = {
    Asset("ANIM", "anim/venus_flytrap_lg_build.zip"),
	Asset("ANIM", "anim/venus_flytrap_planted.zip"),
}

local prefabs = {
    "plantmeat",
    "venus_stalk",
    "vine",
    "nectar_pod",
}

SetSharedLootTable('adult_flytrap', {
    {'plantmeat',   1.0},
    {'plantmeat',   0.5},
    {'vine',        1.0},
    {'vine',        0.5},
    {'venus_stalk', 1.0},
    {'nectar_pod',  1.0},
    {'nectar_pod',  0.3},
})

local function FindFood(inst,guy)
	if guy.components.inventory ~= nil then
		return guy.components.inventory:FindItem(function(item)
            return inst.components.eater:CanEat(item)
		end)
	end
end

local function SpawnMeanFlytrap(inst)
    local pt = Vector3(inst.Transform:GetWorldPosition())
    local angle = math.random() * 360
    if angle > 360 then
        angle = angle - 360
    end
    local radius = 15
    local offset = FindWalkableOffset(pt, angle*DEGREES, radius, 20, true, false) -- try avoiding walls
    if offset ~= nil then
    local ents = TheSim:FindEntities(pt.x, pt.y, pt.z, radius, {"flytrap"})
        if #ents < 5 then
            local plant = SpawnPrefab("mean_flytrap")
            local pt = pt + offset
            plant.Transform:SetPosition(pt.x,pt.y,pt.z)
            plant.sg:GoToState("enter")
            inst.sg:GoToState("taunt")
        end
    end

    inst.SetGrowTask(inst)
end

local function OnNewTarget(inst, data)
    inst.keeptargetevenifnofood = nil
end

local function SetGrowTask(inst, time)
    if not time then
        time = math.random() * (TUNING.TOTAL_DAY_TIME*2) + (TUNING.TOTAL_DAY_TIME*2)
    end

    if inst.growtask ~= nil then
        inst.growtask:Cancel()
        inst.growtask = nil
    end

    inst.growtaskinfo = nil
    inst.growtask, inst.growtaskinfo = inst:ResumeTask(time, SpawnMeanFlytrap)
end

local function retargetfn(inst)
    return FindEntity(inst, TUNING.ADULT_FLYTRAP_ATTACK_DIST, function(guy)
        if guy:HasTag("plantkin") and (guy:GetDistanceSqToInst(inst) > TUNING.FLYTRAP_TARGET_DIST * TUNING.FLYTRAP_TARGET_DIST or not FindFood(inst,guy)) then
            return false
        end
        if guy.components.combat ~= nil and guy.components.health ~= nil and not guy.components.health:IsDead() then
            return (guy.components.combat.target == inst or guy:HasTag("character") or guy:HasTag("monster") or guy:HasTag("animal")) and not guy:HasTag("flytrap") and not (guy.prefab == inst.prefab)
        end
    end)
end

local function ShouldKeepTarget(inst, target)
    if target:HasTag("plantkin") then
        return false
    end
    if target and target:IsValid() and target.components.health ~= nil and not target.components.health:IsDead() then
        local distsq = target:GetDistanceSqToInst(inst)
        return distsq < TUNING.ADULT_FLYTRAP_STOPATTACK_DIST*TUNING.ADULT_FLYTRAP_STOPATTACK_DIST
    else
        return false
    end
end

local function OnAttacked(inst, data)
    inst.components.combat:SetTarget(data.attacker)
end

local function OnSave(inst, data)
    if inst.growtaskinfo ~= nil then
        data.growtask = inst:TimeRemainingInTask(inst.growtaskinfo)
    end
    if inst:HasTag("spawned")then
        data.spawned = true
    end
end

local function OnLoad(inst, data)
    if data ~= nil then
        if data.growtask ~= nil then
            SetGrowTask(inst, data.growtask)
        end
        if data.spawned ~= nil then
            inst:AddTag("spawned")
        end
    end
end

local function OnSpawn(inst)
    if not inst:HasTag("spawned") then
        inst.start_scale = 1.4
        inst.inc_scale = (1.8 - 1.4) /5
        inst.sg:GoToState("grow")
        inst:AddTag("spawned")
    else
        inst.sg:GoToState("idle")
        inst.Transform:SetScale(1.8,1.8,1.8)
        inst.Transform:SetRotation(math.random(360))
    end
end

local function SanityAura(inst, observer)
    return not observer:HasTag("plantkin") and -TUNING.SANITYAURA_MED or 0
end

local function fn()
	local inst = CreateEntity()
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
    inst.entity:AddPhysics()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeObstaclePhysics(inst, .25)

    inst.Transform:SetFourFaced()
    inst.MiniMapEntity:SetIcon("mean_flytrap.tex")

    inst.AnimState:Hide("root")
    inst.AnimState:Hide("leaf")
    inst.AnimState:SetBank("venus_flytrap_planted")
    inst.AnimState:SetBuild("venus_flytrap_lg_build")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("character")
    inst:AddTag("scarytoprey")
    inst:AddTag("monster")
    inst:AddTag("flytrap")
    inst:AddTag("hostile")
    inst:AddTag("animal")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(TUNING.ADULT_FLYTRAP_HEALTH)

    inst:AddComponent("sanityaura")
	inst.components.sanityaura.aurafn = SanityAura

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetChanceLootTable('adult_flytrap')

    inst:AddComponent("combat")
    inst.components.combat:SetRange(TUNING.ADULT_FLYTRAP_ATTACK_DIST)
    inst.components.combat:SetDefaultDamage(TUNING.ADULT_FLYTRAP_DAMAGE)
    inst.components.combat:SetAttackPeriod(TUNING.ADULT_FLYTRAP_ATTACK_PERIOD)
    inst.components.combat:SetRetargetFunction(GetRandomWithVariance(2, 0.5), retargetfn)
    inst.components.combat:SetKeepTargetFunction(ShouldKeepTarget)

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad
    inst.SetGrowTask = SetGrowTask
    inst.OnSpawn = OnSpawn
    inst.SpawnMeanFlytrap = SpawnMeanFlytrap

    inst:ListenForEvent("newcombattarget", OnNewTarget)
    inst:ListenForEvent("attacked", OnAttacked)

    inst:SetStateGraph("SGadultflytrap")

    SetGrowTask(inst)
    MakeHauntablePanic(inst)
    MakeLargeFreezableCharacter(inst)
    MakeMediumBurnableCharacter(inst, "stem")

    inst:DoTaskInTime(0, OnSpawn(inst))

    return inst
end

return Prefab("adult_flytrap", fn, assets, prefabs)
