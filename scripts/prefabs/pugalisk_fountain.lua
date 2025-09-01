local assets =
{
    Asset("ANIM", "anim/python_fountain.zip"),
}

local prefabs =
{
    "waterdrop",
    "lifeplant",
}

local function reset(inst)
    inst.dry = nil
    inst.components.storageloot:DestroyLoots()
    inst.components.storageloot:AddLoot("waterdrop")
    inst.components.activatable.inactive = true
    inst.AnimState:PlayAnimation("flow_pre")
    inst.AnimState:PushAnimation("flow_loop", true)
    inst.SoundEmitter:KillSound("burble")
    inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/pugalisk/fountain_LP", "burble")

    local ent = TheSim:FindFirstEntityWithTag("pugalisk_trap_door")
    if ent then
        ent:PushEvent("reactivate")
    end

    if inst.resettask then
        inst.resettask:Cancel()
        inst.resettask = nil
    end
    if inst.resettaskinfo then
        inst.resettaskinfo = nil
    end

    inst.MiniMapEntity:SetIcon("pugalisk_fountain.tex")
end

local function OnActivate(inst, doer)
    if not doer then
        return
    end

    inst.AnimState:PlayAnimation("flow_pst")
    inst.AnimState:PushAnimation("off", true)
    inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/pugalisk/resurrection")
    inst.SoundEmitter:KillSound("burble")
    inst.components.activatable.inactive = false
    inst.dry = true

    inst:OnDeactivate()

    local loots = inst.components.storageloot:TakeAllLoots()
    for i, v in ipairs(loots) do
        local loot = SpawnPrefab(v)
        doer.components.inventory:GiveItem(loot)
    end
    inst.components.storageloot:DestroyLoots()

    local ent = TheSim:FindFirstEntityWithTag("pugalisk_trap_door")
    if ent then
        ent:PushEvent("activate")
    end

    inst.MiniMapEntity:SetIcon("pugalisk_fountain_empty.tex")
end

local function OnDeactivate(inst)
    if not inst.resettask and TUNING.PUGALISK_ENABLED then
        inst.resettask, inst.resettaskinfo = inst:ResumeTask(TUNING.PUGALISK_RESPAWN, reset)
    end

    inst.MiniMapEntity:SetIcon("pugalisk_fountain.tex")
end

local function OnSave(inst,data)
    if inst.dry then
        data.dry = true
    end

    if inst.resettaskinfo then
        data.resettask = inst:TimeRemainingInTask(inst.resettaskinfo)
    end
end

local function OnLoad(inst, data)
    if not data then
        return
    end

    if data.resettask then
        if inst.resettask then inst.resettask:Cancel() inst.resettask = nil end
        inst.resettaskinfo = nil
        inst.resettask, inst.resettaskinfo = inst:ResumeTask(data.resettask, reset)
    end

    if data.dry then
        inst.AnimState:PlayAnimation("off", true)
        inst.SoundEmitter:KillSound("burble")
        inst.dry = true
        inst.components.storageloot:DestroyLoots()
        inst.components.activatable.inactive = false
    end
end

function OnLongUpdate(inst, dt)
    if inst.resettask then
        local new_time = math.max(inst:TimeRemainingInTask(inst.resettaskinfo) - dt, 0)

        inst.resettask:Cancel()
        inst.resettask = nil
        inst.resettaskinfo = nil

        inst.resettask, inst.resettaskinfo = inst:ResumeTask(new_time, reset)
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    inst.AnimState:SetBuild("python_fountain")
    inst.AnimState:SetBank("fountain")
    inst.AnimState:PlayAnimation("flow_loop", true)

    inst.MiniMapEntity:SetIcon("pugalisk_fountain.tex")

    MakeObstaclePhysics(inst, 2)

    inst:AddTag("pugalisk_fountain")
    inst:AddTag("pugalisk_avoids")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("activatable")
    inst.components.activatable.OnActivate = OnActivate
    inst.components.activatable.inactive = true

    inst:AddComponent("inspectable")
    inst.components.inspectable:RecordViews()

    inst:AddComponent("lootdropper")
    inst.components.lootdropper.max_speed = 3

    inst.dry = nil
    inst:AddComponent("storageloot")
    inst.components.storageloot:AddLoot("waterdrop")

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad
    inst.OnLongUpdate = OnLongUpdate

    inst.OnDeactivate = OnDeactivate

    inst:DoTaskInTime(0, function()
        if inst.dry then
            inst:OnDeactivate()
        else
            inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/pugalisk/fountain_LP", "burble")
        end
    end)

    MakeHauntable(inst)

    return inst
end

return Prefab("pugalisk_fountain", fn, assets, prefabs)
