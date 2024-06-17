local assets =
{
    Asset("ANIM", "anim/action_lines.zip"),
}

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst.AnimState:SetBuild("action_lines")
    inst.AnimState:SetBank("action_lines")
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    inst.Transform:SetNoFaced()
    --inst.AnimState:SetLayer(LAYER_BACKGROUND)
    inst.AnimState:SetSortOrder(3)
    inst.AnimState:PlayAnimation("idle_loop", false)

    inst:AddTag("FX")
    inst:AddTag("NOCLICK")

    if not TheWorld.ismastersim then
        return inst
    end

    inst.persists = false
    inst:ListenForEvent("animover", inst.Remove)
    inst:ListenForEvent("entitysleep", inst.Remove)

    return inst
end

return Prefab("windtrail", fn, assets)
