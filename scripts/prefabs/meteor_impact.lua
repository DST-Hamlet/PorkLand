local assets =
{
	Asset("ANIM", "anim/meteor_impact.zip"),
}

local function RemoveImpact(inst)
    inst.components.colourtweener:StartTween({0, 0, 0, 0}, 5, inst.Remove)
    inst.persists = false
end

local function ontimerdone(inst, data)
    if data.name == "remove" then
        RemoveImpact(inst)
    end
end

local function fn()
	local inst = CreateEntity()
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("meteorimpact")
    inst.AnimState:SetBuild("meteor_impact")
    inst.AnimState:PlayAnimation("idle_loop")
    inst.AnimState:SetFinalOffset(-1)
    inst.AnimState:SetLayer(LAYER_BACKGROUND)
    inst.AnimState:SetSortOrder(3)

    inst:AddTag("fx")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("colourtweener")

    inst:AddComponent("timer")

    inst:ListenForEvent("timerdone", ontimerdone)

    return inst
end

return Prefab("meteor_impact", fn, assets)
