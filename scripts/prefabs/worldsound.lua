local assets =
{
}

local prefabs =
{
}

local function UpdateSound(inst)
    if TheWorld.ismastersim then -- 在主机更新自己的位置数据
        if inst.followentity and inst.followentity:IsValid() and not inst.followentity:IsInLimbo() then
            inst.Transform:SetPosition(inst.followentity:GetPosition():Get())
        end
    end
    if inst._soundpath:value() ~= "" then
        local x, y, z = inst.Transform:GetWorldPosition()
        local distancesq = 0
        if ThePlayer then
            distancesq = ThePlayer:GetDistanceSqToPoint(x, y, z)
        end
        if inst.emitter == nil then
            inst.emitter = SpawnPrefab("worldsoundemitter")
            inst.emitter.entity:SetParent(inst.entity)
            if distancesq > inst._distance:value() * inst._distance:value() then
                inst.emitter.SoundEmitter:SetVolume(inst._sound:value(), 0)
            else
                inst.emitter.SoundEmitter:SetVolume(inst._sound:value(), 1)
            end
            inst.emitter.SoundEmitter:PlaySound(inst._soundpath:value(), inst._sound:value())
            inst.emitter.SoundEmitter:SetParameter(inst._sound:value(), inst._param:value(), inst._paramval:value())
        end
        if distancesq > inst._distance:value() * inst._distance:value() then
            inst.emitter.SoundEmitter:SetVolume(inst._sound:value(), 0)
        else
            inst.emitter.SoundEmitter:SetVolume(inst._sound:value(), 1)
        end
        inst.emitter.SoundEmitter:SetParameter(inst._sound:value(), inst._param:value(), inst._paramval:value())

        if inst.emitter and not inst.emitter.SoundEmitter:PlayingSound(inst._sound:value()) then
            inst.emitter:Remove()
            inst:Remove()
        end
    else
        if inst.emitter then
            inst.emitter:Remove()
        end
        inst:Remove()
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddNetwork()
    inst.entity:SetPristine()

    inst.persists = false

    inst.entity:SetCanSleep(false)

    inst:AddTag("NOBLOCK")
    inst:AddTag("CLASSIFIED")

    inst.followentity = nil

    inst._soundpath = net_string(inst.GUID, "_soundpath")
    inst._sound = net_string(inst.GUID, "_sound")
    inst._param = net_string(inst.GUID, "_param")
    inst._paramval = net_float(inst.GUID, "_paramval")
    inst._areamode = net_shortint(inst.GUID, "_areamode")
    inst._distance = net_float(inst.GUID, "_distance")

    inst:DoPeriodicTask(FRAMES, UpdateSound) -- 在每个客户端执行

    if not TheWorld.ismastersim then
        return inst
    end

    return inst
end

local function emitterfn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddSoundEmitter()
    inst.entity:SetPristine()

    inst.persists = false

    inst:AddTag("NOBLOCK")
    inst:AddTag("CLASSIFIED")

    --[[Non-networked entity]]

    return inst
end

return  Prefab("worldsound", fn, assets, prefabs),
    Prefab("worldsoundemitter", emitterfn, assets, prefabs)
