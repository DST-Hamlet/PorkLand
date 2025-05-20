local assets =
{
}

local prefabs =
{
}

local MULT = 0.8

local lighttypes = {
    natural = {
        day  = {rad = 3, intensity = 0.75, falloff = 0.5, color = {MULT, MULT, MULT}},
        dusk = {rad = 2, intensity = 0.75, falloff = 0.5, color = {MULT / 1.8, MULT/ 1.8, MULT / 1.8}},
        full = {rad = 2, intensity = 0.75, falloff = 0.5, color = {MULT * 0.8 / 1.8, MULT * 0.8 / 1.8, MULT / 1.8}},
        aporkalypse = {rad = 2, intensity = 0.75, falloff = 0.5, color = {150/255, 40/255, 40/255}}
    },
    electric_1 = {
        day = {rad = 3, intensity = 0.9, falloff = 0.5, color = {197 / 255, 197 / 255, 50 / 255}},
    },
}

local function TurnOff(inst, light)
    if light then
        light:Enable(false)
    end
end

local phase_functions =
{
    day = function(inst)
        local lights = lighttypes[inst.lighttype]
        if not inst:IsInLimbo() then
            inst.Light:Enable(true)
        end
        inst.components.lighttweener:StartTween(nil, lights.day.rad, lights.day.intensity, lights.day.falloff,
            {lights.day.color[1],lights.day.color[2],lights.day.color[3]}, 2)
    end,

    dusk = function(inst)
        local lights = lighttypes[inst.lighttype]
        if not inst:IsInLimbo() then
            inst.Light:Enable(true)
        end
        inst.components.lighttweener:StartTween(nil, lights.dusk.rad, lights.dusk.intensity, lights.dusk.falloff,
            {lights.dusk.color[1],lights.dusk.color[2],lights.dusk.color[3]}, 2)
    end,

    night = function(inst)
        local lights = lighttypes[inst.lighttype]
        if TheWorld.state.isaporkalypse then
            inst.components.lighttweener:StartTween(nil, lights.aporkalypse.rad, lights.aporkalypse.intensity, lights.aporkalypse.falloff,
            {lights.aporkalypse.color[1],lights.aporkalypse.color[2],lights.aporkalypse.color[3]}, 4)
        elseif TheWorld.state.moonphase == "full" then
            inst.components.lighttweener:StartTween(nil, lights.full.rad, lights.full.intensity, lights.full.falloff,
                {lights.full.color[1],lights.full.color[2],lights.full.color[3]}, 4)
        else
            inst.components.lighttweener:StartTween(nil, 0, 0, 1, {0, 0, 0}, 6, TurnOff)
        end
    end,
}

local function OnPhaseChange(inst, phase)
    if not inst.Light then
        return
    end
    if phase_functions[phase] then
        phase_functions[phase](inst)
    end
end

local function SetListenEvents(inst)
    inst:AddComponent("lighttweener")
    local lights = lighttypes[inst.lighttype]
    inst.components.lighttweener:StartTween(inst.Light, lights.day.rad, lights.day.intensity, lights.day.falloff,
        {lights.day.color[1],lights.day.color[2],lights.day.color[3]}, 0)
    inst.Light:Enable(true)

    inst:WatchWorldState("phase", OnPhaseChange)
    OnPhaseChange(inst, TheWorld.state.phase)
    inst.components.lighttweener:EndTween()

    inst.daytimeevents = true
end

local function SetLightType(inst, lighttype)
    if lighttypes[lighttype] then
        inst.lighttype = lighttype
        inst.Light:SetIntensity(lighttypes[inst.lighttype].day.intensity)
        inst.Light:SetColour(lighttypes[inst.lighttype].day.color[1], lighttypes[inst.lighttype].day.color[2], lighttypes[inst.lighttype].day.color[3])
        inst.Light:SetFalloff(lighttypes[inst.lighttype].day.falloff)
        inst.Light:SetRadius(lighttypes[inst.lighttype].day.rad)
    end
end

local function OnSave(inst, data)
    if inst.daytimeevents then
        data.daytimeevents = inst.daytimeevents
    end
    if inst.followobject then
        data.followobject = inst.followobject
    end
    if inst.lighttype then
        data.lighttype = inst.lighttype
    end
end

local function OnLoad(inst, data)
    if not data then
        return
    end
    if data.lighttype then
        inst.lighttype = data.lighttype
        inst.Light:SetIntensity(lighttypes[inst.lighttype].day.intensity)
        inst.Light:SetColour(lighttypes[inst.lighttype].day.color[1], lighttypes[inst.lighttype].day.color[2], lighttypes[inst.lighttype].day.color[3])
        inst.Light:SetFalloff(lighttypes[inst.lighttype].day.falloff)
        inst.Light:SetRadius(lighttypes[inst.lighttype].day.rad)
    end
    if data.daytimeevents then
        SetListenEvents(inst)
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddLight()
    inst.entity:AddFollower()
    inst.entity:AddNetwork()

    inst.lighttype = "natural"

    inst.Light:SetIntensity(lighttypes[inst.lighttype].day.intensity)
    inst.Light:SetColour(lighttypes[inst.lighttype].day.color[1], lighttypes[inst.lighttype].day.color[2],lighttypes[inst.lighttype].day.color[3])
    inst.Light:SetFalloff(lighttypes[inst.lighttype].day.falloff)
    inst.Light:SetRadius(lighttypes[inst.lighttype].day.rad)
    inst.Light:Enable(true)

    inst.setListenEvents = SetListenEvents
    inst.setLightType = SetLightType

    inst:AddTag("swinglight")
    inst:AddTag("NOBLOCK")
    inst:AddTag("daylight")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad

    return inst
end

return Prefab("swinglightobject", fn, assets, prefabs)
