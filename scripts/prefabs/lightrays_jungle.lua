local assets =
{
    Asset("ANIM", "anim/lightrays.zip"),
}

local function TurnOff(inst, light)
    if light then
        light:Enable(false)
    end
    inst:Hide()
end

local phase_functions =
{
    day = function(inst)
        inst.Light:Enable(true)
        inst:Show()
        inst.components.lighttweener:StartTween(nil, 4, 0.8, 0.7, {180 / 255, 195 / 255, 150 / 255}, 2)
    end,

    dusk = function(inst)
        inst.Light:Enable(true)
        inst.components.lighttweener:StartTween(nil, 4, 0.8, 0.7, {100 / 255, 100 / 255, 100 / 255}, 2)
    end,

    night = function(inst)
        if TheWorld.state.moonphase == "full" then
            inst.components.lighttweener:StartTween(nil, 5, 0.6, 0.6, {91 / 255, 164 / 255, 255 / 255}, 4)
        else
            inst.components.lighttweener:StartTween(nil, 0, 0, 1, {0, 0, 0}, 6, TurnOff)
        end
    end,
}

local function OnPhaseChange(inst, phase)
    phase_functions[phase](inst)
end

local function ExtraDistFn(inst, dt)
    local time = 1
    local delta = dt/time

    if inst.extradistancefade_current < 1 then
        inst.extradistancefade_current = math.min(1, inst.extradistancefade_current + delta)
    end

    return inst.extradistancefade_current
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddLight()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("lightrays")
    inst.AnimState:SetBuild("lightrays")
    inst.AnimState:PlayAnimation("idle_loop", true)
    inst.AnimState:SetMultColour(255 / 255, 177 / 255, 32 / 255, 0)
    local rays = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11}
    for i = 1, #rays do
        inst.AnimState:Hide("lightray" .. i)
    end
    for i = 1, math.random(4, 6) do
        local selection = math.random(1, #rays)
        inst.AnimState:Show("lightray" .. rays[selection])
        table.remove(rays, selection)
    end

    inst.Transform:SetEightFaced()
    inst.Transform:SetRotation(45)

    inst:AddTag("NOCLICK")
    inst:AddTag("NOBLOCK")
    inst:AddTag("lightrays")
    inst:AddTag("exposure")
    inst:AddTag("daylight")

    if not TheNet:IsDedicated() then
        inst:AddComponent("distancefade")
        inst.components.distancefade:Setup(15, 15)
        inst.components.distancefade:SetExtraFn(ExtraDistFn)

        inst.extradistancefade_current = 1
        inst:AddTag("no_fade_by_zone")
    end

    inst:AddComponent("lighttweener")
    inst.components.lighttweener:StartTween(inst.Light, 4, 0.8, 0.7, {180 / 255, 195 / 255, 150 / 255}, 0)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:WatchWorldState("phase", OnPhaseChange)
    OnPhaseChange(inst, TheWorld.state.phase)

    return inst
end

return Prefab("lightrays_jungle", fn, assets)
