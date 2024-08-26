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

local COMMON = 3
-- local UNCOMMON = 1
-- local RARE = .5

local SEEDLESS =
{
    coffeebeans = true,
}

local assets_seeds =
{
    Asset("ANIM", "anim/seeds.zip"),
    Asset("ANIM", "anim/pl_farm_plant_seeds.zip"),
}

PL_VEGGIES = {
    coffeebeans = MakeVegStats(0, TUNING.CALORIES_TINY, 0, TUNING.PERISH_FAST, 0, TUNING.CALORIES_TINY, 0, TUNING.PERISH_SLOW, -TUNING.SANITY_TINY),
    radish = MakeVegStats(COMMON, TUNING.CALORIES_SMALL, TUNING.HEALING_TINY, TUNING.PERISH_SLOW, 0, TUNING.CALORIES_SMALL, TUNING.HEALING_SMALL, TUNING.PERISH_MED, 0),
    aloe = MakeVegStats(COMMON, TUNING.CALORIES_TINY, TUNING.HEALING_MEDSMALL, TUNING.PERISH_FAST, 0, TUNING.CALORIES_SMALL, TUNING.HEALING_SMALL, TUNING.PERISH_SUPERFAST, 0),
}
for veggie in pairs(PL_VEGGIES) do
    VEGGIES[veggie] = PL_VEGGIES[veggie]
end

local function can_plant_seed(inst, pt, mouseover, deployer)
    local x, z = pt.x, pt.z
    return TheWorld.Map:CanTillSoilAtPoint(x, 0, z, true)
end

local function OnDeploy(inst, pt, deployer) --, rot)
    local plant = SpawnPrefab("plant_normal_ground")
    plant.components.crop:StartGrowing(inst.components.plantable.product, inst.components.plantable.growtime)
    plant.Transform:SetPosition(pt.x, 0, pt.z)
    plant.SoundEmitter:PlaySound("dontstarve/wilson/plant_seeds")
    inst:Remove()
end

local function MakeVeggie(name, has_seeds)
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

    if has_seeds then
        table.insert(prefabs, name .. "_seeds")
    end

    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddNetwork()

        MakeInventoryPhysics(inst)
        PorkLandMakeInventoryFloatable(inst)

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
        PorkLandMakeInventoryFloatable(inst, "cooked_water", "idle")

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

    local function fn_seeds()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddNetwork()

        MakeInventoryPhysics(inst)

        inst.AnimState:SetBank("pl_farm_plant_seeds")
        inst.AnimState:SetBuild("pl_farm_plant_seeds")
        inst.AnimState:PlayAnimation(name)
        inst.AnimState:SetRayTestOnBB(true)

        -- inst.pickupsound = "vegetation_firm"

        --cookable (from cookable component) added to pristine state for optimization
        inst:AddTag("cookable")
        inst:AddTag("deployedplant")
        inst:AddTag("deployedfarmplant")
        inst:AddTag("oceanfishing_lure")

        inst.overridedeployplacername = "seeds_placer"

        inst._custom_candeploy_fn = can_plant_seed -- for DEPLOYMODE.CUSTOM

        MakeInventoryFloatable(inst)

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        inst:AddComponent("edible")
        inst.components.edible.foodtype = FOODTYPE.SEEDS

        inst:AddComponent("stackable")
        inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM

        inst:AddComponent("tradable")

        inst:AddComponent("inspectable")

        inst:AddComponent("inventoryitem")

        inst.components.edible.healthvalue = TUNING.HEALING_TINY / 2
        inst.components.edible.hungervalue = TUNING.CALORIES_TINY

        inst:AddComponent("perishable")
        inst.components.perishable:SetPerishTime(TUNING.PERISH_SUPERSLOW)
        inst.components.perishable:StartPerishing()
        inst.components.perishable.onperishreplacement = "spoiled_food"

        inst:AddComponent("cookable")
        inst.components.cookable.product = "seeds_cooked"

        inst:AddComponent("bait")

        inst:AddComponent("plantable")
        inst.components.plantable.growtime = TUNING.SEEDS_GROW_TIME
        inst.components.plantable.product = name

        inst:AddComponent("deployable")
        inst.components.deployable:SetDeployMode(DEPLOYMODE.CUSTOM) -- use inst._custom_candeploy_fn
        inst.components.deployable.restrictedtag = "plantkin"
        inst.components.deployable.ondeploy = OnDeploy

        MakeSmallBurnable(inst)
        MakeSmallPropagator(inst)

        MakeHauntableLaunchAndPerish(inst)

        return inst
    end

    local exported_prefabs = {}

    table.insert(exported_prefabs, Prefab(name, fn, assets, prefabs))
    table.insert(exported_prefabs, Prefab(name .. "_cooked", fn_cooked, assets_cooked))

    if has_seeds then
        table.insert(exported_prefabs, Prefab(name .. "_seeds", fn_seeds, assets_seeds))
    end

    return exported_prefabs
end

local prefs = {}
for veggiename, veggiedata in pairs(PL_VEGGIES) do
    local veggies = MakeVeggie(veggiename, not SEEDLESS[veggiename])
    for _, v in ipairs(veggies) do
        table.insert(prefs, v)
    end
end

return unpack(prefs)
