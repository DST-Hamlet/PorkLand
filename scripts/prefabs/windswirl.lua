local assets =
{
    Asset("ANIM", "anim/wind_fx.zip"),
}

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    --[[Non-networked entity]]

    inst.AnimState:SetBuild("wind_fx")
    inst.AnimState:SetBank("wind_fx")
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    --inst.AnimState:SetLayer(LAYER_BACKGROUND)
    inst.Transform:SetNoFaced()
    inst.AnimState:SetSortOrder(3)
    inst.AnimState:PlayAnimation("side_wind_loop", false)

    inst:AddTag("FX")
    inst:AddTag("NOCLICK")

    local speed = TheWorld.net.components.plateauwind:GetWindSpeed()
    if speed < 0.01 then
        inst:Remove()
    else
        inst.AnimState:SetMultColour(1, 1, 1,  math.clamp(speed, 0.0, 1.0))
    end

    inst.persists = false
    inst:ListenForEvent("animover", inst.Remove)
    inst:ListenForEvent("entitysleep", inst.Remove)

    return inst
end

return Prefab("windswirl", fn, assets)
