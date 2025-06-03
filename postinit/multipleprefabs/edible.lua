local AddPrefabPostInit = AddPrefabPostInit
GLOBAL.setfenv(1, GLOBAL)

local wood_foods = {
    ["dug_berrybush"] = {foodtype = FOODTYPE.ROUGHAGE},
    ["dug_berrybush2"] = {foodtype = FOODTYPE.ROUGHAGE},
    ["dug_berrybush_juicy"] = {foodtype = FOODTYPE.ROUGHAGE},
    ["dug_sapling"] = {foodtype = FOODTYPE.ROUGHAGE},
    ["dug_sapling_moon"] = {foodtype = FOODTYPE.ROUGHAGE},
    ["dug_grass"] = {foodtype = FOODTYPE.ROUGHAGE},
    ["dug_marsh_bush"] = {foodtype = FOODTYPE.ROUGHAGE},
    ["dug_rock_avocado_bush"] = {foodtype = FOODTYPE.ROUGHAGE},
    ["dug_bananabush"] = {foodtype = FOODTYPE.ROUGHAGE},
    ["dug_monkeytail"] = {foodtype = FOODTYPE.ROUGHAGE},
    ["log"] = {health = TUNING.HEALING_TINY, hunger = TUNING.CALORIES_TINY},
    ["cork"] = {health = TUNING.HEALING_TINY, hunger = TUNING.CALORIES_TINY},
    ["boards"] = {health = TUNING.HEALING_SMALL, hunger = TUNING.CALORIES_MEDSMALL},
    ["livinglog"] = {health = TUNING.HEALING_MED, hunger = TUNING.CALORIES_MED},
}

local function add_edible_wood_type(inst, data)
    if not TheWorld.ismastersim then
        return
    end

    local health = data.health
    local hunger = data.hunger
    local sanity = data.sanity
    local food_type = data.foodtype or FOODTYPE.WOOD

    if not inst.components.edible then
        inst:AddComponent("edible")
        inst.components.edible.foodtype = food_type
        inst.components.edible.secondaryfoodtype = FOODTYPE.WOOD
        inst.components.edible.hungervalue = hunger or TUNING.CALORIES_TINY/2
    elseif inst.components.edible.foodtype ~= food_type and inst.components.edible.secondaryfoodtype == nil then
        inst.components.edible.secondaryfoodtype = food_type
    elseif inst.components.edible.foodtype == food_type or inst.components.edible.secondaryfoodtype == food_type then

    end

    inst.components.edible.healthvalue = health or inst.components.edible.healthvalue
    inst.components.edible.hungervalue = hunger or inst.components.edible.hungervalue
    inst.components.edible.sanityvalue = sanity or inst.components.edible.sanityvalue
end

for name, data in pairs(wood_foods) do
    AddPrefabPostInit(name, function(inst) add_edible_wood_type(inst, data) end)
end
