local AddPrefabPostInit = AddPrefabPostInit
GLOBAL.setfenv(1, GLOBAL)

--[[ 
TODO: Add respective animations

AddPrefabPostInit("grass", function (inst)
    MakePickableBlowInWindGust(inst, TUNING.GRASS_WINDBLOWN_SPEED, TUNING.GRASS_WINDBLOWN_FALL_CHANCE)
end)

AddPrefabPostInit("depleted_grass", function (inst)
    MakePickableBlowInWindGust(inst, TUNING.GRASS_WINDBLOWN_SPEED, TUNING.GRASS_WINDBLOWN_FALL_CHANCE)
end)

AddPrefabPostInit("sapling", function (inst)
    MakePickableBlowInWindGust(inst, TUNING.SAPLING_WINDBLOWN_SPEED, TUNING.SAPLING_WINDBLOWN_FALL_CHANCE)
end)
--]]
