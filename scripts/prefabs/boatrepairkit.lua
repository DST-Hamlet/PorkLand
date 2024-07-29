local assets = {
    Asset("ANIM", "anim/boat_repair_kit.zip"),
}

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("boat_repair_kit")
    inst.AnimState:SetBuild("boat_repair_kit")
    inst.AnimState:PlayAnimation("idle")

    PorkLandMakeInventoryFloatable(inst)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")
    inst:AddComponent("inventoryitem")

    inst:AddComponent("finiteuses")
    inst.components.finiteuses:SetMaxUses(TUNING.BOAT_REPAIR_KIT_USES)
    inst.components.finiteuses:SetUses(TUNING.BOAT_REPAIR_KIT_USES)
    inst.components.finiteuses:SetOnFinished(inst.Remove)

    inst:AddComponent("repairer")
    inst.components.repairer.healthrepairvalue = TUNING.BOAT_REPAIR_KIT_HEALING
    inst.components.repairer.repairmaterial = "boat"


    MakeHauntableLaunch(inst)
    return inst
end

return Prefab("boatrepairkit", fn, assets)
