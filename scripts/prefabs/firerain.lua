local easing = require("easing")

local assets =
{
    Asset("ANIM", "anim/pl_meteor.zip"),
}

local prefabs =
{
    "lavapool",
    "groundpound_fx",
    "groundpoundring_fx",
    "bombsplash",
    "lava_bombsplash",
    "clouds_bombsplash",
    "firerainshadow",
    "meteor_impact",
    "soundplayer"
}

local function DoStep(inst)
    local x, y, z = inst.Transform:GetLocalPosition()

    if TheWorld.Map:IsImpassableAtPoint(x, y, z) then
        local fx = SpawnPrefab("clouds_bombsplash")
        fx.Transform:SetPosition(x, y, z)
    elseif TheWorld.Map:ReverseIsVisualWaterAtPoint(x, y, z) then
        local fx = SpawnPrefab("bombsplash")
        fx.Transform:SetPosition(x, y, z)

        SpawnWaves(inst, 8, 360, 6)

        inst.SoundEmitter:PlaySound("dontstarve_DLC002/common/volcano/volcano_rock_splash")

        inst.components.groundpounder.burner = false
        inst.components.groundpounder.groundpoundfx = nil
        inst.components.groundpounder:GroundPound()
    else
        if IsSurroundedByLand(x, y, z, 2) then
            if math.random() < TUNING.VOLCANO_FIRERAIN_LAVA_CHANCE then
                local lavapool = SpawnPrefab("lavapool")
                lavapool.Transform:SetPosition(x, y, z)
            else
                local impact = SpawnPrefab("meteor_impact")
                impact.components.timer:StartTimer("remove", TUNING.TOTAL_DAY_TIME * 2)
                impact.Transform:SetPosition(x, y, z)
            end
        end

        inst.SoundEmitter:PlaySound("dontstarve_DLC002/common/volcano/volcano_rock_smash")

        inst.components.groundpounder.numRings = 4
        inst.components.groundpounder.burner = true
        inst.components.groundpounder:GroundPound()
    end

    ShakeAllCameras(CAMERASHAKE.VERTICAL, 0.5, 0.03, 3, inst, 40)
end

local function StartStep(inst)
    local shadow = SpawnPrefab("firerainshadow")
    shadow.Transform:SetPosition(inst.Transform:GetWorldPosition())
    shadow.Transform:SetRotation(math.random(0, 360))

    inst.SoundEmitter:PlaySound("dontstarve_DLC002/common/bomb_fall")
    inst:DoTaskInTime(TUNING.VOLCANO_FIRERAIN_WARNING - (5  * FRAMES), inst.DoStep)
    inst:DoTaskInTime(TUNING.VOLCANO_FIRERAIN_WARNING - (14 * FRAMES), function(inst)
        inst:Show()
        inst.AnimState:PlayAnimation("idle")
        inst.persists = false
        inst:ListenForEvent("animover", inst.Remove)
        inst:ListenForEvent("entitysleep", inst.Remove)
    end)
end

local function StartStepWithDelay(inst, delay)
    if inst.start_step_task then
        inst.start_step_task:Cancel()
        inst.start_step_task = nil
    end

    inst.start_step_task = inst:DoTaskInTime(delay, inst.StartStep)
end

local function firerainfn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("meteor")
    inst.AnimState:SetBuild("pl_meteor")

    inst.Transform:SetFourFaced()

    inst:AddTag("FX")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("groundpounder")
    inst.components.groundpounder.numRings = 4
    inst.components.groundpounder.ringDelay = 0.1
    inst.components.groundpounder.initialRadius = 1
    inst.components.groundpounder.radiusStepDistance = 2
    inst.components.groundpounder.pointDensity = .25
    inst.components.groundpounder.damageRings = 2
    inst.components.groundpounder.destructionRings = 3
    inst.components.groundpounder.destroyer = true
    inst.components.groundpounder.burner = true
    inst.components.groundpounder.ring_fx_scale = 0.75

    inst:AddComponent("combat")
    inst.components.combat:SetDefaultDamage(TUNING.VOLCANO_FIRERAIN_DAMAGE)

    inst.DoStep = DoStep
    inst.StartStep = StartStep
    inst.StartStepWithDelay = StartStepWithDelay

    inst:Hide()

    return inst
end

local function LerpIn(inst)
    local scale = easing.inExpo(inst:GetTimeAlive(), 1, 1 - inst.starting_scale, TUNING.VOLCANO_FIRERAIN_WARNING)

    inst.Transform:SetScale(scale, scale, scale)
    if scale >= inst.starting_scale then
        inst.size_task:Cancel()
        inst.size_task = nil
    end
end

local function OnRemove(inst)
    if inst.size_task then
        inst.size_task:Cancel()
        inst.size_task = nil
    end

    if inst.start_step_task then
        inst.start_step_task:Cancel()
        inst.start_step_task = nil
    end
end

local function Impact(inst)
    inst:Remove()
end

local function shadowfn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("meteor_shadow")
    inst.AnimState:SetBuild("pl_meteor")
    inst.AnimState:PlayAnimation("idle")
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    inst.AnimState:SetLayer(LAYER_BACKGROUND)
    inst.AnimState:SetMultColour(0, 0, 0, 0)
    inst.AnimState:SetSortOrder(3)

    inst.Transform:SetScale(2, 2, 2)

    inst:AddTag("FX")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.persists = false
    inst.starting_scale = 2

    inst:AddComponent("colourtweener")
    inst.components.colourtweener:StartTween({0, 0, 0, 1}, TUNING.VOLCANO_FIRERAIN_WARNING, Impact)

    inst.OnRemoveEntity = OnRemove

    inst.size_task = inst:DoPeriodicTask(FRAMES, LerpIn)

    return inst
end

return  Prefab("firerain", firerainfn, assets, prefabs),
        Prefab("firerainshadow", shadowfn, assets, prefabs)
