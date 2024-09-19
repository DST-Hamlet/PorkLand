local assets =
{
    Asset("ANIM", "anim/sprinkler_fx.zip"),
}

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst.AnimState:SetBuild("sprinkler_fx")
    inst.AnimState:SetBank("sprinkler_fx")
    inst.AnimState:PlayAnimation("spray_loop", true)

    inst:AddTag("FX")
    inst:AddTag("NOCLICK")

    if not TheWorld.ismastersim then
        return inst
    end

    inst.persists = false

    return inst
end

return Prefab("water_spray", fn, assets)
