local assets =
{
    Asset("ANIM", "anim/ruins_light_beam.zip"),
}

local prefabs =
{

}

local DART_TRAP_MUST_TAGS = {"dartthrower"}
local SPEAR_TRAP_MUST_TAGS = {"spear_trap"}

local function TriggerTraps(inst)
    local range = inst:HasTag("localtrap") and 4 or 50

    local x, y, z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, range, DART_TRAP_MUST_TAGS)
    for _, ent in pairs(ents) do
        if ent.components.autodartthrower then
            ent.components.autodartthrower:TurnOn()
        elseif ent.shoot then
            ent:shoot()
        end
    end

    ents = TheSim:FindEntities(x, y, z, range, SPEAR_TRAP_MUST_TAGS)
    for _, ent in pairs(ents) do
        ent:PushEvent("triggertrap")
    end
end

local function CreatureProxTest(ent)
    return ent:HasTag("locomotor") and not ent:HasTag("notraptrigger") -- TODO add notraptrigger tag to mobs
end

local function TurnOn(inst, light)
    inst.components.creatureprox:SetEnabled(true)
end

local function TurnOff(inst, light)
    if light then
        light:Enable(false)
    end
    inst.components.creatureprox:SetEnabled(false)
    inst:Hide()
end

local phase_functions =
{
    day = function(inst)
        inst.Light:Enable(true)
        inst:Show()

        if inst:HasTag("ruins_light") then
            inst.components.lighttweener:StartTween(nil, 1, 0.6, 0.7, {180 / 255, 195 / 255, 150 / 255}, 2, TurnOn)
        elseif inst:HasTag("cave_light") then
            inst.components.lighttweener:StartTween(nil, 1 * 3, 0.8, 0.7, {180 / 255, 195 / 255, 150 / 255}, 2, TurnOn)
        end
    end,

    dusk = function(inst)
        inst.Light:Enable(true)
        if inst:HasTag("ruins_light") then
            inst.components.lighttweener:StartTween(nil, 0.75, 0.6, 0.7, {100 / 255, 100 / 255, 100 / 255}, 2, TurnOn)
        elseif inst:HasTag("cave_light") then
            inst.components.lighttweener:StartTween(nil, 0.75 * 3, 0.8, 0.7, {100 / 255, 100 / 255, 100 / 255}, 2, TurnOn)
        end
    end,

    night = function(inst)
        if TheWorld.state.moonphase == "full" then
            if inst:HasTag("ruins_light") then
                inst.components.lighttweener:StartTween(nil, 1, 0.5, 0.6, {91 / 255, 164 / 255, 255 / 255}, 4, TurnOn)
            elseif inst:HasTag("cave_light") then
                inst.components.lighttweener:StartTween(nil, 1 * 3, 0.5, 0.6, {91 / 255, 164 / 255, 255 / 255}, 4, TurnOn)
            end

        else
            inst.components.lighttweener:StartTween(nil, 0, 0, 1, {0, 0, 0}, 6, TurnOff)
        end
    end,
}

local function OnPhaseChange(inst, phase)
    phase_functions[phase](inst)
end

local function OnSave(inst, data)
    if inst:HasTag("localtrap") then
        data.localtrap = true
    end
end

local function OnLoad(inst, data)
    if data and data.localtrap then
        inst:AddTag("localtrap")
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddLight()

    inst.AnimState:SetBank("ruins_light_cone")
    inst.AnimState:SetBuild("ruins_light_beam")
    inst.AnimState:PlayAnimation("idle_loop", true)
    inst.AnimState:SetMultColour(255 / 255, 177 / 255, 32 / 255, 0)

    inst:AddTag("NOBLOCK")
    inst:AddTag("NOCLICK")

    inst:AddComponent("lighttweener")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:WatchWorldState("phase", OnPhaseChange)
    OnPhaseChange(inst, TheWorld.state.phase)

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad

    return inst
end

local function ruinsfn()
    local inst = fn()

    inst:AddTag("ruins_light")

    inst.components.lighttweener:StartTween(inst.Light, 1, 0.6, 0.7, {180 / 255, 195 / 255, 150 / 255}, 0)

    if not TheWorld.ismastersim then
        return inst
    end

    return inst
end

local function cavefn()
    local inst = fn()

    inst:AddTag("cave_light")

    inst.components.lighttweener:StartTween(inst.Light, 1 * 3, 0.8, 0.7, {180 / 255, 195 / 255, 150 / 255}, 0)

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("creatureprox")
    inst.components.creatureprox:SetOnNear(TriggerTraps)
    inst.components.creatureprox:SetFindTestFn(CreatureProxTest)
    inst.components.creatureprox:SetDist(1.4, 1.5)
    inst.components.creatureprox.inventorytrigger = true

    return inst
end

return  Prefab("pig_ruins_light_beam", ruinsfn, assets, prefabs),
        Prefab("roc_cave_light_beam", cavefn, assets, prefabs)
