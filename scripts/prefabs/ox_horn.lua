local assets =
{
    Asset("ANIM", "anim/ox_horn.zip"),
}

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("ox_horn")
    inst.AnimState:SetBuild("ox_horn")
    inst.AnimState:PlayAnimation("idle")

    MakeInventoryPhysics(inst)
    PorkLandMakeInventoryFloatable(inst, "idle_water", "idle")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")

    inst:AddComponent("stackable")
    inst.components.stackable.maxsize = TUNING.STACK_SIZE_LARGEITEM -- needs to be one of the tuning values because of stackable_replica

    MakeHauntableLaunch(inst)

    return inst
end

return Prefab("ox_horn", fn, assets)
