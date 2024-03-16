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
    inst.components.activatable.inactive = true
    inst.AnimState:PlayAnimation("flow_pre")
    inst.AnimState:PushAnimation("flow_loop", true)
    inst.SoundEmitter:KillSound("burble")
    inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/pugalisk/fountain_LP", "burble")
    if inst.resettask then
        inst.resettask:Cancel()
        inst.resettask = nil
    end
    if inst.resettaskinfo then
        inst.resettaskinfo = nil
    end
end

local function OnActivate(inst, doer)
    inst.AnimState:PlayAnimation("flow_pst")
    inst.AnimState:PushAnimation("off", true)
    inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/pugalisk/resurrection")
    inst.SoundEmitter:KillSound("burble")
    inst.components.activatable.inactive = false
    inst.dry = true

    local drop = SpawnPrefab("waterdrop")
    drop.fountain = inst
    doer.components.inventory:GiveItem(drop) --, nil, Vector3(TheSim:GetScreenPos(inst.Transform:GetWorldPosition())))

    local ent = TheSim:FindFirstEntityWithTag("pugalisk_trap_door")
    if ent then
        ent:PushEvent("activate")
    end
end

local function OnDeactivate(inst)
    if not inst.resettask then
        inst.resettask, inst.resettaskinfo = inst:ResumeTask(TUNING.TOTAL_DAY_TIME, reset)
    end
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

    inst.MiniMapEntity:SetIcon("pig_ruins_well.tex")

    inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/pugalisk/fountain_LP", "burble")

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

    inst:ListenForEvent("deactivate", OnDeactivate)

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad
    inst.OnLongUpdate = OnLongUpdate

    inst:DoTaskInTime(0, function()
        local drop = nil
        local plant = nil
        for k,v in pairs(Ents) do
            if v:HasTag("lifeplant") then
                plant = true
            end
            if v:HasTag("waterdrop") then
                drop = true
            end
            if plant and drop then
                break
            end
        end
        if not plant and not drop and inst.dry then
            OnDeactivate(inst)
        end
    end)

    MakeHauntable(inst)

    return inst
end

return Prefab("pugalisk_fountain", fn, assets, prefabs)
