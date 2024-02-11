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

    if worker and worker:HasTag("dungbeetle") then
        SpawnDungball(inst)
    else
        for i = 1, inst.components.pickable.cycles_left do
            inst.components.lootdropper:DropLoot(inst:GetPosition())
        end
    end

    inst.components.pickable:MakeBarren()
end

local function OnWorkCallback(inst)
    inst.AnimState:PlayAnimation("hit", false)
end

local function OnPicked(inst, picker)
    local pt = inst:GetPosition()
    local sanity = picker.components.sanity
    inst.SoundEmitter:PlaySound("dontstarve/common/food_rot")
    inst.components.lootdropper:DropLoot(pt)

    if picker and sanity then
        if picker.components.talker and picker:HasTag("player") then
            picker.components.talker:Say(GetString(picker, "ANNOUNCE_PICKPOOP"))
        end
        local delta = picker:HasTag("plantkin") and 10 or -10
        sanity:DoDelta(delta)
    end

    if inst.components.pickable.cycles_left <= 0 then
        inst.components.pickable:MakeBarren()
    end
end

local function MakeFull(inst)
    if inst.components.pickable.cycles_left <= 0 then
        inst.components.workable:SetWorkLeft(1)
    end
end

local function MakeBarren(inst)
    inst:RemoveTag("dungpile")
    inst.persists = false
    inst.components.workable.workleft = 0
    inst.AnimState:PlayAnimation("idle_to_dead")
    inst.SoundEmitter:PlaySound("dontstarve/common/food_rot")
end

local function GetRegenTime(inst)
    return 0
end

local function GetStatus(inst, viewer)
    if not inst:HasTag("dungpile") then
        return "PICKED"
    end
end

local function Init(inst)
    inst.flies = inst:SpawnChild("flies")
    inst.flies.Transform:SetScale(1.2, 1.2, 1.2)
end

local function OnIdleToDead(inst)
    local time_to_erode = 1
    local tick_time = TheSim:GetTickTime()

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
        inst.AnimState:PlayAnimation("idle")
    end
end

local function OnBurn(inst)
    if inst.flies then
        inst.flies:Remove()
        inst.flies = nil
    end
end

local function Fall(inst)
    inst.AnimState:PlayAnimation("fall")
    inst:DoTaskInTime(10 / 30,function() inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/roc/dung_pile") end)
    inst:DoTaskInTime(15 / 30,function()
        ShakeAllCameras(CAMERASHAKE.VERTICAL, 0.3, 0.02, 0.5, inst, 40)
    end)
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
    inst:AddTag("pickable_digin_str")

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
    for k, v in pairs(loots) do
        inst.components.lootdropper:AddRandomLoot(v[1], v[2])
    end
    inst.components.lootdropper.numrandomloot = 1
    inst.components.lootdropper.max_speed = 3

    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.DIG)
    inst.components.workable:SetWorkLeft(1)
    inst.components.workable:SetOnFinishCallback(OnFinishCallback)
    inst.components.workable:SetOnWorkCallback(OnWorkCallback)

    inst:AddComponent("pickable")
    inst.components.pickable.picksound = "dontstarve/wilson/harvest_berries"
    inst.components.pickable.max_cycles = 3
    inst.components.pickable.cycles_left = inst.components.pickable.max_cycles
    inst.components.pickable.transplanted = true
    inst.components.pickable:SetUp(nil, 0)
    inst.components.pickable.onpickedfn = OnPicked
    inst.components.pickable.getregentimefn = GetRegenTime
    inst.components.pickable.makefullfn = MakeFull
    inst.components.pickable.makebarrenfn = MakeBarren

    inst:AddComponent("childspawner")
    inst.components.childspawner.childname = "dungbeetle"
    inst.components.childspawner:SetRegenPeriod(TUNING.DUNGBEETLE_REGEN_TIME)
    inst.components.childspawner:SetSpawnPeriod(TUNING.DUNGBEETLE_RELEASE_TIME)
    inst.components.childspawner:SetMaxChildren(TUNING.DUNGBEETLE_MAXCHILDREN)
    inst.components.childspawner:StartSpawning()
    WorldSettings_ChildSpawner_SpawnPeriod(inst, TUNING.DUNGBEETLE_RELEASE_TIME, TUNING.DUNGBEETLE_ENABLED)
    WorldSettings_ChildSpawner_RegenPeriod(inst, TUNING.DUNGBEETLE_REGEN_TIME, TUNING.DUNGBEETLE_ENABLED)
    if not TUNING.DUNGBEETLE_ENABLED then
        inst.components.childspawner.childreninside = 0
    end

    inst:ListenForEvent("animover", OnAnimOver)

    MakeMediumBurnable(inst)
    inst.components.burnable:SetOnIgniteFn(OnBurn)
    MakeSmallPropagator(inst)
    MakeHauntableIgnite(inst)
    MakeSnowCovered(inst)

    inst.Fall = Fall

    inst:DoTaskInTime(0, Init)

    return inst
end

return Prefab("dungpile", fn, assets, prefabs)
