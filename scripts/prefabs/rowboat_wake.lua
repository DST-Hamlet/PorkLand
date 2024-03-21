local assets =
{
    Asset("ANIM", "anim/rowboat_wake_trail.zip"),
}

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddNetwork()

    inst.persists = false

    inst.entity:AddAnimState()

    inst.AnimState:SetBuild("rowboat_wake_trail")
    inst.AnimState:SetBank("wakeTrail")
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    inst.AnimState:SetLayer(LAYER_BACKGROUND)
    inst.AnimState:SetSortOrder(-3)
    inst.AnimState:PlayAnimation("trail")
    inst.AnimState:SetOceanBlendParams(TUNING.OCEAN_SHADER.EFFECT_TINT_AMOUNT)

    --inst:Hide()
    inst:AddTag( "FX" )
    inst:AddTag( "NOCLICK" )

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:ListenForEvent("animover", inst.Remove)
    inst:ListenForEvent("entitysleep", inst.Remove)

    inst:AddComponent("colourtweener")
    inst.components.colourtweener:StartTween({0,0,0,0}, FRAMES * 20)

    return inst
end

return Prefab("rowboat_wake", fn, assets)
