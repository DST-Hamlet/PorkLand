local function MakeFeather(name)
    local asset_name = "feather_"..name
    local assets =
    {
        Asset("ANIM", "anim/" .. asset_name .. ".zip"),
    }

    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddNetwork()

        MakeInventoryPhysics(inst)
        PorkLandMakeInventoryFloatable(inst, "idle_water", "idle")

        inst.AnimState:SetBank(asset_name)
        inst.AnimState:SetBuild(asset_name)
        inst.AnimState:PlayAnimation("idle")

        inst.pickupsound = "cloth"

        inst:AddTag("cattoy")
        inst:AddTag("birdfeather")

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        inst:AddComponent("stackable")
        inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM

        inst:AddComponent("inspectable")

        inst:AddComponent("inventoryitem")
        inst.components.inventoryitem.nobounce = true

        inst:AddComponent("tradable")

        inst:AddComponent("fuel")
        inst.components.fuel.fuelvalue = TUNING.TINY_FUEL

        MakeSmallBurnable(inst, TUNING.SMALL_BURNTIME)
        MakeSmallPropagator(inst)
        MakeHauntableLaunchAndIgnite(inst)
        MakeBlowInHurricane(inst, TUNING.WINDBLOWN_SCALE_MIN.LIGHT, TUNING.WINDBLOWN_SCALE_MAX.LIGHT)

        return inst
    end
    return Prefab( asset_name, fn, assets)
end

return MakeFeather("thunder")
