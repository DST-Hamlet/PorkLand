local assets = {
    Asset("ANIM", "anim/lantern_fly.zip"),
}

SetSharedLootTable("glowfly", {
    {"lightbulb", 0.1},
})

SetSharedLootTable("glowflyinventory",
{
    {"lightbulb", 1},
})

local brain = require("brains/glowflybrain")

local INTENSITY = .75

local function FadeIn(inst)
    inst.components.fader:StopAll()
    inst.Light:Enable(true)
    if inst:IsAsleep() then
        inst.Light:SetIntensity(INTENSITY)
    else
        inst.Light:SetIntensity(0)
        inst.components.fader:Fade(0, INTENSITY, 3 + math.random() * 2, function(v)
            inst.Light:SetIntensity(v)
        end)
    end
end

local function FadeOut(inst)
    inst.components.fader:StopAll()
    if inst:IsAsleep() then
        inst.Light:SetIntensity(0)
    else
        inst.components.fader:Fade(INTENSITY, 0, .75 + math.random(), function(v)
            inst.Light:SetIntensity(v)
        end, function()
            inst.Light:Enable(false)
        end)
    end
end

local function UpdateLight(inst)
    if (not TheWorld.state.isday or inst:HasTag("under_leaf_canopy")) and
        not (inst.components.inventoryitem ~= nil and inst.components.inventoryitem.owner ~= nil) then
        if not inst.lighton then
            FadeIn(inst)
        else
            inst.Light:Enable(true)
            inst.Light:SetIntensity(INTENSITY)
        end
        inst.lighton = true
    else
        if inst.lighton then
            FadeOut(inst)
        else
            inst.Light:Enable(false)
            inst.Light:SetIntensity(0)
        end
        inst.lighton = false
    end
end

local function OnDeath(inst)
    inst.components.fader:Fade(INTENSITY, 0, .75 + math.random(), function(v)
        inst.Light:SetIntensity(v)
    end, function()
        inst.Light:Enable(false)
    end)
end

local function OnChangePhase(inst)
    inst:DoTaskInTime(2 + math.random(), UpdateLight)
end

local function OnChangeArea(inst, data)
    if data and data.tags and table.contains(data.tags, "Canopy") then
        if not inst:HasTag("under_leaf_canopy") then
            inst:AddTag("under_leaf_canopy")
            inst:PushEvent("onchangecanopyzone", true)
            OnChangePhase(inst)
        end
    elseif inst:HasTag("under_leaf_canopy") then
        inst:RemoveTag("under_leaf_canopy")
        inst:PushEvent("onchangecanopyzone", false)
        OnChangePhase(inst)
    end
end

local function commonfn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddLightWatcher()
    inst.entity:AddDynamicShadow()
    inst.entity:AddLight()
    inst.entity:AddNetwork()

    inst:AddTag("animal")
    inst:AddTag("insect")
    inst:AddTag("smallcreature")
    inst:AddTag("wildfireprotected")

    MakeTinyFlyingCharacterPhysics(inst, 1, .5)

    inst.Transform:SetSixFaced()
    inst.Transform:SetScale(0.6, 0.6, 0.6)

    inst.DynamicShadow:SetSize(.8, .5)

    inst.AnimState:SetBank("lantern_fly")
    inst.AnimState:SetBuild("lantern_fly")
    inst.AnimState:SetRayTestOnBB(true)

    inst.Light:SetFalloff(.7)
    inst.Light:SetIntensity(INTENSITY)
    inst.Light:SetRadius(2)
    inst.Light:SetColour(120 / 255, 120 / 255, 120 / 255)
    inst.Light:Enable(false)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("fader")
    inst:AddComponent("areaaware")
    inst:AddComponent("inspectable")

    inst:AddComponent("health")

    inst:AddComponent("combat")
    inst.components.combat.hiteffectsymbol = "body"

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetChanceLootTable('glowfly')

    inst:ListenForEvent("death", OnDeath)
    inst:ListenForEvent("changearea", OnChangeArea)
    inst:WatchWorldState("phase", OnChangePhase)

    inst:DoTaskInTime(0, UpdateLight)

    MakeHauntablePanicAndIgnite(inst)
    MakePoisonableCharacter(inst, "upper_body", Vector3(0, -1, 1))
    MakeSmallBurnableCharacter(inst, "upper_body", Vector3(0, -1, 1))

    return inst
end


local function OnWorked(inst, worker)
    if worker.components.inventory ~= nil then
        if inst.glowflyspawner ~= nil then
            inst.glowflyspawner:StopTracking(inst)
        end
        worker.components.inventory:GiveItem(inst, nil, inst:GetPosition())
    else
        inst:Remove()
    end
end

local function OnDropped(inst)
    inst.sg:GoToState("idle")
    inst.components.lootdropper:SetChanceLootTable("glowfly")
    UpdateLight(inst)

    if inst.glowflyspawner ~= nil then
        inst.glowflyspawner:StartTracking(inst)
    end

    if inst.components.workable ~= nil then
        inst.components.workable:SetWorkLeft(1)
    end
end

local function OnPutInInventory(inst)
    inst.components.lootdropper:SetChanceLootTable("glowflyinventory")
    if inst.glowflyspawner ~= nil then
        inst.glowflyspawner:StopTracking(inst)
    end
end

local function OnBorn(inst)
    inst.components.fader:Fade(0, INTENSITY, .75 + math.random(), function(v) inst.Light:SetIntensity(v) end)
end

local function SetCocoonTask(inst, time)
    time = time or math.random() * 3
    inst.cocoon_task, inst.cocoon_taskinfo = inst:ResumeTask(time, inst.BeginCocoonStage)
end

local function BeginCocoonStage(inst)
    inst.cocoon_task, inst.cocoon_taskinfo = nil, nil
    inst.wantstococoon = true
end

local function OnGlowflySave(inst, data)
    if inst.cocoon_task ~= nil then
        data.cocoon_task = inst:TimeRemainingInTask(inst.cocoon_taskinfo)
    end
end

local function OnGlowflyLoad(inst, data)
    if data ~= nil then
        if data.cocoon_task ~= nil then
            inst.SetCocoonTask(inst, data.cocoon_task)
        end
    end
end

local function glowflyfn()
    local inst = commonfn()

    inst:AddTag("glowfly")
    inst:AddTag("flying")
    inst:AddTag("cattoyairborne")
    inst:AddTag("ignorewalkableplatformdrowning")
    -- inst:AddTag("pollinator")  -- pollinator (from pollinator component) added to pristine state for optimization

    inst.AnimState:PlayAnimation("idle")

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("tradable")
    -- inst:AddComponent("pollinator")
    inst:AddComponent("knownlocations")

    inst.components.health:SetMaxHealth(1)

    inst:AddComponent("sleeper")
    inst.components.sleeper.onlysleepsfromitems = true

    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.NET)
    inst.components.workable:SetWorkLeft(1)
    inst.components.workable:SetOnFinishCallback(OnWorked)

    -- locomotor must be constructed before the stategraph
    inst:AddComponent("locomotor")
    inst.components.locomotor:EnableGroundSpeedMultiplier(false)
    inst.components.locomotor:SetTriggersCreep(false)
    inst.components.locomotor.walkspeed = TUNING.GLOWFLY_WALK_SPEED
    inst.components.locomotor.runspeed = TUNING.GLOWFLY_RUN_SPEED

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem:SetOnDroppedFn(OnDropped)
    inst.components.inventoryitem:SetOnPutInInventoryFn(OnPutInInventory)
    inst.components.inventoryitem:ChangeImageName("lantern_fly")
    inst.components.inventoryitem.canbepickedup = false
    inst.components.inventoryitem.canbepickedupalive = false
    inst.components.inventoryitem.nobounce = true
    inst.components.inventoryitem.pushlandedevents = false

    inst.glowflyspawner = TheWorld.components.glowflyspawner
    if inst.glowflyspawner ~= nil then
        inst.components.inventoryitem:SetOnPickupFn(inst.glowflyspawner.StopTrackingFn)
        inst:ListenForEvent("onremove", inst.glowflyspawner.StopTrackingFn)
        inst.glowflyspawner:StartTracking(inst)
    end

    inst:SetStateGraph("SGglowfly")
    inst:SetBrain(brain)

    inst.OnBorn = OnBorn
    inst.SetCocoonTask = SetCocoonTask
    inst.BeginCocoonStage = BeginCocoonStage

    MakeTinyFreezableCharacter(inst, "upper_body", Vector3(0, -1, 1))

    inst.OnSave = OnGlowflySave
    inst.OnLoad = OnGlowflyLoad

    return inst
end


local function OnNear(inst)
    if inst:HasTag("readytohatch") then
        inst:DoTaskInTime(5 + math.random() * 3, inst.PushEvent, "hatch")
    end
end

local function CocoonExpire(inst)
    inst.expiretask, inst.expiretaskinfo = nil, nil
    inst.sg:GoToState("cocoon_expire")
end

local function OnChangeSeason(inst, season)
    if season ~= SEASONS.HUMID then
        inst.expiretask, inst.expiretaskinfo = inst:ResumeTask(2 * TUNING.SEG_TIME + math.random() * 3, CocoonExpire)
    else
        inst:AddTag("readytohatch")
    end
end

local function OnCocoonSave(inst, data)
    if inst:HasTag("readytohatch") then
        data.readytohatch = true
    end

    if inst.expiretaskinfo ~= nil then
        data.expiretasktime = inst:TimeRemainingInTask(inst.expiretaskinfo)
    end
end

local function OnCocoonLoad(inst, data)
    if data.readytohatch then
        inst:AddTag("readytohatch")
    end

    if data.expiretasktime ~= nil then
        inst.expiretask, inst.expiretaskinfo = inst:ResumeTask(data.expiretasktime, CocoonExpire(inst))
    end
end

local function cocoonfn()
    local inst = commonfn()

    inst:AddTag("cocoon")

    inst.AnimState:PlayAnimation("cocoon_idle_loop", true)

    if not TheWorld.ismastersim then
        return inst
    end

    inst.components.health:SetMaxHealth(TUNING.GLOWFLY_COCOON_HEALTH)

    inst:AddComponent("playerprox")
    inst.components.playerprox:SetDist(30, 31)
    inst.components.playerprox:SetOnPlayerNear(OnNear)

    inst:SetStateGraph("SGglowfly_cocoon")

    inst:WatchWorldState("season", OnChangeSeason)

    inst.OnSave = OnCocoonSave
    inst.OnLoad = OnCocoonLoad

    return inst
end

return Prefab("glowfly", glowflyfn, assets),
    Prefab("glowfly_cocoon", cocoonfn, assets)
