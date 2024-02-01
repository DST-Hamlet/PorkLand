require("map/lockandkey")

local function add_simple_key_lock(name)
    if KEYS[name] then
        return
    end

    table.insert(KEYS_ARRAY, name)
    table.insert(LOCKS_ARRAY, name)
    KEYS[name] = #KEYS_ARRAY
    LOCKS[name] = #KEYS_ARRAY
    LOCKS_KEYS[LOCKS[name]] = {KEYS[name]}
end

add_simple_key_lock("JUNGLE_DEPTH_1")
add_simple_key_lock("JUNGLE_DEPTH_2")
add_simple_key_lock("JUNGLE_DEPTH_3")

add_simple_key_lock("CIVILIZATION_1")
add_simple_key_lock("CIVILIZATION_2")

add_simple_key_lock("RUINS_ENTRANCE_1")
add_simple_key_lock("RUINS_EXIT_1")

add_simple_key_lock("OTHER_CIVILIZATION_1")
add_simple_key_lock("OTHER_CIVILIZATION_2")

add_simple_key_lock("OTHER_JUNGLE_DEPTH_1")
add_simple_key_lock("OTHER_JUNGLE_DEPTH_2")

add_simple_key_lock("LOST_JUNGLE_DEPTH_1")
add_simple_key_lock("LOST_JUNGLE_DEPTH_2")

add_simple_key_lock("WILD_JUNGLE_DEPTH_1")
add_simple_key_lock("WILD_JUNGLE_DEPTH_2")
add_simple_key_lock("WILD_JUNGLE_DEPTH_3")

add_simple_key_lock("PINACLE")
add_simple_key_lock("IMPASS")

add_simple_key_lock("ISLAND_1")
add_simple_key_lock("ISLAND_2")
add_simple_key_lock("ISLAND_3")
add_simple_key_lock("ISLAND_4")
add_simple_key_lock("ISLAND_5")

add_simple_key_lock("INTERIOR")

add_simple_key_lock("LAND_DIVIDE_1")
add_simple_key_lock("LAND_DIVIDE_2")
add_simple_key_lock("LAND_DIVIDE_3")
add_simple_key_lock("LAND_DIVIDE_4")
add_simple_key_lock("LAND_DIVIDE_5")
