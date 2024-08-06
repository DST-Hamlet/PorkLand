local assets =
{
    Asset( "ANIM", "anim/mist_fx.zip" )
}

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst.AnimState:SetBuild("mist_fx")
    inst.AnimState:SetBank("mist_fx")
    inst.AnimState:PlayAnimation("idle", true)
    inst.AnimState:SetMultColour(0.3, 0.6, 0.2, 1)
    inst.AnimState:SetTime(math.random() * inst.AnimState:GetCurrentAnimationLength())

    local scale = (math.random() * 1.5) + 1.5
    inst.Transform:SetScale(scale, scale, scale)

    inst:AddTag("NOCLICK")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    return inst
end

return Prefab( "poisonmist", fn, assets)
