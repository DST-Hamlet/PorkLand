require("map/lockandkey")

local function AddSimpleKeyAndLock(name)
    if KEYS[name] then
        return
    end

    table.insert(KEYS_ARRAY, name)
    table.insert(LOCKS_ARRAY, name)
    KEYS[name] = #KEYS_ARRAY
    LOCKS[name] = #KEYS_ARRAY
    LOCKS_KEYS[LOCKS[name]] = {KEYS[name]}
end

AddSimpleKeyAndLock("JUNGLE_DEPTH_1")
AddSimpleKeyAndLock("JUNGLE_DEPTH_2")
AddSimpleKeyAndLock("JUNGLE_DEPTH_3")

AddSimpleKeyAndLock("CIVILIZATION_1")
AddSimpleKeyAndLock("CIVILIZATION_2")

AddSimpleKeyAndLock("RUINS_ENTRANCE_1")
AddSimpleKeyAndLock("RUINS_EXIT_1")

AddSimpleKeyAndLock("OTHER_CIVILIZATION_1")
AddSimpleKeyAndLock("OTHER_CIVILIZATION_2")

AddSimpleKeyAndLock("OTHER_JUNGLE_DEPTH_1")
AddSimpleKeyAndLock("OTHER_JUNGLE_DEPTH_2")

AddSimpleKeyAndLock("LOST_JUNGLE_DEPTH_1")
AddSimpleKeyAndLock("LOST_JUNGLE_DEPTH_2")

AddSimpleKeyAndLock("WILD_JUNGLE_DEPTH_1")
AddSimpleKeyAndLock("WILD_JUNGLE_DEPTH_2")
AddSimpleKeyAndLock("WILD_JUNGLE_DEPTH_3")

AddSimpleKeyAndLock("PINACLE")
AddSimpleKeyAndLock("IMPASS")

AddSimpleKeyAndLock("ISLAND_1")
AddSimpleKeyAndLock("ISLAND_2")
AddSimpleKeyAndLock("ISLAND_3")
AddSimpleKeyAndLock("ISLAND_4")
AddSimpleKeyAndLock("ISLAND_5")

AddSimpleKeyAndLock("INTERIOR")

AddSimpleKeyAndLock("LAND_DIVIDE_1")
AddSimpleKeyAndLock("LAND_DIVIDE_2")
AddSimpleKeyAndLock("LAND_DIVIDE_3")
AddSimpleKeyAndLock("LAND_DIVIDE_4")
AddSimpleKeyAndLock("LAND_DIVIDE_5")
