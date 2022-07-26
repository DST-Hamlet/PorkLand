require("map/lockandkey")

local function AddSimpleKeyLock(name)
    if KEYS[name] then
        return
    end

    table.insert(KEYS_ARRAY, name)
    KEYS[name] = #KEYS_ARRAY
    table.insert(LOCKS_ARRAY, name)
    LOCKS[name] = #KEYS_ARRAY
    LOCKS_KEYS[LOCKS[name]] = {KEYS[name]}
end

AddSimpleKeyLock("JUNGLE_DEPTH_1")
AddSimpleKeyLock("JUNGLE_DEPTH_2")
AddSimpleKeyLock("JUNGLE_DEPTH_3")

AddSimpleKeyLock("CIVILIZATION_1")
AddSimpleKeyLock("CIVILIZATION_2")

AddSimpleKeyLock("RUINS_ENTRANCE_1")
AddSimpleKeyLock("RUINS_EXIT_1")

AddSimpleKeyLock("OTHER_CIVILIZATION_1")
AddSimpleKeyLock("OTHER_CIVILIZATION_2")

AddSimpleKeyLock("OTHER_JUNGLE_DEPTH_1")
AddSimpleKeyLock("OTHER_JUNGLE_DEPTH_2")

AddSimpleKeyLock("LOST_JUNGLE_DEPTH_1")
AddSimpleKeyLock("LOST_JUNGLE_DEPTH_2")

AddSimpleKeyLock("WILD_JUNGLE_DEPTH_1")
AddSimpleKeyLock("WILD_JUNGLE_DEPTH_2")
AddSimpleKeyLock("WILD_JUNGLE_DEPTH_3")

AddSimpleKeyLock("PINACLE")
AddSimpleKeyLock("IMPASS")

AddSimpleKeyLock("ISLAND_1")
AddSimpleKeyLock("ISLAND_2")
AddSimpleKeyLock("ISLAND_3")
AddSimpleKeyLock("ISLAND_4")
AddSimpleKeyLock("ISLAND_5")

AddSimpleKeyLock("INTERIOR")

AddSimpleKeyLock("LAND_DIVIDE_1")
AddSimpleKeyLock("LAND_DIVIDE_2")
AddSimpleKeyLock("LAND_DIVIDE_3")
AddSimpleKeyLock("LAND_DIVIDE_4")
AddSimpleKeyLock("LAND_DIVIDE_5")