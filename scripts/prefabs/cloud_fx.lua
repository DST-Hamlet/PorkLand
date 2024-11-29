local assets =
{
    Asset("ANIM", "anim/cloudwave.zip"),
}

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:SetCanSleep(false)
    --[[Non-networked entity]]

    inst.AnimState:SetBuild("cloudwave")
    inst.AnimState:SetBank("cloudwave")
    inst.AnimState:PlayAnimation("wave_loop", true)
    inst.AnimState:SetScale(2,2,2)
    inst.AnimState:SetFrame(math.random(inst.AnimState:GetCurrentAnimationNumFrames()) - 1)
    inst.AnimState:SetDeltaTimeMultiplier(2)

    inst.AnimState:SetLayer(LAYER_BELOW_GROUND)
    inst.AnimState:SetSortOrder(-1)
    inst.AnimState:SetFinalOffset(-2)

    inst:AddTag("FX")
    inst:AddTag("NOCLICK")
    inst:AddTag("NOBLOCK")

    inst.persists = false

    return inst
end

return Prefab("cloud_fx", fn, assets)
