local assets =
{
    Asset("ANIM", "anim/roc_egg.zip"),
}

local prefabs =
{
    "ro_bin",
    "tallbirdegg_cracked",
    "tallbirdegg_cooked",
    "spoiled_food",
}

local function Hatch(inst)
    inst.components.inventoryitem.canbepickedup = false
    inst.AnimState:PlayAnimation("hatch")
    inst.persists = false
    inst:ListenForEvent("animover", inst.Remove)
    inst:ListenForEvent("entitysleep", inst.Remove)

    inst:DoTaskInTime(50/30, function()
        local stone = SpawnPrefab("ro_bin_gizzard_stone")
        local pt = Point(inst.Transform:GetWorldPosition())
        stone.Transform:SetPosition(pt.x,pt.y,pt.z)

        local down = TheCamera:GetDownVec()
        local angle = math.atan2(down.z, down.x) + (math.random()*60-30) * DEGREES
        local speed = 3
        stone.Physics:SetVel(speed*math.cos(angle), GetRandomWithVariance(8, 4), speed*math.sin(angle))
    end)
end

local function CheckHatch(inst)
    if inst.playernear
        and inst.components.hatchable.state == "hatch"
        and not inst:HasTag("INLIMBO")
        and not inst.components.inventoryitem:IsHeld()then

        Hatch(inst)
    end
end

local function PlayUncomfySound(inst)
    inst.SoundEmitter:KillSound("uncomfy")
    if inst.components.hatchable.toohot then
        inst.SoundEmitter:PlaySound("dontstarve/creatures/egg/egg_hot_steam_LP", "uncomfy")
    elseif inst.components.hatchable.toocold then
        inst.SoundEmitter:PlaySound("dontstarve/creatures/egg/egg_cold_shiver_LP", "uncomfy")
    end
end

local function OnNear(inst)
    inst.playernear = true
    CheckHatch(inst)
end

local function OnFar(inst)
    inst.playernear = false
end

local function OnPutInInventory(inst)
    inst.SoundEmitter:KillSound("uncomfy")
    inst.components.hatchable:StopUpdating()

    if inst.components.hatchable.state == "unhatched" then
        inst.components.hatchable:OnState("uncomfy")
    end
end

local function OnLoadPostPass(inst)
    --V2C: in case of load order of hatchable and inventoryitem components
    if inst.components.inventoryitem:IsHeld() then
        OnPutInInventory(inst)
    end
end

local function GetStatus(inst)
    if inst.components.hatchable then
        local state = inst.components.hatchable.state
        if state == "uncomfy" then
            if inst.components.hatchable.toohot then
                return "HOT"
            elseif inst.components.hatchable.toocold then
                return "COLD"
            end
        end
    end
end

local function OnHatchState(inst, state)
    inst.SoundEmitter:KillSound("uncomfy")

    if state == "uncomfy" then
        if inst.components.hatchable.toohot then
            inst.AnimState:PlayAnimation("idle_hot_smoulder", true)
            inst.components.floater:UpdateAnimations("idle_water", "idle_hot_smoulder")
        elseif inst.components.hatchable.toocold then
            inst.AnimState:PlayAnimation("idle_cold_frost", true)
            inst.components.floater:UpdateAnimations("idle_water", "idle_cold_frost")
        end
        PlayUncomfySound(inst)
    elseif state == "comfy" then
        inst.AnimState:PlayAnimation("idle", true)
        inst.components.floater:UpdateAnimations("idle_water", "idle")
    elseif state == "hatch" then
        CheckHatch(inst)
    end
end

local function OnDropped(inst)
    inst.components.hatchable:StartUpdating()
    CheckHatch(inst)
    PlayUncomfySound(inst)
    OnHatchState(inst, inst.components.hatchable.state)
end

local function OnUpdateFn(inst, dt)
    if inst.components.hatchable.state == "uncomfy" then
       inst.components.hatchable.progress = math.max(inst.components.hatchable.progress - (3*dt),  0)
    else
       inst.components.hatchable.discomfort = 0
    end
    local percent = inst.components.hatchable.progress / inst.components.hatchable.hatchtime

    local scale = 1 + (1.5 * percent)
    inst.Transform:SetScale(scale, scale, scale)
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)
    PorkLandMakeInventoryFloatable(inst, "idle_water", "idle")

    inst.AnimState:SetBuild("roc_egg")
    inst.AnimState:SetBank("roc_egg")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("ro_bin_egg")
    inst:AddTag("nonpotatable")
    inst:AddTag("irreplaceable")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")
    inst.components.inspectable.getstatus = GetStatus

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem:ChangeImageName("roc_egg")
    inst.components.inventoryitem:SetOnDroppedFn(OnDropped)
    inst.components.inventoryitem:SetOnPutInInventoryFn(OnPutInInventory)

    inst:AddComponent("playerprox")
    inst.components.playerprox:SetDist(4, 6)
    inst.components.playerprox:SetOnPlayerNear(OnNear)
    inst.components.playerprox:SetOnPlayerFar(OnFar)

    inst:AddComponent("hatchable")
    inst.components.hatchable:SetOnState(OnHatchState)
    inst.components.hatchable:SetCrackTime(0)
    inst.components.hatchable:SetHatchTime(TUNING.ROBIN_HATCH_TIME)
    inst.components.hatchable:SetHatchFailTime(math.huge)
    inst.components.hatchable:StartUpdating()

    inst:AddComponent("updatelooper")
    inst.components.updatelooper:AddOnUpdateFn(OnUpdateFn)

    MakeHauntableLaunch(inst)

    inst.hatch = Hatch

    inst.playernear = false

    return inst
end

return Prefab("roc_robin_egg", fn, assets, prefabs)
