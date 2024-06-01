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
	"evergreen_normal",
    "evergreen_tall",
    "evergreen_short",
    "evergreen_sparse",
    "evergreen_sparse_normal",
    "evergreen_sparse_tall",
    "evergreen_sparse_short",
    "evergreen_burnt",
}
local deciduoustrees = {
    "deciduoustree",
    "deciduoustree_normal",
    "deciduoustree_tall",
    "deciduoustree_short",
    "deciduoustree_burnt",
}

local stages = {
    "short",
    "normal",
    "tall",
    "old",
}

for _, tree in pairs(evergreens) do
    AddPrefabPostInit(tree, function(inst)
        if not TheWorld.ismastersim then
            return
        end

        MakeTreeBlowInWindGust(inst, stages, TUNING.EVERGREEN_WINDBLOWN_SPEED, TUNING.EVERGREEN_WINDBLOWN_FALL_CHANCE)
    end)
end

for _, tree in pairs(deciduoustrees) do
    AddPrefabPostInit(tree, function(inst)
        if not TheWorld.ismastersim then
            return
        end

        MakeTreeBlowInWindGust(inst, stages, TUNING.DECIDUOUS_WINDBLOWN_SPEED, TUNING.DECIDUOUS_WINDBLOWN_FALL_CHANCE)
    end)
end
