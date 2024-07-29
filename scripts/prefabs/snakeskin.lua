local assets =
{
    Asset("ANIM", "anim/snakeskin.zip"),
    Asset("ANIM", "anim/snakeskin_scaly.zip"),
}

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("snakeskin")
    inst.AnimState:SetBuild("snakeskin")
    inst.AnimState:PlayAnimation("idle")

    MakeInventoryPhysics(inst)
    PorkLandMakeInventoryFloatable(inst)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")

    inst:AddComponent("visualvariant")
    inst.components.visualvariant:SetVariantData("snakeskin")

    inst:AddComponent("stackable")
    inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM

    MakeBlowInHurricane(inst, TUNING.WINDBLOWN_SCALE_MIN.LIGHT, TUNING.WINDBLOWN_SCALE_MAX.LIGHT)
    MakeSmallBurnable(inst, TUNING.MED_BURNTIME)
    MakeHauntableLaunch(inst)
    MakeSmallPropagator(inst)

    return inst
end

return Prefab("snakeskin", fn, assets)
