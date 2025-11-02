local assets =
{
    Asset("ANIM", "anim/waterfall_lilypond_base.zip"),
    Asset("ANIM", "anim/waterfall_lilypond_corner_base.zip"),
}

local function OnSave(inst, data)
    if inst._paramrotation then
        data.paramrotation_version_2 = inst._paramrotation:value()
    end
end

local function OnLoad(inst, data)
    if not data then
        inst:Remove()
        return
    end

    if data.paramrotation_version_2 then
        inst._paramrotation:set(data.paramrotation_version_2)
    else
        inst:Remove()
    end
end

local function OnEntitySleep(inst, data)

end

local function OnEntityWake(inst, data)

end

local function register_pool(inst)
    TheWorld:PushEvent("ms_registerwaterfall", {waterfall = inst})
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    inst.AnimState:SetBuild("waterfall_lilypond_base")
    inst.AnimState:SetBank("waterfall_pl")
    inst.AnimState:PlayAnimation("idle", false)
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    inst.AnimState:SetDefaultEffectHandle(resolvefilepath("shaders/anim_waterfall.ksh"))

    inst.AnimState:SetLayer(LAYER_BELOW_GROUND)
    inst.AnimState:SetSortOrder(3)
    inst.AnimState:SetDepthTestEnabled(true)
    inst.AnimState:SetDepthWriteEnabled(true)

    inst._paramrotation = net_float(inst.GUID, "_paramrotation", "paramrotationdirty")

    inst:DoStaticTaskInTime(0, function()
        local x, _, z = inst.Transform:GetWorldPosition()
        inst.AnimState:SetFloatParams(x, z, (inst._paramrotation:value() or 0) * DEGREES) -- 不要用setrotation，直接修改paramrotation的参数就行
    end)

    inst:AddTag("FX")
    inst:AddTag("NOCLICK")

    if not TheNet:IsDedicated() then
        inst:DoTaskInTime(0, register_pool)
    end

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad

    inst.OnEntitySleep = OnEntitySleep
    inst.OnEntityWake = OnEntityWake

    return inst
end

local function corner_fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    inst.AnimState:SetBuild("waterfall_lilypond_corner_base")
    inst.AnimState:SetBank("waterfall_corner_pl")
    inst.AnimState:PlayAnimation("idle", false)
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    inst.AnimState:SetDefaultEffectHandle(resolvefilepath("shaders/anim_waterfall_corner.ksh"))

    inst.AnimState:SetLayer(LAYER_BELOW_GROUND)
    inst.AnimState:SetSortOrder(3)
    inst.AnimState:SetDepthTestEnabled(true)
    inst.AnimState:SetDepthWriteEnabled(true)

    inst._paramrotation = net_float(inst.GUID, "_paramrotation")

    inst:DoStaticTaskInTime(0, function()
        local x, _, z = inst.Transform:GetWorldPosition()
        inst.AnimState:SetFloatParams(x, z, (inst._paramrotation:value() or 0) * DEGREES) -- 不要用setrotation，直接修改paramrotation的参数就行
    end)

    inst:AddTag("FX")
    inst:AddTag("NOCLICK")

    if not TheNet:IsDedicated() then
        inst:DoTaskInTime(0, register_pool)
    end

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad

    inst.OnEntitySleep = OnEntitySleep
    inst.OnEntityWake = OnEntityWake

    return inst
end

return Prefab("waterfall_lilypond", fn, assets),
    Prefab("waterfall_lilypond_corner", corner_fn, assets)
