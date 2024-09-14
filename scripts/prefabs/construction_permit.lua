local assets =
{
    Asset("ANIM", "anim/permit_reno.zip"),
}

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)
    PorkLandMakeInventoryFloatable(inst, "idle_water", "idle")

    inst.AnimState:SetBank("permit_reno")
    inst.AnimState:SetBuild("permit_reno")
    inst.AnimState:PlayAnimation("idle")

    inst.foleysound = "dontstarve/movement/foley/jewlery"

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")

    inst:AddComponent("roombuilder")

    MakeHauntableLaunch(inst)

    return inst
end

return Prefab("construction_permit", fn, assets)
