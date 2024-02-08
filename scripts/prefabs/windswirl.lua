local assets =
{
	Asset("ANIM", "anim/wind_fx.zip")
}

local function fn()
	local inst = CreateEntity()
	inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst.AnimState:SetBuild("wind_fx")
    inst.AnimState:SetBank("wind_fx")
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
	inst.AnimState:PlayAnimation("side_wind_loop", true)

	inst:AddTag("FX")
	inst:AddTag("NOCLICK")

    if not TheWorld.ismastersim then
        return
    end

	inst.persists = false
	inst:ListenForEvent("animover", inst.Remove)
	inst:ListenForEvent("entitysleep", inst.Remove)

    return inst
end

return Prefab("windswirl", fn, assets, nil)