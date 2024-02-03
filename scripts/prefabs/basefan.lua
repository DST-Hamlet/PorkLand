local assets = {
    Asset("ANIM", "anim/basefan.zip"),
    Asset("ANIM", "anim/firefighter_placement.zip"),
}

local PLACER_SCALE = 1.55

local function TurnOff(inst, instant)
    inst.on = false
    inst.components.fueled:StopConsuming()
    inst:RemoveTag("prevents_hayfever")
    inst:RemoveTag("blows_air")

    inst.sg:GoToState(instant and "idle_off" or "turn_off")
end

local function TurnOn(inst, instant)
    inst.on = true
    inst.components.fueled:StartConsuming()
    inst:AddTag("prevents_hayfever")
    inst:AddTag("blows_air")

    inst.sg:GoToState(instant and "idle_on" or "turn_on")
end

local function OnFuelEmpty(inst)
    inst.components.machine:TurnOff()
end

local function OnFuelSectionChange(newsection, oldsection, inst)
    local fuelanim = inst.components.fueled:GetCurrentSection()
end

local function CanInteract(inst)
    return not inst.components.fueled:IsEmpty() and not inst.components.floodable.flooded
end

local function onhammered(inst, worker)
    inst.SoundEmitter:KillSound("idleloop")
    inst.components.lootdropper:DropLoot()
    local fx  = SpawnPrefab("collapse_small")
    fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
    fx:SetMaterial("metal")
    inst:Remove()
end

local function onhit(inst, worker)
    if not inst.sg:HasStateTag("busy") then
        inst.sg:GoToState("hit")
    end
end

local function getstatus(inst, viewer)
    return inst.components.fueled ~= nil
    and inst.components.fueled.currentfuel / inst.components.fueled.maxfuel <= .25
    and "LOWFUEL"
    or "ON"
end

local function OnSave(inst, data)
    data.on = inst.on
end

local function OnLoad(inst, data)
    inst.on = data.on or false
end

local function onbuilt(inst)
    inst.AnimState:PlayAnimation("place")
    inst.AnimState:PushAnimation("off")
end

local function OnFloodedStart(inst)
    if inst.on then
        TurnOff(inst, true)
    end
end

local function ontakefuelfn(inst)
    inst.SoundEmitter:PlaySound("dontstarve_DLC001/common/machine_fuel")
    if inst.on == false then
        inst.components.machine:TurnOn()
    end
end

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    inst.MiniMapEntity:SetPriority(5)
    inst.MiniMapEntity:SetIcon("basefan.tex")

    MakeObstaclePhysics(inst, 0.3)

    inst:AddTag("structure")

    inst.AnimState:SetBank("basefan")
    inst.AnimState:SetBuild("basefan")
    inst.AnimState:PlayAnimation("off")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("lootdropper")

    inst:AddComponent("inspectable")
    inst.components.inspectable.getstatus = getstatus

    inst:AddComponent("machine")
    inst.components.machine.turnonfn = TurnOn
    inst.components.machine.turnofffn = TurnOff
    inst.components.machine.caninteractfn = CanInteract
    inst.components.machine.cooldowntime = 0.5

    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(4)
    inst.components.workable:SetOnFinishCallback(onhammered)
    inst.components.workable:SetOnWorkCallback(onhit)

    inst:AddComponent("floodable")
    inst.components.floodable.onStartFlooded = OnFloodedStart
    inst.components.floodable:SetFX("shock_machines_fx")

    inst:AddComponent("fueled")
    inst.components.fueled:SetDepletedFn(OnFuelEmpty)
    inst.components.fueled.accepting = true
    inst.components.fueled:SetSections(10)
    inst.components.fueled:SetTakeFuelFn(ontakefuelfn)
    inst.components.fueled:SetSectionCallback(OnFuelSectionChange)
    inst.components.fueled:InitializeFuelLevel(TUNING.FIRESUPPRESSOR_MAX_FUEL_TIME)
    inst.components.fueled.bonusmult = 5
    inst.components.fueled.secondaryfueltype = FUELTYPE.CHEMICAL

    inst:SetStateGraph("SGbasefan")

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad

    inst:ListenForEvent("onbuilt", onbuilt)

    MakeHauntableWork(inst)

    return inst
end

local function placer_postinit_fn(inst)
    -- Show the flingo placer on top of the flingo range ground placer

    local placer2 = CreateEntity()

    --[[Non-networked entity]]
    placer2.entity:SetCanSleep(false)
    placer2.persists = false

    placer2.entity:AddTransform()
    placer2.entity:AddAnimState()

    placer2:AddTag("CLASSIFIED")
    placer2:AddTag("NOCLICK")
    placer2:AddTag("placer")

    local s = 1 / PLACER_SCALE
    placer2.Transform:SetScale(s, s, s)

    placer2.AnimState:SetBank("basefan")
    placer2.AnimState:SetBuild("basefan")
    placer2.AnimState:PlayAnimation("off")
    placer2.AnimState:SetLightOverride(1)

    placer2.entity:SetParent(inst.entity)

    inst.components.placer:LinkEntity(placer2)
end

return Prefab("basefan", fn, assets),
    MakePlacer("basefan_placer", "firefighter_placement", "firefighter_placement", "idle", true, nil, nil, PLACER_SCALE, nil, nil, placer_postinit_fn)
