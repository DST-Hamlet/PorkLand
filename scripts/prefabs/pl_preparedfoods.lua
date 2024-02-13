
local prefabs =
{
    "spoiled_food",
}

local function MakePreparedFood(data)
	local foodassets =
	{
		Asset("ANIM", "anim/cook_pot_food2.zip"),
	}

    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddNetwork()

        MakeInventoryPhysics(inst)
        MakeInventoryFloatable(inst)
        inst.components.floater:UpdateAnimations("idle_water", "idle")

		inst.AnimState:SetBuild("cook_pot_food")
		inst.AnimState:SetBank("food")
        inst.AnimState:PlayAnimation(data.name, false)

        inst:AddTag("preparedfood")

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        inst:AddComponent("edible")
        inst.components.edible.healthvalue = data.health
        inst.components.edible.hungervalue = data.hunger
        inst.components.edible.foodtype = data.foodtype or FOODTYPE.GENERIC
        inst.components.edible.secondaryfoodtype = data.secondaryfoodtype or nil
        inst.components.edible.sanityvalue = data.sanity or 0
        inst.components.edible.temperaturedelta = data.temperature or 0
        inst.components.edible.temperatureduration = data.temperatureduration or 0
        inst.components.edible.nochill = data.nochill or nil
        inst.components.edible:SetOnEatenFn(data.oneatenfn)

        -- TODO insta temperature change
        inst.components.edible.caffeinedelta = data.caffeinedelta or 0
		inst.components.edible.caffeineduration = data.caffeineduration or 0
        inst.components.edible.antihistamine = data.antihistamine or 0

        inst.yotp_override = data.yotp
        --[[ TODO: Add fiesta stuff	
        local function setfiesta(active)
			if active then
				inst.AnimState:AddOverrideBuild("cook_pot_food_yotp")
				inst.components.inventoryitem:ChangeImageName(data.name .. "_yotp")
			else
				inst.AnimState:ClearOverrideBuild("cook_pot_food_yotp")
				inst.components.inventoryitem:ChangeImageName(data.name)
			end
		end

		if inst.yotp_override then
			inst:ListenForEvent("beginfiesta", function() setfiesta(true) end, GetWorld())
			inst:ListenForEvent("endfiesta", function() setfiesta(false) end, GetWorld())

			if GetAporkalypse() and GetAporkalypse():GetFiestaActive() then
				setfiesta(true)
			end
		end]]

        inst:AddComponent("inspectable")
        inst.wet_prefix = data.wet_prefix

        inst:AddComponent("inventoryitem")

        inst:AddComponent("stackable")
        inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM

        if data.perishtime ~= nil and data.perishtime > 0 then
            inst:AddComponent("perishable")
            inst.components.perishable:SetPerishTime(data.perishtime)
            inst.components.perishable:StartPerishing()
            inst.components.perishable.onperishreplacement = data.spoiled_product or "spoiled_food"
        end


        inst:AddComponent("bait")

        inst:AddComponent("tradable")

        MakeSmallBurnable(inst)
        MakeSmallPropagator(inst)
        MakeHauntableLaunchAndPerish(inst)

        return inst
    end

    return Prefab(data.name, fn, foodassets, prefabs)
end

local prefs = {}

for k, v in pairs(require("main/preparedfoods")) do
    table.insert(prefs, MakePreparedFood(v))
end

return unpack(prefs)
