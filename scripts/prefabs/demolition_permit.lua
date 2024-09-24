local assets=
{
    Asset("ANIM", "anim/permit_demolition.zip"),
}

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)
    PorkLandMakeInventoryFloatable(inst, "idle_water", "idle")

    inst.AnimState:SetBank("permit_demolition")
    inst.AnimState:SetBuild("permit_demolition")
    inst.AnimState:PlayAnimation("idle")

    inst.foleysound = "dontstarve/movement/foley/jewlery"

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")

    inst:AddComponent("roomdemolisher")

    MakeHauntableLaunch(inst)

    return inst
end

return Prefab("demolition_permit", fn, assets)
