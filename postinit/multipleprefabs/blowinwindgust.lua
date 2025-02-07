local AddPrefabPostInit = AddPrefabPostInit
GLOBAL.setfenv(1, GLOBAL)

AddPrefabPostInit("grass", function (inst)
    MakePickableBlowInWindGust(inst, TUNING.GRASS_WINDBLOWN_SPEED, TUNING.GRASS_WINDBLOWN_FALL_CHANCE)
end)

AddPrefabPostInit("depleted_grass", function (inst)
    MakePickableBlowInWindGust(inst, TUNING.GRASS_WINDBLOWN_SPEED, TUNING.GRASS_WINDBLOWN_FALL_CHANCE)
end)

AddPrefabPostInit("sapling", function (inst)
    MakePickableBlowInWindGust(inst, TUNING.SAPLING_WINDBLOWN_SPEED, TUNING.SAPLING_WINDBLOWN_FALL_CHANCE)
end)

local evergreens = {
    "evergreen",
    "evergreen_sparse",
}
local deciduoustrees = {
    "deciduoustree",
}

local stages = {
    "short",
    "normal",
    "tall",
    "old",
}

local function make_tree_blow_in_wind_gust_evergreen(inst)
    if not TheWorld.ismastersim then
        return
    end

    MakeTreeBlowInWindGust(inst, stages, TUNING.EVERGREEN_WINDBLOWN_SPEED, TUNING.EVERGREEN_WINDBLOWN_FALL_CHANCE)
end

local function make_tree_blow_in_wind_gust_deciduous(inst)
    if not TheWorld.ismastersim then
        return
    end

    MakeTreeBlowInWindGust(inst, stages, TUNING.DECIDUOUS_WINDBLOWN_SPEED, TUNING.DECIDUOUS_WINDBLOWN_FALL_CHANCE)
end

for _, tree in pairs(evergreens) do
    AddPrefabPostInit(tree, make_tree_blow_in_wind_gust_evergreen)
end

for _, tree in pairs(deciduoustrees) do
    AddPrefabPostInit(tree, make_tree_blow_in_wind_gust_deciduous)
end
