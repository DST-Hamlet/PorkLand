local assets =
{
    Asset("ANIM", "anim/cloud_puff_soft.zip"),
}

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    --[[Non-networked entity]]

    inst.AnimState:SetBuild("cloud_puff_soft")
    inst.AnimState:SetBank("cloud_puff_soft")
    inst.AnimState:PlayAnimation("idle_sink", false)

    inst:AddTag("FX")
    inst:AddTag("NOCLICK")
    inst:AddTag("NOBLOCK")

    inst.persists = false

    inst:ListenForEvent("animover", inst.Remove)
    inst:ListenForEvent("entitysleep", inst.Remove)

    return inst
end

return Prefab("cloudpuff_visual", fn, assets)
