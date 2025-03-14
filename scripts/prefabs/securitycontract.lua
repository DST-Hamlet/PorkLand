local assets =
{
    Asset("ANIM", "anim/security_contract.zip"),
}

local function fn(inst)
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)
    PorkLandMakeInventoryFloatable(inst)

    inst.AnimState:SetBank("security_contract")
    inst.AnimState:SetBuild("security_contract")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("securitycontract")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("tradable")

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.foleysound = "dontstarve/movement/foley/jewlery"

    inst:AddComponent("erasablepaper")

    MakeHauntableLaunch(inst)

    return inst
end

return Prefab("securitycontract", fn, assets)
