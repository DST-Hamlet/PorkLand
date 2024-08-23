local assets =
{
    Asset("ANIM", "anim/waterfall_pl.zip"),
}

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    --[[Non-networked entity]]

    inst.AnimState:SetBuild("waterfall_pl")
    inst.AnimState:SetBank("waterfall_pl")
    inst.AnimState:PlayAnimation("idle", false)
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    inst.AnimState:SetDefaultEffectHandle(resolvefilepath("shaders/anim_waterfall.ksh"))

    inst:DoTaskInTime(0, function()
        local x, _, z = inst.Transform:GetWorldPosition()
        inst.AnimState:SetFloatParams(x, z, inst.Transform:GetRotation())
    end)

    inst:AddTag("FX")
    inst:AddTag("NOCLICK")

    inst.persists = false

    return inst
end

return Prefab("waterfall_lilypond", fn, assets)
