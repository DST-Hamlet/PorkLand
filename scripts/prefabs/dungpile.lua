local assets = {
    Asset("ANIM", "anim/dung_pile.zip"),
}

local prefabs = {
    "dungbeetle",
    "cutgrass",
    "flint",
    "twigs",
    "boneshard",
    "rocks",
    "poop",
    "collapse_small",
}

local loots = {
    {"poop",        1.00},
    {"rocks",       1.00},
    {"cutgrass",    0.05},
    {"boneshard",   0.2},
    {"flint",       0.05},
    {"twigs",       0.05},
}

local function SpawnDungball(inst)
    local dungball = SpawnPrefab("dungball")
    dungball.Transform:SetPosition(inst.Transform:GetWorldPosition())
    dungball.AnimState:PlayAnimation("idle")
end

local function OnFinishCallback(inst, worker)
    inst.SoundEmitter:PlaySound("dontstarve/common/food_rot")
    local pt = Vector3(inst.Transform:GetWorldPosition())

    if worker and worker:HasTag("dungbeetle") then
        SpawnDungball(inst)
    else
        for i = 1, inst.components.pickable.cycles_left do
            inst.components.lootdropper:DropLoot(pt)
        end
    end

    inst.components.pickable:MakeBarren()
end

local function OnWorkCallback(inst)
    inst.AnimState:PlayAnimation("hit", false)
end

local function OnPickedFn(inst, picker)
    local pt = inst:GetPosition()
    local sanity = picker.components.sanity
    inst.SoundEmitter:PlaySound("dontstarve/common/food_rot")
    inst.components.lootdropper:DropLoot(pt)

    if picker and sanity then
        if picker.components.talker and picker:HasTag("player") then
            picker.components.talker:Say(GetString(picker, "ANNOUNCE_PICKPOOP"))
        end
        if picker:HasTag("plantkin") then
            sanity:DoDelta(10)
        else
            sanity:DoDelta(-10)
        end
    end

    if inst.components.pickable.cycles_left <= 0 then
        inst.components.pickable:MakeBarren()
    end
end

local function MakeFullFn(inst)
    if inst.components.pickable.cycles_left <= 0 then
        inst:AddTag("dungpile")
        inst.components.workable:SetWorkLeft(1)
        inst.AnimState:PlayAnimation("dead_to_idle")
        inst.AnimState:PushAnimation("idle")
    end
end

local function OnBarren(inst)
    inst:AddTag("dungpile")
    inst.components.workable:SetWorkLeft(1)
    inst.components.pickable.cycles_left = inst.components.pickable.max_cycles
    inst.components.pickable.canbepicked = true
    inst.AnimState:PlayAnimation("dead_to_idle")
    inst.AnimState:PushAnimation("idle")

    inst.resttask = nil
end

local function MakeBarrenFn(inst)
    inst:RemoveTag("dungpile")
    inst.components.workable.workleft = 0
    inst.AnimState:PlayAnimation("idle_to_dead")
    inst.SoundEmitter:PlaySound("dontstarve/common/food_rot")

    inst.resttask, inst.resttaskinfo = inst:ResumeTask(TUNING.TOTAL_DAY_TIME * 3 + (math.random() * TUNING.TOTAL_DAY_TIME), function()
        OnBarren(inst)
    end)
end

local function GetRegenTimeFn(inst)
    return 0
end

local function OnBurn(inst)
    if inst.flies then
        inst.flies:Remove()
        inst.flies = nil
    end
end

local function OnSave(inst, data)
    if inst:HasTag("dungpile") then
        data.hasdung = true
    end
    if inst.taskinfo then
        data.timeleft = inst:TimeRemainingInTask(inst.taskinfo)
    end
    if inst.destroyed then
        data.destroyed = true
        inst:Remove()
    end
end

local function OnLoad(inst, data)
    if data ~= nil then
        if data.hasdung then
            inst:AddTag("hasdung")
            inst.AnimState:PlayAnimation("idle")
        else
            inst:RemoveTag("hasdung")
            inst.AnimState:PlayAnimation("dead")
        end
        if data.timeleft then
            if inst.resttask then
                inst.resttask:Cancel()
                inst.resttask = nil
            end
            inst.resttaskinfo = nil
            inst.resttask, inst.resttaskinfo = inst:ResumeTask(data.timeleft, function()
                OnBarren(inst)
            end)
        end
        if data.destroyed then
            inst:Remove()
        end
    end
end

local function GetStatus(inst, viewer)
    if not inst:HasTag("dungpile") then
        return "PICKED"
    end
end

local function DoPostinit(inst)
    inst.flies = inst:SpawnChild("flies")
    inst.flies.Transform:SetScale(1.2, 1.2, 1.2)

    for k, v in pairs(loots) do
        inst.components.lootdropper:AddRandomLoot(v[1], v[2])
    end

    inst.components.burnable:SetOnIgniteFn(OnBurn)
end

local function OnPlayFallAnim(inst)
    inst.AnimState:PlayAnimation("fall")
    inst:DoTaskInTime(10/30, function()
        inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/roc/dung_pile")
    end)
    inst:DoTaskInTime(15/30, function()
        ShakeAllCameras(CAMERASHAKE.VERTICAL, 0.3, 0.02, 0.5)
    end)
end

local function OnIdleToDead(inst)
    local time_to_erode = 1
    local tick_time = TheSim:GetTickTime()
    inst.destroyed = true

    inst:StartThread(function()
        local ticks = 0
        while ticks * tick_time < time_to_erode do
            local erode_amount = ticks * tick_time / time_to_erode
            inst.AnimState:SetErosionParams(erode_amount, 0.1, 1.0)
            ticks = ticks + 1
            Yield()
        end
        inst:Remove()
    end)
end

local function OnAnimOver(inst, data)
    if inst.AnimState:IsCurrentAnimation("idle_to_dead") then
        OnIdleToDead(inst)
    end
    if inst.AnimState:IsCurrentAnimation("fall") then
        OnPlayFallAnim(inst)
    end
end

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()
    inst.entity:AddMiniMapEntity()

    inst.MiniMapEntity:SetIcon("dung_pile.tex")

    inst:AddTag("dungpile")
    inst:AddTag("pick_digin")

    inst.AnimState:SetBank("dung_pile")
    inst.AnimState:SetBuild("dung_pile")
    inst.AnimState:PlayAnimation("idle")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")
    inst.components.inspectable.getstatus = GetStatus

    inst:AddComponent("lootdropper")
    inst.components.lootdropper.numrandomloot = 1
    inst.components.lootdropper.speed = 2
    inst.components.lootdropper.alwaysinfront = true

    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.DIG)
    inst.components.workable:SetWorkLeft(1)
    inst.components.workable:SetOnFinishCallback(OnFinishCallback)
    inst.components.workable:SetOnWorkCallback(OnWorkCallback)

    inst:AddComponent("childspawner")
    inst.components.childspawner.childname = "dungbeetle"
    inst.components.childspawner:SetRegenPeriod(TUNING.DUNGPILE_REGEN_TIME)
    inst.components.childspawner:SetSpawnPeriod(TUNING.DUNGPILE_RELEASE_TIME)
    inst.components.childspawner:SetMaxChildren(TUNING.DUNGPILE_MAXCHILDREN)
    inst.components.childspawner:StartSpawning()
    WorldSettings_ChildSpawner_SpawnPeriod(inst, TUNING.DUNGPILE_RELEASE_TIME, TUNING.DUNGPILE_ENABLED)
    WorldSettings_ChildSpawner_RegenPeriod(inst, TUNING.DUNGPILE_REGEN_TIME, TUNING.DUNGPILE_ENABLED)
    if not TUNING.DUNGPILE_ENABLED then
        inst.components.childspawner.childreninside = 0
    end

    inst:AddComponent("pickable")
    inst.components.pickable.picksound = "dontstarve/wilson/harvest_berries"
    inst.components.pickable.getregentimefn = GetRegenTimeFn
    inst.components.pickable.onpickedfn = OnPickedFn
    inst.components.pickable.makebarrenfn = MakeBarrenFn
    inst.components.pickable.makefullfn = MakeFullFn
    inst.components.pickable.max_cycles = 3
    inst.components.pickable.cycles_left = inst.components.pickable.max_cycles
    inst.components.pickable:SetUp(nil, 0)
    inst.components.pickable.transplanted = true

    inst:ListenForEvent("animover", OnAnimOver)

    MakeMediumBurnable(inst)
    MakeSmallPropagator(inst)
    MakeHauntableIgnite(inst)
    MakeSnowCovered(inst)

    inst.DoPostinit = DoPostinit
    inst.SpawnDungball = SpawnDungball
    inst.OnSave = OnSave
    inst.OnLoad = OnLoad

    inst:DoTaskInTime(0, DoPostinit)

    return inst
end

return Prefab("dungpile", fn, assets, prefabs)
