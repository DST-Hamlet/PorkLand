local assets = {
    Asset("ANIM", "anim/fabric.zip"),
}

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("fabric")
    inst.AnimState:SetBuild("fabric")
    inst.AnimState:PlayAnimation("idle")

    inst.pickupsound = "cloth"

    MakeInventoryPhysics(inst)

    MakeInventoryFloatable(inst)
    inst.components.floater:UpdateAnimations("idle_water", "idle")

    inst:AddTag("cattoy")
    inst:AddComponent("tradable")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
      return inst
    end

    inst:AddComponent("stackable")

    inst:AddComponent("inspectable")
    inst:AddComponent("inventoryitem")

    inst:AddComponent("fuel")
    inst.components.fuel.fuelvalue = TUNING.MED_FUEL

    MakeBlowInHurricane(inst, TUNING.WINDBLOWN_SCALE_MIN.LIGHT, TUNING.WINDBLOWN_SCALE_MAX.LIGHT)
    MakeHauntableLaunch(inst)
    MakeSmallBurnable(inst, TUNING.LARGE_BURNTIME)
    MakeSmallPropagator(inst)

    return inst
end

return Prefab("fabric", fn, assets)
