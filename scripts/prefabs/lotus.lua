local assets =
{
    Asset("ANIM", "anim/lotus.zip"),
}

local prefabs =
{
    "bill"
}

local BILL_SPAWN_DIST = 12
local function OnPicked(inst)
    inst.SoundEmitter:PlaySound("dontstarve/wilson/pickup_reeds")

    if not inst.closed then
        inst.AnimState:PlayAnimation("picking")
        inst.AnimState:PushAnimation("picked", true)
    else
        inst.AnimState:PlayAnimation("picked", true)
    end

    local bill = FindEntity(inst, 50, nil, {"platapine"})
    if bill then
        return
    end

    if not (math.random() < TUNING.BILL_SPAWN_CHANCE) then
        return
    end

    local lotus_position = inst:GetPosition()
    local offset = FindSwimmableOffset(lotus_position, math.random() * PI * 2, BILL_SPAWN_DIST, nil, nil, false, nil, false)

    if offset then
        local spawn_point = lotus_position + offset
        bill = SpawnPrefab("bill")
        bill.components.combat.target = nil
        bill.Transform:SetPosition(spawn_point.x, spawn_point.y, spawn_point.z)
        bill.sg:GoToState("surface")
    end
end

local function OnRegen(inst)
    inst.AnimState:PlayAnimation("grow")
    inst.AnimState:PushAnimation("idle_plant", true)
end

local function MakeEmpty(inst)
    inst.AnimState:PlayAnimation("picked", true)
end

local function OnDay(inst)
    if inst.components.pickable and inst.components.pickable:CanBePicked() and inst.closed then
        inst.closed = false
        inst.AnimState:PlayAnimation("open")
        inst.AnimState:PushAnimation("idle_plant", true)
    end
end

local function Close(inst)
    if inst.components.pickable and inst.components.pickable:CanBePicked() then
        inst.AnimState:PlayAnimation("close")
        inst.AnimState:PushAnimation("idle_plant_close", true)
        inst.closed = true
    end
end

local function OnPhaseChange(inst, phase)
    if phase == "day" then
        inst:DoTaskInTime(math.random() * 10, OnDay)
    elseif not inst.closed then
        inst:DoTaskInTime(math.random() * 10, Close)
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    MakeObstaclePhysics(inst, 0.25)

    inst.AnimState:SetBank("lotus")
    inst.AnimState:SetBuild("lotus")
    inst.AnimState:PlayAnimation("idle_plant", true)
    inst.AnimState:SetTime(math.random() * 2)
    local color = 0.75 + math.random() * 0.25
    inst.AnimState:SetMultColour(color, color, color, 1)

    inst.MiniMapEntity:SetIcon("lotus.tex")

    inst:AddTag("lotus")
    inst:AddTag("plant")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.closed = false

    inst:AddComponent("inspectable")

    inst:AddComponent("pickable")
    inst.components.pickable.picksound = "dontstarve/wilson/pickup_plants"
    inst.components.pickable:SetUp("lotus_flower", TUNING.LOTUS_REGROW_TIME)
    inst.components.pickable:SetOnPickedFn(OnPicked)
    inst.components.pickable:SetOnRegenFn(OnRegen)
    inst.components.pickable:SetMakeEmptyFn(MakeEmpty)

    inst:AddComponent("fuel")
    inst.components.fuel.fuelvalue = TUNING.SMALL_FUEL

    MakeSmallBurnable(inst, TUNING.MED_BURNTIME)
    MakeSmallPropagator(inst)
    MakeHauntable(inst)

    inst:WatchWorldState("phase", OnPhaseChange)
    OnPhaseChange(inst, TheWorld.state.phase)

    return inst
end

return Prefab("lotus", fn, assets, prefabs)
