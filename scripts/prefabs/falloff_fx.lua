local assets =
{
    Asset("ANIM", "anim/falloff.zip"),

    Asset("ANIM", "anim/mud_falloff_1.zip"),
    Asset("ANIM", "anim/mud_falloff_2.zip"),
    Asset("ANIM", "anim/mud_falloff_3.zip"),
    Asset("ANIM", "anim/mud_falloff_4.zip"),
    Asset("ANIM", "anim/mud_falloff_5.zip"),
    Asset("ANIM", "anim/mud_falloff_6.zip"),
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

local builds =
{
    "mud_falloff_1",
    "mud_falloff_2",
    "mud_falloff_3",
    "mud_falloff_4",
    "mud_falloff_5",
    "mud_falloff_6",
}

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    inst.AnimState:SetBuild("mud_falloff_1")
    inst.AnimState:SetBank("falloff")
    inst.AnimState:PlayAnimation("idle", false)
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    inst.AnimState:SetDefaultEffectHandle(resolvefilepath("shaders/anim_vertical.ksh"))

    inst.AnimState:SetLayer(LAYER_BELOW_GROUND)
    inst.AnimState:SetSortOrder(0)
    inst.AnimState:SetFinalOffset(-2)

    inst._paramrotation = net_float(inst.GUID, "_paramrotation", "paramrotationdirty")

    inst:DoStaticTaskInTime(0, function()
        inst.AnimState:SetBuild(builds[math.random(#builds)])
        local x, _, z = inst.Transform:GetWorldPosition()
        inst.AnimState:SetFloatParams(x, z, (inst._paramrotation:value() or 0) * DEGREES) -- 不要用setrotation，直接修改paramrotation的参数就行
    end)

    inst:AddTag("FX")
    inst:AddTag("NOCLICK")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad

    return inst
end

return Prefab("falloff_fx", fn, assets)
