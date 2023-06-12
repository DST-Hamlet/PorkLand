local assets =
{
	Asset( "ANIM", "anim/mist_fx.zip" )
}

local function fn(Sim)
	local inst = CreateEntity()
	
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddNetwork()
	
	inst:AddTag("NOCLICK")

    inst.AnimState:SetBuild("mist_fx")
    inst.AnimState:SetBank("mist_fx")
    inst.AnimState:PlayAnimation("idle", true)

    local cloudScale = (math.random() * 1.5) + 1.5
    inst.Transform:SetScale(cloudScale, cloudScale, cloudScale)
    inst.AnimState:SetMultColour(0.3, 0.6, 0.2, 1)

    inst.AnimState:SetTime(math.random() * inst.AnimState:GetCurrentAnimationLength())

	inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    return inst
end

return Prefab("poisonmist", fn, assets) 
 
