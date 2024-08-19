local assets =
{
    Asset("ANIM", "anim/pedestal_key.zip"),
}

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("pedestal_key")
    inst.AnimState:SetBuild("pedestal_key")
    inst.AnimState:PlayAnimation("idle")

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")

    inst:AddComponent("tradable")

    inst:AddComponent("stackable")
    inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM

    inst:AddComponent("key")
    inst.components.key.keytype = LOCKTYPE.ROYAL

    return inst
end

return Prefab("pedestal_key", fn, assets)
