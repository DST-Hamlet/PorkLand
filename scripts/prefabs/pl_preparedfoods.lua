local assets =
{
    Asset("ANIM", "anim/cook_pot_food_2.zip"),
    Asset("ANIM", "anim/cook_pot_food_yotp.zip"),
}

local prefabs =
{
    "spoiled_food",
}

local function MakePreparedFood(data)
    local foodassets = assets
    local spicename = data.spice ~= nil and string.lower(data.spice) or nil
    if spicename ~= nil then
        foodassets = shallowcopy(assets)
        table.insert(foodassets, Asset("ANIM", "anim/spices.zip"))
        table.insert(foodassets, Asset("ANIM", "anim/plate_food.zip"))
        table.insert(foodassets, Asset("INV_IMAGE", spicename.."_over"))
    end

    local foodprefabs = prefabs
    if data.prefabs ~= nil then
        foodprefabs = shallowcopy(prefabs)
        for i, v in ipairs(data.prefabs) do
            if not table.contains(foodprefabs, v) then
                table.insert(foodprefabs, v)
            end
        end
    end

    local function DisplayNameFn(inst)
        return subfmt(STRINGS.NAMES[data.spice.."_FOOD"], { food = STRINGS.NAMES[string.upper(data.basename)] })
    end

    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddNetwork()

        MakeInventoryPhysics(inst)

        if spicename ~= nil then
            inst.AnimState:SetBuild("plate_food")
            inst.AnimState:SetBank("plate_food")
			inst.AnimState:PlayAnimation("idle")
            inst.AnimState:OverrideSymbol("swap_garnish", "spices", spicename)

            inst:AddTag("spicedfood")

            inst.inv_image_bg = { image = (data.basename or data.name)..".tex" }
            inst.inv_image_bg.atlas = GetInventoryItemAtlas(inst.inv_image_bg.image)

            inst.AnimState:OverrideSymbol("swap_food", data.basename or data.name, data.basename or data.name)

			MakeInventoryFloatable(inst)
        else
			inst.AnimState:SetBuild("cook_pot_food")
			inst.AnimState:SetBank("food")
			inst.AnimState:PlayAnimation(data.name, false)

			MakeInventoryFloatable(inst)
			--inst.components.floater:UpdateAnimations(data.name.."_water", data.name)
        end

        inst:AddTag("preparedfood")
        if data.tags then
            for i,v in pairs(data.tags) do
                inst:AddTag(v)
            end
        end

        if data.basename ~= nil then
            inst:SetPrefabNameOverride(data.basename)
            if data.spice ~= nil then
                inst.displaynamefn = DisplayNameFn
            end
        end

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        inst:AddComponent("edible")
        inst.components.edible.healthvalue = data.health
        inst.components.edible.hungervalue = data.hunger
        inst.components.edible.foodtype = data.foodtype or FOODTYPE.GENERIC
        inst.components.edible.sanityvalue = data.sanity or 0
        inst.components.edible.temperaturedelta = data.temperature or 0
        inst.components.edible.temperatureduration = data.temperatureduration or 0
        inst.components.edible.nochill = data.nochill or nil
        inst.components.edible.spice = data.spice
        inst.components.edible:SetOnEatenFn(data.oneatenfn)

        inst.components.edible.naughtyvalue = data.naughtiness or 0
        inst.components.edible.caffeinedelta = data.caffeinedelta or 0
        inst.components.edible.caffeineduration = data.caffeineduration or 0

        if data.boost_surf then
            inst.components.edible.surferdelta = TUNING.HYDRO_FOOD_BONUS_SURF
            inst.components.edible.surferduration = TUNING.FOOD_SPEED_AVERAGE
        end
        if data.boost_dry then
            inst.components.edible.autodrydelta = TUNING.HYDRO_FOOD_BONUS_DRY
            inst.components.edible.autodryduration = TUNING.FOOD_SPEED_AVERAGE
        end
        if data.boost_cool then
            inst.components.edible.autocooldelta = TUNING.HYDRO_FOOD_BONUS_COOL_RATE
        end

        inst:AddComponent("inspectable")
        inst.wet_prefix = data.wet_prefix

		inst:AddComponent("inventoryitem")

		if data.OnPutInInventory then
			inst:ListenForEvent("onputininventory", data.OnPutInInventory)
		end

        if spicename ~= nil then
            inst.components.inventoryitem:ChangeImageName(spicename.."_over")
        elseif data.basename ~= nil then
            inst.components.inventoryitem:ChangeImageName(data.basename)
        end

        inst:AddComponent("stackable")
        inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM

		if data.perishtime ~= nil and data.perishtime > 0 then
			inst:AddComponent("perishable")
			inst.components.perishable:SetPerishTime(data.perishtime)
			inst.components.perishable:StartPerishing()
			inst.components.perishable.onperishreplacement = "spoiled_food"
		end

        MakeSmallBurnable(inst)
        MakeSmallPropagator(inst)
        MakeHauntableLaunchAndPerish(inst)
        -- AddHauntableCustomReaction(inst, function(inst, haunter)
            --#HAUNTFIX
            --if math.random() <= TUNING.HAUNT_CHANCE_SUPERRARE then
                --if inst.components.burnable and not inst.components.burnable:IsBurning() then
                    --inst.components.burnable:Ignite()
                    --inst.components.hauntable.hauntvalue = TUNING.HAUNT_MEDIUM
                    --inst.components.hauntable.cooldown_on_successful_haunt = false
                    --return true
                --end
            --end
            -- return false
        -- end, true, false, true)
        ---------------------

        inst:AddComponent("bait")

        ------------------------------------------------
        inst:AddComponent("tradable")

        ------------------------------------------------

        return inst
    end

    return Prefab(data.name, fn, foodassets, foodprefabs)
end

----------------------------------------------------------------------------------------

local function ApplyGourmetBonus(edible, key)
	if edible and edible[key] then
		if edible[key] < 0 then
			edible[key] = edible[key] * (1 - .33) --TUNING.WARLY_IA_GOURMET_BONUS
		else
			edible[key] = edible[key] * (1 + .33) --TUNING.WARLY_IA_GOURMET_BONUS
		end
	end
end

local function MakeGourmetFood(name)
	local needtocopyassets = true
	if Prefabs[name] ~= nil then --might not be registered yet
		needtocopyassets = nil
	end
    local function fn()
		local inst = Prefabs[name].fn()

		if needtocopyassets then
			Prefabs[name .."_gourmet"].assets = Prefabs[name].assets
			Prefabs[name .."_gourmet"].deps = Prefabs[name].deps
			needtocopyassets = nil
		end

		inst:AddTag("gourmetfood") --this is not pristine anymore, but it should not hurt networking too much

        if not TheWorld.ismastersim then
            return inst
        end

		-- inst.nameoverride = name
		if inst.components.inspectable ~= nil then
			inst.components.inspectable.nameoverride = name
		end
		if inst.components.inventoryitem ~= nil then
			inst.components.inventoryitem.imagename = inst.components.inventoryitem.imagename or name
		end
		if inst.components.perishable ~= nil then
			inst.components.perishable:SetPerishTime( inst.components.perishable.perishtime * .5) --TUNING.WARLY_IA_GOURMET_PERISHTIME_MULT 
		end

		ApplyGourmetBonus(inst.components.edible, "healthvalue")
		ApplyGourmetBonus(inst.components.edible, "hungervalue")
		ApplyGourmetBonus(inst.components.edible, "sanityvalue")
		-- ApplyGourmetBonus(inst.components.edible, "temperaturedelta")
		ApplyGourmetBonus(inst.components.edible, "temperatureduration")
		-- ApplyGourmetBonus(inst.components.edible, "naughtyvalue")
		-- ApplyGourmetBonus(inst.components.edible, "caffeinedelta")
		ApplyGourmetBonus(inst.components.edible, "caffeineduration")
		-- ApplyGourmetBonus(inst.components.edible, "surferdelta")
		ApplyGourmetBonus(inst.components.edible, "surferduration")
		-- ApplyGourmetBonus(inst.components.edible, "autodrydelta")
		ApplyGourmetBonus(inst.components.edible, "autodryduration")
		ApplyGourmetBonus(inst.components.edible, "autocooldelta")

        return inst
    end

    return Prefab(name .."_gourmet", fn, Prefabs[name] and Prefabs[name].assets, Prefabs[name] and Prefabs[name].deps)
end

local prefs = {}

for k,v in pairs(PL_PREPAREDFOODS) do
    table.insert(prefs, MakePreparedFood(v))
end

local cooking = require("cooking")
for cooker, recipes in pairs(cooking.recipes) do
	if cooker ~= "portablespicer" then
		for name, data in pairs(recipes) do
			if name ~= "wetgoop" then --explicitly exclude the failed cooking
				table.insert(prefs, MakeGourmetFood(name))
				--STRINGS.NAMES[string.upper(name) .."_GOURMET"] = STRINGS.GOURMETPREFIX .. (STRINGS.NAMES[string.upper(name)] or STRINGS.GOURMETGENERIC)
			end
		end
	end
end

return unpack(prefs)
