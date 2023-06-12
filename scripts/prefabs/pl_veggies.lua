local PLANT_DEFS = require("prefabs/farm_plant_defs").PLANT_DEFS

local function MakeVegStats(seedweight, hunger, health, perish_time, sanity, cooked_hunger, cooked_health, cooked_perish_time, cooked_sanity, float_settings, cooked_float_settings, dryable, secondary_foodtype, halloweenmoonmutable_settings, lure_data)
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
        float_settings = float_settings,
        cooked_float_settings = cooked_float_settings,
        dryable = dryable,
        halloweenmoonmutable_settings = halloweenmoonmutable_settings,
        secondary_foodtype = secondary_foodtype,
        lure_data = lure_data,
    }
end

local COMMON = TUNING.SEED_CHANCE_COMMON
local UNCOMMON = TUNING.SEED_CHANCE_UNCOMMON
local RARE = TUNING.SEED_CHANCE_RARE

local OVERSIZED_PHYSICS_RADIUS = 0.1
local OVERSIZED_MAXWORK = 1
local OVERSIZED_PERISHTIME_MULT = 4

local QUAGMIRE_PORTS = {
    "tomato",
    "onion",
}

PL_VEGGIES = {
    aloe = MakeVegStats(COMMON, TUNING.CALORIES_TINY, TUNING.HEALING_MEDSMALL, TUNING.PERISH_FAST, 0, 
								TUNING.CALORIES_SMALL, TUNING.HEALING_SMALL, TUNING.PERISH_SUPERFAST, 0),
    radish = MakeVegStats(COMMON, TUNING.CALORIES_SMALL, TUNING.HEALING_TINY, TUNING.PERISH_SLOW, 0, 
								TUNING.CALORIES_SMALL, TUNING.HEALING_SMALL, TUNING.PERISH_MED, 0)
}

local SEEDLESS = {
	berries = true,
	cave_banana = true,
	cactus_meat = true,
	berries_juicy = true,
	fig = true,
	kelp = true,
	
	aloe = true,
	radish = true,
}
local assets_seeds = {
    Asset("ANIM", "anim/seeds.zip"),
}

local function can_plant_seed(inst, pt, mouseover, deployer)
	local x, z = pt.x, pt.z
	return TheWorld.Map:CanTillSoilAtPoint(x, 0, z, true)
end

local function OnDeploy(inst, pt, deployer) --, rot)
    local plant = SpawnPrefab(inst.components.farmplantable.plant)
    plant.Transform:SetPosition(pt.x, 0, pt.z)
	plant:PushEvent("on_planted", {in_soil = false, doer = deployer, seed = inst})
    TheWorld.Map:CollapseSoilAtPoint(pt.x, 0, pt.z)
    inst:Remove()
end

local function oversized_calcweightcoefficient(name)
    if PLANT_DEFS[name].weight_data[3] ~= nil and math.random() < PLANT_DEFS[name].weight_data[3] then
        return (math.random() + math.random()) / 2
    else
        return math.random()
    end
end

local function oversized_onequip(inst, owner)
    if PLANT_DEFS[inst._base_name].build ~= nil then
        owner.AnimState:OverrideSymbol("swap_body", PLANT_DEFS[inst._base_name].build, "swap_body")
    else
        owner.AnimState:OverrideSymbol("swap_body", "farm_plant_" .. inst._base_name, "swap_body")
    end
end

local function oversized_onequip(inst, owner)
	local swap = inst.components.symbolswapdata
    owner.AnimState:OverrideSymbol("swap_body", swap.build, swap.symbol)
end

local function oversized_onunequip(inst, owner)
    owner.AnimState:ClearOverrideSymbol("swap_body")
end

local function oversized_onfinishwork(inst, chopper)
    inst.components.lootdropper:DropLoot()
    inst:Remove()
end

local function oversized_onburnt(inst)
    inst.components.lootdropper:DropLoot()
    inst:Remove()
end

local function oversized_makeloots(inst, name)
    local product = name
	local seeds = name .. "_seeds"
    return {product, product, seeds, seeds, math.random() < 0.75 and product or seeds}
end

local function oversized_onperish(inst)
    -- vars for rotting on a gym
    local gym = nil
    local rot = nil
    local slot = nil

    if inst.components.inventoryitem:GetGrandOwner() ~= nil and not inst.components.inventoryitem:GetGrandOwner():HasTag("gym") then
        local loots = {}
        for i = 1, #inst.components.lootdropper.loot do
            table.insert(loots, "spoiled_food")
        end
        inst.components.lootdropper:SetLoot(loots)
        inst.components.lootdropper:DropLoot()
    else
        rot = SpawnPrefab(inst.prefab .. "_rotten")
        rot.Transform:SetPosition(inst.Transform:GetWorldPosition())
        if inst.components.inventoryitem:GetGrandOwner() and inst.components.inventoryitem:GetGrandOwner():HasTag("gym") then
            gym = inst.components.inventoryitem:GetGrandOwner()
            slot = gym.components.inventory:GetItemSlot(inst)
        end
    end

    inst:Remove()

    if gym and rot then
        gym.components.mightygym:LoadWeight(rot, slot)
    end
end

local function Seed_GetDisplayName(inst)
    local registry_key = inst.plant_def.product

    local plantregistryinfo = inst.plant_def.plantregistryinfo
    return (ThePlantRegistry:KnowsSeed(registry_key, plantregistryinfo) and ThePlantRegistry:KnowsPlantName(registry_key, plantregistryinfo)) and STRINGS.NAMES["KNOWN_" .. string.upper(inst.prefab)]
            or nil
end

local function Oversized_OnSave(inst, data)
    data.from_plant = inst.from_plant
    data.harvested_on_day = inst.harvested_on_day
end

local function Oversized_OnPreLoad(inst, data)
    inst.from_plant = (data and data.from_plant) ~= false
	if data ~= nil then
        inst.harvested_on_day = data.harvested_on_day
	end
end

local function displayadjectivefn(inst)
    return STRINGS.UI.HUD.WAXED
end

local function dowaxfn(inst, doer, waxitem)
    local waxedveggie = SpawnPrefab(inst.prefab .. "_waxed")
    if doer.components.inventory and doer.components.inventory:IsHeavyLifting() and doer.components.inventory:GetEquippedItem(EQUIPSLOTS.BODY) == inst then
        doer.components.inventory:Unequip(EQUIPSLOTS.BODY)
        doer.components.inventory:Equip(waxedveggie)
    else
        waxedveggie.Transform:SetPosition(inst.Transform:GetWorldPosition())
        waxedveggie.AnimState:PlayAnimation("wax_oversized", false)
        waxedveggie.AnimState:PushAnimation("idle_oversized")
    end
    inst:Remove()
    return true
end

local function PlayWaxAnimation(inst)
    -- inst.AnimState:PlayAnimation("wax_oversized", false)
    -- inst.AnimState:PushAnimation("crop_oversized")
end

local function CancelWaxTask(inst)
	if inst._waxtask ~= nil then
		inst._waxtask:Cancel()
		inst._waxtask = nil
	end
end

local function StartWaxTask(inst)
	if not inst.inlimbo and inst._waxtask == nil then
		inst._waxtask = inst:DoTaskInTime(GetRandomMinMax(20, 40), PlayWaxAnimation)
	end
end

local function MakeVeggie(name, has_seeds)
    local assets = {
        Asset("ANIM", "anim/seeds.zip"),
        Asset("ANIM", "anim/" .. name .. ".zip"),
       -- Asset("ANIM", "anim/farm_plant_aloe.zip"),
       -- Asset("ANIM", "anim/farm_plant_radish.zip"),
    }

    if PL_VEGGIES[name].lure_data ~= nil then
        table.insert(assets, Asset("ANIM", "anim/" .. PL_VEGGIES[name].lure_data.build .. ".zip"))
    end

    if has_seeds then
        table.insert(assets, Asset("ANIM", "anim/oceanfishing_lure_mis.zip"))
    end

    local assets_cooked = {
        Asset("ANIM", "anim/" .. name .. ".zip"),
        Asset("INV_IMAGE", name.."_cooked"),
    }

    local usequagmireicon = table.contains(QUAGMIRE_PORTS, name)
    if usequagmireicon then
        table.insert(assets, Asset("INV_IMAGE", "quagmire_" .. name))
        table.insert(assets_cooked, Asset("INV_IMAGE", "quagmire_" .. name .. "_cooked"))
    end

    local prefabs = {
        name .. "_cooked",
        "spoiled_food",
    }

    local dryable = PL_VEGGIES[name].dryable

    if has_seeds then
        table.insert(prefabs, name .. "_seeds")
    end

    local assets_dried = {}
	if dryable ~= nil then
        table.insert(prefabs, name .. "_dried")
        table.insert(assets_dried, Asset("ANIM", "anim/" .. dryable.build .. ".zip"))
	end

    local seeds_prefabs = has_seeds and { "farm_plant_" .. name } or nil

    local assets_oversized = {}
    if has_seeds then
        table.insert(prefabs, name .. "_oversized")
        table.insert(prefabs, name .. "_oversized_waxed")
        table.insert(prefabs, name .. "_oversized_rotten")
        table.insert(prefabs, "splash_green")

        table.insert(assets_oversized, Asset("ANIM", "anim/" .. PLANT_DEFS[name].build .. ".zip"))
    end

    local function fn_seeds()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddNetwork()

        MakeInventoryPhysics(inst)

        inst.AnimState:SetBank("ia_farm_plant_seeds")
        inst.AnimState:SetBuild("ia_farm_plant_seeds")
        inst.AnimState:PlayAnimation(name)
        inst.AnimState:SetRayTestOnBB(true)

        --cookable (from cookable component) added to pristine state for optimization
        inst:AddTag("cookable")
        inst:AddTag("deployedplant")
        inst:AddTag("deployedfarmplant")
		inst:AddTag("oceanfishing_lure")

        inst.overridedeployplacername = "seeds_placer"

		inst.plant_def = PLANT_DEFS[name]
		inst.displaynamefn = Seed_GetDisplayName

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

	    inst:AddComponent("farmplantable")
	    inst.components.farmplantable.plant = "farm_plant_" .. name

         -- deprecated (used for crafted farm structures)
        inst:AddComponent("plantable")
        inst.components.plantable.growtime = TUNING.SEEDS_GROW_TIME
        inst.components.plantable.product = name

         -- deprecated (used for wormwood)
        inst:AddComponent("deployable")
        inst.components.deployable:SetDeployMode(DEPLOYMODE.CUSTOM) -- use inst._custom_candeploy_fn
        inst.components.deployable.restrictedtag = "plantkin"
        inst.components.deployable.ondeploy = OnDeploy

		inst:AddComponent("oceanfishingtackle")
        inst.components.oceanfishingtackle:SetupLure({build = "oceanfishing_lure_mis", symbol = "hook_seeds", single_use = true, lure_data = TUNING.OCEANFISHING_LURE.SEED})

        MakeSmallBurnable(inst)
        MakeSmallPropagator(inst)

        MakeHauntableLaunchAndPerish(inst)

        return inst
    end

    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddNetwork()

        MakeInventoryPhysics(inst)

        inst.AnimState:SetBank(name)
        inst.AnimState:SetBuild(name)
        inst.AnimState:PlayAnimation("idle")

        --cookable (from cookable component) added to pristine state for optimization
        inst:AddTag("cookable")

		if dryable ~= nil then
			--dryable (from dryable component) added to pristine state for optimization
			inst:AddTag("dryable")
        end

        if not SEEDLESS[name] then
            --weighable (from weighable component) added to pristine state for optimization
            inst:AddTag("weighable_OVERSIZEDVEGGIES")
        end

        local float = PL_VEGGIES[name].float_settings
        if float ~= nil then
            MakeInventoryFloatable(inst, float[1], float[2], float[3])
        else
            MakeInventoryFloatable(inst)
        end

		if PL_VEGGIES[name].lure_data ~= nil then
			inst:AddTag("oceanfishing_lure")
		end

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
        if name ~= "pumpkin" and
            name ~= "eggplant" and
            name ~= "durian" and
            name ~= "watermelon" then
            inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM
        end

        if name == "watermelon" then
            inst.components.edible.temperaturedelta = TUNING.COLD_FOOD_BONUS_TEMP
            inst.components.edible.temperatureduration = TUNING.FOOD_TEMP_BRIEF
        end

		if dryable ~= nil then
			inst:AddComponent("dryable")
			inst.components.dryable:SetProduct(name .. "_dried")
			inst.components.dryable:SetBuildFile(dryable.build)
			inst.components.dryable:SetDryTime(dryable.time)
		end

        inst:AddComponent("inspectable")
        inst:AddComponent("inventoryitem")
        if usequagmireicon then
            inst.components.inventoryitem:ChangeImageName("quagmire_" .. name)
        end

        -- Regular veggies are weighable but don't have a weight. They all show the same
        -- result when put in a trophyscale_oversizedveggies, and always replace other
        -- regular veggies when attempting to do so.
        if not SEEDLESS[name] then
            inst:AddComponent("weighable")
            inst.components.weighable.type = TROPHYSCALE_TYPES.OVERSIZEDVEGGIES
        end

        MakeSmallBurnable(inst)
        MakeSmallPropagator(inst)
        ---------------------

        inst:AddComponent("bait")

        ------------------------------------------------
        inst:AddComponent("tradable")

        ------------------------------------------------

        inst:AddComponent("cookable")
        inst.components.cookable.product = name .. "_cooked"

		if PL_VEGGIES[name].lure_data ~= nil then
			inst:AddComponent("oceanfishingtackle")
			inst.components.oceanfishingtackle:SetupLure(PL_VEGGIES[name].lure_data)
		end

		local halloweenmoonmutable_settings = PL_VEGGIES[name].halloweenmoonmutable_settings
		if halloweenmoonmutable_settings ~= nil then
			inst:AddComponent("halloweenmoonmutable")
			inst.components.halloweenmoonmutable:SetPrefabMutated(halloweenmoonmutable_settings.prefab)
			inst.components.halloweenmoonmutable:SetOnMutateFn(halloweenmoonmutable_settings.onmutatefn)
		end

        if TheNet:GetServerGameMode() == "quagmire" then
            event_server_data("quagmire", "prefabs/veggies").master_postinit(inst)
        end

        MakeHauntableLaunchAndPerish(inst)

        return inst
    end

    local function fn_cooked()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddNetwork()

        MakeInventoryPhysics(inst)

        inst.AnimState:SetBank(name)
        inst.AnimState:SetBuild(name)
        inst.AnimState:PlayAnimation("cooked")

        local float = PL_VEGGIES[name].cooked_float_settings
        if float ~= nil then
            MakeInventoryFloatable(inst, float[1], float[2], float[3])
        else
            MakeInventoryFloatable(inst)
        end

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

        inst:AddComponent("stackable")
        inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM

        inst:AddComponent("inspectable")

		inst:AddComponent("inventoryitem")
		inst.components.inventoryitem.imagename = name .. "_cooked"

        if usequagmireicon then
            inst.components.inventoryitem:ChangeImageName("quagmire_" .. name .. "_cooked")
        end

        MakeSmallBurnable(inst)
        MakeSmallPropagator(inst)
        ---------------------

        inst:AddComponent("bait")

        ------------------------------------------------
        inst:AddComponent("tradable")

        if TheNet:GetServerGameMode() == "quagmire" then
            event_server_data("quagmire", "prefabs/veggies").master_postinit_cooked(inst)
        end

        MakeHauntableLaunchAndPerish(inst)

        return inst
    end

    local function fn_dried()
        local inst = CreateEntity()

		inst.entity:AddTransform()
		inst.entity:AddAnimState()
        inst.entity:AddNetwork()

        MakeInventoryPhysics(inst)

        inst.AnimState:SetBank(dryable.build)
        inst.AnimState:SetBuild(dryable.build)
        inst.AnimState:PlayAnimation("dried_" .. name)

        MakeInventoryFloatable(inst)

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end
        inst:AddComponent("perishable")
        inst.components.perishable:SetPerishTime(dryable.perish)
        inst.components.perishable:StartPerishing()
        inst.components.perishable.onperishreplacement = "spoiled_food"

        inst:AddComponent("edible")
        inst.components.edible.healthvalue = dryable.health or 0
        inst.components.edible.hungervalue = dryable.hunger or 0
        inst.components.edible.sanityvalue = dryable.sanity or 0
        inst.components.edible.foodtype = FOODTYPE.VEGGIE

        inst:AddComponent("stackable")
        inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM

        inst:AddComponent("inspectable")
        inst:AddComponent("inventoryitem")

        MakeSmallBurnable(inst)
        MakeSmallPropagator(inst)

        inst:AddComponent("bait")

        inst:AddComponent("tradable")

        MakeHauntableLaunchAndPerish(inst)

        return inst
    end

    local function fn_oversized()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddNetwork()

        local plant_def = PLANT_DEFS[name]

        inst.AnimState:SetBank(plant_def.bank)
        inst.AnimState:SetBuild(plant_def.build)
        inst.AnimState:PlayAnimation("idle_oversized")

        inst:AddTag("heavy")
        inst:AddTag("waxable")
        inst:AddTag("show_spoilage")
        inst:AddTag("weighable_OVERSIZEDVEGGIES")
        MakeHeavyObstaclePhysics(inst, OVERSIZED_PHYSICS_RADIUS)
        inst:SetPhysicsRadiusOverride(OVERSIZED_PHYSICS_RADIUS)
        inst.gymweight = 4
        
        inst._base_name = name

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        inst.harvested_on_day = inst.harvested_on_day or (TheWorld.state.cycles + 1)

        inst:AddComponent("heavyobstaclephysics")
        inst.components.heavyobstaclephysics:SetRadius(OVERSIZED_PHYSICS_RADIUS)
        inst.components.heavyobstaclephysics:MakeSmallObstacle()

        inst:AddComponent("perishable")
        inst.components.perishable:SetPerishTime(PL_VEGGIES[name].perishtime * OVERSIZED_PERISHTIME_MULT)
        inst.components.perishable:StartPerishing()
        inst.components.perishable.onperishreplacement = nil
        inst.components.perishable:SetOnPerishFn(oversized_onperish)

        inst:AddComponent("inspectable")
        inst:AddComponent("inventoryitem")
        inst.components.inventoryitem.cangoincontainer = false
        inst.components.inventoryitem:SetSinks(true)

        inst:AddComponent("equippable")
        inst.components.equippable.equipslot = EQUIPSLOTS.BODY
        inst.components.equippable:SetOnEquip(oversized_onequip)
        inst.components.equippable:SetOnUnequip(oversized_onunequip)
        inst.components.equippable.walkspeedmult = TUNING.HEAVY_SPEED_MULT

        inst:AddComponent("workable")
        inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
        inst.components.workable:SetOnFinishCallback(oversized_onfinishwork)
        inst.components.workable:SetWorkLeft(OVERSIZED_MAXWORK)

        inst:AddComponent("waxable")
        inst.components.waxable:SetWaxfn(dowaxfn)

        inst:AddComponent("submersible")
        inst:AddComponent("symbolswapdata")
        inst.components.symbolswapdata:SetData(plant_def.build, "swap_body")

        local weight_data = plant_def.weight_data
        inst:AddComponent("weighable")
        inst.components.weighable.type = TROPHYSCALE_TYPES.OVERSIZEDMYVEGGIES
        inst.components.weighable:Initialize(weight_data.min, weight_data.max)
        local coefficient = oversized_calcweightcoefficient(name)
        inst.components.weighable:SetWeight(Lerp(weight_data[1], weight_data[2], coefficient))

        inst:AddComponent("lootdropper")
        inst.components.lootdropper:SetLoot(oversized_makeloots(inst, name))

        MakeMediumBurnable(inst)
        inst.components.burnable:SetOnBurntFn(oversized_onburnt)
        MakeMediumPropagator(inst)

        MakeHauntableWork(inst)

        inst.from_plant = false

        inst.OnSave = Oversized_OnSave
        inst.OnPreLoad = Oversized_OnPreLoad

        return inst
    end

    local function fn_oversized_waxed()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddNetwork()

        local plant_def = PLANT_DEFS[name]

        inst.AnimState:SetBank(plant_def.bank)
        inst.AnimState:SetBuild(plant_def.build)
        inst.AnimState:PlayAnimation("idle_oversized")

        inst:AddTag("heavy")
        inst.gymweight = 4

        inst.displayadjectivefn = displayadjectivefn
        inst:SetPrefabNameOverride(name .. "_oversized")

        MakeHeavyObstaclePhysics(inst, OVERSIZED_PHYSICS_RADIUS)
        inst:SetPhysicsRadiusOverride(OVERSIZED_PHYSICS_RADIUS)

        inst._base_name = name

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        inst:AddComponent("heavyobstaclephysics")
        inst.components.heavyobstaclephysics:SetRadius(OVERSIZED_PHYSICS_RADIUS)
        inst.components.heavyobstaclephysics:MakeSmallObstacle()

        inst:AddComponent("inspectable")
        inst:AddComponent("inventoryitem")
        inst.components.inventoryitem.cangoincontainer = false
        inst.components.inventoryitem:SetSinks(true)

        inst:AddComponent("equippable")
        inst.components.equippable.equipslot = EQUIPSLOTS.BODY
        inst.components.equippable:SetOnEquip(oversized_onequip)
        inst.components.equippable:SetOnUnequip(oversized_onunequip)
        inst.components.equippable.walkspeedmult = TUNING.HEAVY_SPEED_MULT

        inst:AddComponent("workable")
        inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
        inst.components.workable:SetOnFinishCallback(oversized_onfinishwork)
        inst.components.workable:SetWorkLeft(OVERSIZED_MAXWORK)

        inst:AddComponent("submersible")
        inst:AddComponent("symbolswapdata")
        inst.components.symbolswapdata:SetData(plant_def.build, "swap_body")

        inst:AddComponent("lootdropper")
        inst.components.lootdropper:SetLoot({"spoiled_food"})

        MakeMediumBurnable(inst)
        inst.components.burnable:SetOnBurntFn(oversized_onburnt)
        MakeMediumPropagator(inst)

        MakeHauntableWork(inst)

        -- inst:ListenForEvent("onputininventory", CancelWaxTask)
        -- inst:ListenForEvent("ondropped", StartWaxTask)

        -- inst.OnEntitySleep = CancelWaxTask
        -- inst.OnEntityWake = StartWaxTask

        -- StartWaxTask(inst)

        return inst
    end

    local function fn_oversized_rotten()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddNetwork()

        local plant_def = PLANT_DEFS[name]

        inst.AnimState:SetBank(plant_def.bank)
        inst.AnimState:SetBuild(plant_def.build)
        inst.AnimState:PlayAnimation("idle_rot_oversized")

        inst:AddTag("heavy")
        inst:AddTag("farm_plant_killjoy")
        inst:AddTag("pickable_harvest_str")
		inst:AddTag("pickable")
        inst:AddTag("oversized_veggie")
        inst.gymweight = 3

        MakeHeavyObstaclePhysics(inst, OVERSIZED_PHYSICS_RADIUS)
        inst:SetPhysicsRadiusOverride(OVERSIZED_PHYSICS_RADIUS)

		inst._base_name = name

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        inst:AddComponent("heavyobstaclephysics")
        inst.components.heavyobstaclephysics:SetRadius(OVERSIZED_PHYSICS_RADIUS)

        inst:AddComponent("inspectable")
		inst.components.inspectable.nameoverride = "VEGGIE_OVERSIZED_ROTTEN"

        inst:AddComponent("workable")
        inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
        inst.components.workable:SetOnFinishCallback(oversized_onfinishwork)
        inst.components.workable:SetWorkLeft(OVERSIZED_MAXWORK)

        inst:AddComponent("pickable")
		inst.components.pickable.remove_when_picked = true
	    inst.components.pickable:SetUp(nil)
		inst.components.pickable.use_lootdropper_for_product = true
	    inst.components.pickable.picksound = "dontstarve/wilson/harvest_berries"

        inst:AddComponent("inventoryitem")
        inst.components.inventoryitem.cangoincontainer = false
		--inst.components.inventoryitem.canbepickedup = false
        inst.components.inventoryitem:SetSinks(true)

        inst:AddComponent("equippable")
        inst.components.equippable.equipslot = EQUIPSLOTS.BODY
        inst.components.equippable:SetOnEquip(oversized_onequip)
        inst.components.equippable:SetOnUnequip(oversized_onunequip)
        inst.components.equippable.walkspeedmult = TUNING.HEAVY_SPEED_MULT

        inst:AddComponent("submersible")
        inst:AddComponent("symbolswapdata")
        inst.components.symbolswapdata:SetData(plant_def.build, "swap_body_rotten")

        inst:AddComponent("lootdropper")
        inst.components.lootdropper:SetLoot(plant_def.loot_oversized_rot)

        inst.components.inventoryitem:ChangeImageName(name .. "_oversized_rot")

        MakeMediumBurnable(inst)
        inst.components.burnable:SetOnBurntFn(oversized_onburnt)
        MakeMediumPropagator(inst)

        MakeHauntableWork(inst)

        return inst
    end


    local exported_prefabs = {}

    if has_seeds then
        table.insert(exported_prefabs, Prefab(name .. "_seeds", fn_seeds, assets_seeds, seeds_prefabs))
        table.insert(exported_prefabs, Prefab(name .. "_oversized", fn_oversized, assets_oversized))
        table.insert(exported_prefabs, Prefab(name .. "_oversized_waxed", fn_oversized_waxed, assets_oversized))
        table.insert(exported_prefabs, Prefab(name .. "_oversized_rotten", fn_oversized_rotten, assets_oversized))
    end
    if dryable ~= nil then
		table.insert(exported_prefabs, Prefab(name .. "_dried", fn_dried, assets_dried))
    end

    table.insert(exported_prefabs, Prefab(name, fn, assets, prefabs))
    table.insert(exported_prefabs, Prefab(name .. "_cooked", fn_cooked, assets_cooked))

    return exported_prefabs
    -- local base = Prefab(name, fn, assets, prefabs)
    -- local cooked = Prefab(name .. "_cooked", fn_cooked, assets_cooked)
    -- local seeds = has_seeds and Prefab(name .. "_seeds", fn_seeds, assets_seeds) or nil

    -- return base, cooked, seeds
end


local prefs = {}
for veggiename, veggiedata in pairs(PL_VEGGIES) do
    local veggies = MakeVeggie(veggiename, not SEEDLESS[veggiename])
    for _, v in ipairs(veggies) do
        table.insert(prefs, v)
    end
end

return unpack(prefs)
