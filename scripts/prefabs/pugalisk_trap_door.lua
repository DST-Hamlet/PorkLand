local assets =
{
    Asset("ANIM", "anim/python_trap_door.zip"),
}

local prefabs =
{
    "pugalisk"
}

local STATES = {
   CLOSED = 1,
   OPENING = 2,
   OPEN = 3,
   CLOSNG = 4,
}

local STATE_TO_ANIMATION = {
    [STATES.CLOSED] = "closed",
    [STATES.OPENING] = "opening",
    [STATES.OPEN] = "open",
    [STATES.CLOSNG] = "closing",
}

local function DoSpawnPugalisk(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    local pugalisk = SpawnPrefab("pugalisk")
    pugalisk.Transform:SetPosition(x,y,z)
    pugalisk.home = TheSim:FindFirstEntityWithTag("pugalisk_fountain")
    pugalisk.sg:GoToState("emerge_taunt")
    pugalisk.wantstotaunt = false
    inst.doingpugaliskspawn = nil
end

local function SpawnPugalisk(inst)
    inst.doingpugaliskspawn = true
    local pugalisk = TheSim:FindFirstEntityWithTag("pugalisk")
    if not pugalisk then
        inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/pugalisk/entrance")
        inst.task, inst.taskinfo = inst:ResumeTask(2, DoSpawnPugalisk)
    end
end

local function activate(inst)
    if not GetWorldSetting("pugalisk_fountain", true) then
        return
    end

    if inst.state == STATES.CLOSED then
        inst.state = STATES.OPENING
        inst.AnimState:PlayAnimation("opening")
        inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/pugalisk/trap_door")

        ShakeAllCameras(CAMERASHAKE.FULL, 1, 0.02, 40, inst, 45)
    end
end

local function reactivate(inst)
    if inst.state == STATES.OPEN then
        inst.state = STATES.CLOSING
        inst.AnimState:PlayAnimation("closing")
    end
end

local function OnSave(inst, data)
    data.rotation = inst.Transform:GetRotation()

    if inst.doingpugaliskspawn then
        data.doingpugaliskspawn = true
    end

    if inst.state then
        data.state = inst.state
    end
end

local function OnLoad(inst, data)
    if data then
        if data.rotation then
            inst.Transform:SetRotation(data.rotation)
        end
        if data.state then
            inst.state = data.state
        end
        if data.doingpugaliskspawn then
            SpawnPugalisk(inst)
        end
    end

    inst.AnimState:PlayAnimation(STATE_TO_ANIMATION[inst.state], inst.state ~= STATES.CLOSING)
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    inst.AnimState:SetBuild("python_trap_door")
    inst.AnimState:SetBank("python_trap_door")
    inst.AnimState:PlayAnimation("closed", true)
    inst.AnimState:SetLayer(LAYER_BACKGROUND)
    inst.AnimState:SetSortOrder(3)

    inst:AddTag("pugalisk_trap_door")

    inst.state = STATES.CLOSED

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    MakeHauntable(inst)

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad

    inst:ListenForEvent("activate", activate)
    inst:ListenForEvent("reactivate", reactivate)

    inst:ListenForEvent("animover", function(inst)
        if inst.state == STATES.OPENING then
            inst.state = STATES.OPEN
            inst.AnimState:PlayAnimation("open", true)
            inst.SoundEmitter:KillSound("quake")
            SpawnPugalisk(inst)
        elseif inst.state == STATES.CLOSING then
            inst.state = STATES.CLOSED
            inst.AnimState:PlayAnimation("closed",true)
        end
    end)

    return inst
end

return Prefab("pugalisk_trap_door", fn, assets, prefabs)

