local assets =
{
    Asset("ANIM", "anim/bearger_ring_fx.zip"),
}

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    --[[Non-networked entity]]

    inst:AddTag("FX")

    inst.AnimState:SetBank("bearger_ring_fx")
    inst.AnimState:SetBuild("bearger_ring_fx")
    inst.AnimState:PlayAnimation("idle")
    inst.AnimState:SetFinalOffset(3)
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    inst.AnimState:SetLayer(LAYER_BACKGROUND)
    inst.AnimState:SetSortOrder(3)

    inst.Transform:SetScale(2, 2, 2)

    inst.persists = false

    inst:ListenForEvent("animover", inst.Remove)
    inst:ListenForEvent("entitysleep", inst.Remove)

    return inst
end

return Prefab("batsonar_fx", fn, assets)
