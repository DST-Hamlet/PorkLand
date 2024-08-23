local assets =
{
    Asset("ANIM", "anim/waterfall_lilypond.zip"),
    Asset("ANIM", "anim/waterfall_lilypond_alpha.zip"),
    Asset("ANIM", "anim/waterfall_lilypond_mix.zip"),
    Asset("ANIM", "anim/waterfall_lilypond_base.zip"),
}

local function CreateAlphaChild(inst)
    local alphachild = SpawnPrefab("waterfall_lilypond_alpha")
    alphachild.entity:SetParent(inst.entity)
    inst.waterfall_alpha = alphachild
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    --[[Non-networked entity]]

    inst.AnimState:SetBuild("waterfall_lilypond_base")
    inst.AnimState:SetBank("waterfall_pl")
    inst.AnimState:PlayAnimation("idle", false)
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    inst.AnimState:SetDefaultEffectHandle(resolvefilepath("shaders/anim_waterfall.ksh"))

    inst.AnimState:SetLayer(LAYER_BELOW_GROUND)
    inst.AnimState:SetFinalOffset(-2)

    CreateAlphaChild(inst)

    inst:DoPeriodicTask(FRAMES, function()
        local x, _, z = inst.Transform:GetWorldPosition()
        inst.AnimState:SetFloatParams(x, z, inst.paramrotation or 0)
    end)

    inst:AddTag("FX")
    inst:AddTag("NOCLICK")

    inst.persists = false

    return inst
end

local function alpha_fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    --[[Non-networked entity]]

    inst.AnimState:SetBuild("waterfall_lilypond_base")
    inst.AnimState:SetBank("waterfall_pl")
    inst.AnimState:PlayAnimation("idle", false)
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    inst.AnimState:SetDefaultEffectHandle(resolvefilepath("shaders/anim_waterfall_alpha.ksh"))

    inst.AnimState:SetLayer(LAYER_BELOW_GROUND)
    inst.AnimState:SetFinalOffset(2)

    inst:DoPeriodicTask(FRAMES, function()
        local x, _, z = inst.Transform:GetWorldPosition()
        inst.AnimState:SetFloatParams(x, z, inst.paramrotation or 0)
    end)

    inst:AddTag("FX")
    inst:AddTag("NOCLICK")

    inst.persists = false

    return inst
end

return Prefab("waterfall_lilypond", fn, assets),
    Prefab("waterfall_lilypond_alpha", alpha_fn, assets)
