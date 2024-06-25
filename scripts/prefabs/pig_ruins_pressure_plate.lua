local assets =
{
    Asset("ANIM", "anim/pressure_plate.zip"),
    Asset("ANIM", "anim/pressure_plate_build.zip"),
}

local prefabs =
{
    "pig_ruins_dart",
}

local DART_TRAP_TAGS = {"dartthrower"}
local SPEAR_TRAP_TAGS = {"spear_trap"}
local DOOR_TRAP_TAGS = {"lockable_door"}

local function Trigger(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    local dist = 50

    if inst:HasTag("trap_dart") then
        local ents = TheSim:FindEntities(x, y, z, dist, DART_TRAP_TAGS)
        for _, ent in pairs(ents) do
            if ent.components.autodartthrower then
                ent.components.autodartthrower:TurnOn()
            elseif ent.shoot then
                ent.shoot(ent)
            end
        end
    elseif inst:HasTag("trap_spear") then
        if inst:HasTag("localtrap") then
            dist = 4
        end
        local ents = TheSim:FindEntities(x, y, z, dist, SPEAR_TRAP_TAGS)
        for _, ent in pairs(ents) do
            ent:PushEvent("triggertrap")
        end
    else
        local ents = TheSim:FindEntities(x, y, z, dist, DOOR_TRAP_TAGS)
        for _, ent in pairs(ents) do
            ent:PushEvent("open")
        end
    end
end

local function Untrigger(inst)
    if inst:HasTag("trap_dart") then
        return
    end

    local x, y, z = inst.Transform:GetWorldPosition()
    local dist = 50

    if inst:HasTag("trap_spear") then
        if inst:HasTag("localtrap") then
            dist = 4
        end
        local ents = TheSim:FindEntities(x, y, z, dist, SPEAR_TRAP_TAGS)
        for _, ent in pairs(ents) do
            ent:PushEvent("reset")
        end
    else
        local ents = TheSim:FindEntities(x, y, z, dist, DOOR_TRAP_TAGS)
        for _, ent in pairs(ents) do
            ent:PushEvent("close")
        end
    end
end

local function OnNear(inst)
    if inst.components.disarmable.armed and not inst.down then
        inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/items/pressure_plate/hit")
        inst.AnimState:PlayAnimation("popdown")
        inst.AnimState:PushAnimation("down_idle")
        inst.down = true
        if inst:HasTag("reversetrigger") then
            Untrigger(inst)
        else
            Trigger(inst)
        end
    end
end

local function OnFar(inst)
    if not inst:HasTag("INTERIOR_LIMBO") and inst.components.disarmable.armed and inst.down then
        inst.AnimState:PlayAnimation("popup")
        inst.AnimState:PushAnimation("up_idle")
        inst.down = nil
        if inst:HasTag("reversetrigger") then
            Trigger(inst)
        else
            Untrigger(inst)
        end
    end
end

local function TestFn(testinst)
    return not testinst:HasTag("flying") and not testinst:HasTag("notraptrigger")
end

local function Disarm(inst, doer)
   inst.AnimState:PlayAnimation("disarmed")
   inst.components.creatureprox:SetEnabled(false)
   inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/traps/disarm_floor")
   inst.down = false
end

local function Rearm(inst, doer)
    inst.AnimState:PlayAnimation("up_idle")
    inst.components.creatureprox:SetEnabled(true)
    inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/traps/disarm_floor")
    if inst.components.creatureprox then
       inst.components.creatureprox:ForceUpdate()
    end
end

local function CheckStartDown(inst)
    if inst:HasTag("startdown") then
        inst.down = true
        inst.AnimState:PlayAnimation("down_idle")
    end
end

local function OnSave(inst, data)
    if inst:HasTag("trap_dart") then
        data.trap_type = "trap_dart"
    end
    if inst:HasTag("trap_spear") then
        data.trap_type = "trap_spear"
    end
    if inst:HasTag("localtrap") then
        data.localtrap = true
    end
    if inst:HasTag("reversetrigger") then
        data.reversetrigger = true
    end
    if inst:HasTag("startdown") then
        data.startdown = true
    end
end

local function OnLoad(inst, data)
    if data then
        if data.trap_type then
            inst:AddTag(data.trap_type)
        end
        if data.localtrap then
            inst:AddTag("localtrap")
        end
        if data.reversetrigger then
            inst:AddTag("reversetrigger")
        end
        if data.startdown then
            inst:AddTag("startdown")
        end
    end

    if not inst.components.disarmable.armed then
        inst.AnimState:PlayAnimation("disarmed")
        inst.components.creatureprox:SetEnabled(false)
        inst.down = false
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("pressure_plate")
    inst.AnimState:SetBuild("pressure_plate_build")
    inst.AnimState:PlayAnimation("up_idle")
    inst.AnimState:SetLayer(LAYER_BACKGROUND)
    inst.AnimState:SetSortOrder(3)

    inst:AddTag("structure")
    inst:AddTag("weighdownable")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("disarmable")
    inst.components.disarmable.disarmfn = Disarm
    inst.components.disarmable.rearmfn = Rearm
    inst.components.disarmable.rearmable = true

    inst:AddComponent("creatureprox")
    inst.components.creatureprox:SetOnNear(OnNear)
    inst.components.creatureprox:SetOnFar(OnFar)
    inst.components.creatureprox:SetFindTestFn(TestFn)
    inst.components.creatureprox:SetDist(0.8, 0.9)
    inst.components.creatureprox.inventorytrigger = true
    inst.components.creatureprox.period = 0.01

    inst:AddComponent("hiddendanger")

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad

    inst:DoTaskInTime(0, CheckStartDown)

    return inst
end

return  Prefab("pig_ruins_pressure_plate", fn, assets, prefabs)
