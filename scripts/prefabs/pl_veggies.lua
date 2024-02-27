local function MakeVegStats(seedweight, hunger, health, perish_time, sanity, cooked_hunger, cooked_health, cooked_perish_time, cooked_sanity, secondary_foodtype)
    return {
        health = health,
        hunger = hunger,
        cooked_health = cooked_health,
        cooked_hunger = cooked_hunger,
        seed_weight = seedweight,
        perishtime = perish_time,
        cooked_perishtime = cooked_perish_time,
        sanity = sanity,
        cooked_sanity = cooked_sanity,
        secondary_foodtype = secondary_foodtype,
    }
end

PL_VEGGIES = {
    coffeebeans = MakeVegStats(0, TUNING.CALORIES_TINY, 0, TUNING.PERISH_FAST, 0, TUNING.CALORIES_TINY, 0, TUNING.PERISH_SLOW, -TUNING.SANITY_TINY),
}

local function MakeVeggie(name)
    local assets =
    {
        Asset("ANIM", "anim/" .. name .. ".zip"),
    }

    local assets_cooked =
    {
        Asset("ANIM", "anim/" .. name .. ".zip"),
    }

    local prefabs =
    {
        name .. "_cooked",
        "spoiled_food",
    }

    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddNetwork()

        MakeInventoryPhysics(inst)
        MakeInventoryFloatable(inst)
        inst.components.floater:UpdateAnimations("idle_water", "idle")

        inst.AnimState:SetBank(name)
        inst.AnimState:SetBuild(name)
        inst.AnimState:PlayAnimation("idle")

        -- inst.pickupsound = "vegetation_firm"

        --cookable (from cookable component) added to pristine state for optimization
        inst:AddTag("cookable")

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        inst:AddComponent("edible")
        inst.components.edible.healthvalue = PL_VEGGIES[name].health
        inst.components.edible.hungervalue = PL_VEGGIES[name].hunger
        inst.components.edible.sanityvalue = PL_VEGGIES[name].sanity or 0
        inst.components.edible.foodtype = FOODTYPE.VEGGIE
        inst.components.edible.secondaryfoodtype = PL_VEGGIES[name].secondary_foodtype

        inst:AddComponent("perishable")
        inst.components.perishable:SetPerishTime(PL_VEGGIES[name].perishtime)
        inst.components.perishable:StartPerishing()
        inst.components.perishable.onperishreplacement = "spoiled_food"

        inst:AddComponent("stackable")
        inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM

        inst:AddComponent("inspectable")

        inst:AddComponent("inventoryitem")

        inst:AddComponent("bait")

        inst:AddComponent("tradable")

        inst:AddComponent("cookable")
        inst.components.cookable.product = name .. "_cooked"

        MakeSmallBurnable(inst)
        MakeSmallPropagator(inst)
        MakeHauntableLaunchAndPerish(inst)

        return inst
    end

    local function fn_cooked()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddNetwork()

        MakeInventoryPhysics(inst)
        MakeInventoryFloatable(inst)
        inst.components.floater:UpdateAnimations("cooked_water", "idle")

        inst.AnimState:SetBank(name)
        inst.AnimState:SetBuild(name)
        inst.AnimState:PlayAnimation("cooked")

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        inst:AddComponent("perishable")
        inst.components.perishable:SetPerishTime(PL_VEGGIES[name].cooked_perishtime)
        inst.components.perishable:StartPerishing()
        inst.components.perishable.onperishreplacement = "spoiled_food"

        inst:AddComponent("edible")
        inst.components.edible.healthvalue = PL_VEGGIES[name].cooked_health
        inst.components.edible.hungervalue = PL_VEGGIES[name].cooked_hunger
        inst.components.edible.sanityvalue = PL_VEGGIES[name].cooked_sanity or 0
        inst.components.edible.foodtype = FOODTYPE.VEGGIE
        inst.components.edible.secondaryfoodtype = PL_VEGGIES[name].secondary_foodtype

        if name == "coffeebeans" then
            inst.components.edible:SetOnEatenFn(function(inst, eater)
                eater:RemoveDebuff("buff_speed_coffee")
                eater:RemoveDebuff("buff_speed_tea")
                eater:RemoveDebuff("buff_speed_icedtea")
                eater:AddDebuff("buff_speed_coffee_beans", "buff_speed_coffee_beans")
            end)
        end

        inst:AddComponent("stackable")
        inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM

        inst:AddComponent("inspectable")

        inst:AddComponent("inventoryitem")

        inst:AddComponent("bait")

        inst:AddComponent("tradable")

        MakeSmallBurnable(inst)
        MakeSmallPropagator(inst)
        MakeHauntableLaunchAndPerish(inst)

        return inst
    end

    local exported_prefabs = {}

    table.insert(exported_prefabs, Prefab(name, fn, assets, prefabs))
    table.insert(exported_prefabs, Prefab(name.."_cooked", fn_cooked, assets_cooked))

    return exported_prefabs
end

local prefs = {}
for veggiename, veggiedata in pairs(PL_VEGGIES) do
    local veggies = MakeVeggie(veggiename)
    for _, v in ipairs(veggies) do
        table.insert(prefs, v)
    end
end

return unpack(prefs)
