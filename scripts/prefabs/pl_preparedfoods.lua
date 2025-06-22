local prefabs =
{
    "spoiled_food",
}

local function OnFiestaChange(inst, active)
    if active then
        inst.AnimState:AddOverrideBuild("cook_pot_food_yotp")
        inst.components.inventoryitem:ChangeImageName(inst.prefab .. "_yotp")
    else
        inst.AnimState:ClearOverrideBuild("cook_pot_food_yotp")
        inst.components.inventoryitem:ChangeImageName(inst.prefab)
    end
end

local function MakePreparedFood(data)
    local foodassets =
    {
        Asset("ANIM", "anim/pl_cook_pot_food.zip"),
		Asset("ANIM", "anim/cook_pot_food_yotp.zip"),
    }

    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddNetwork()

        MakeInventoryPhysics(inst)
        PorkLandMakeInventoryFloatable(inst, data.name .. "_water", data.name)

        inst.AnimState:SetBuild("pl_cook_pot_food")
        inst.AnimState:SetBank(data.is_shipwreck_food and "sw_food" or "pl_food")
        inst.AnimState:PlayAnimation(data.name, false)

        inst:AddTag("preparedfood")
        inst.wet_prefix = data.wet_prefix

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
        inst.components.edible.antihistamine = data.antihistamine or 0
        inst.components.edible:SetOnEatenFn(data.oneatenfn)

        inst:AddComponent("inspectable")

        inst:AddComponent("inventoryitem")

        inst:AddComponent("stackable")
        inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM

        if data.perishtime and data.perishtime > 0 then
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

        inst.yotp_override = data.yotp
        if inst.yotp_override then
            inst:SetPrefabName(data.name) -- For inst.prefab used in OnFiestaChange
            inst.OnFiestaChange = function(src, isfiesta) OnFiestaChange(inst, isfiesta) end
            inst:WatchWorldState("fiestachange", inst.OnFiestaChange)
            OnFiestaChange(inst, TheWorld.state.isfiesta)
        end

        return inst
    end

    return Prefab(data.name, fn, foodassets, prefabs)
end

local prefs = {}

for k, v in pairs(require("main/preparedfoods")) do
    table.insert(prefs, MakePreparedFood(v))
end

return unpack(prefs)
