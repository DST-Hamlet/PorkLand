local assets=
{
  Asset("ANIM", "anim/vine.zip"),
}

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()

    MakeInventoryPhysics(inst)
    MakeBlowInHurricane(inst, TUNING.WINDBLOWN_SCALE_MIN.LIGHT, TUNING.WINDBLOWN_SCALE_MAX.LIGHT)
    MakeInventoryFloatable(inst, "idle_water", "idle")

    inst.AnimState:SetBank("vine")
    inst.AnimState:SetBuild("vine")
    inst.AnimState:PlayAnimation("idle")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    MakeBlowInHurricane(inst, TUNING.WINDBLOWN_SCALE_MIN.LIGHT, TUNING.WINDBLOWN_SCALE_MAX.LIGHT)

    inst:AddComponent("stackable")
    inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM

    --inst:AddComponent("edible")
    --inst.components.edible.foodtype = "WOOD"
    --inst.components.edible.woodiness = 10


    inst:AddComponent("fuel")
    inst.components.fuel.fuelvalue = TUNING.MED_FUEL

    inst:AddComponent("appeasement")
    inst.components.appeasement.appeasementvalue = TUNING.WRATH_SMALL


    MakeSmallBurnable(inst, TUNING.MED_BURNTIME)
    MakeSmallPropagator(inst)
    --inst.components.burnable:MakeDragonflyBait(3)

    ---------------------

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")

   -- inst:AddComponent("repairer")
   -- inst.components.repairer.repairmaterial = "wood"
    --inst.components.repairer.healthrepairvalue = TUNING.REPAIR_LOGS_HEALTH

    --inst:ListenForEvent("burnt", function(inst) inst.entity:Retire() end)

    return inst
end

return Prefab( "vine", fn, assets)

