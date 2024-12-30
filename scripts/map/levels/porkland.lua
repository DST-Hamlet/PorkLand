local LEVELTYPE = GLOBAL.LEVELTYPE
local STRINGS = GLOBAL.STRINGS

AddLevel(LEVELTYPE.SURVIVAL, {
    id = "PORKLAND_DEFAULT",
    name = STRINGS.UI.CUSTOMIZATIONSCREEN.PRESETLEVELS.PORKLAND,
    desc = STRINGS.UI.CUSTOMIZATIONSCREEN.PRESETLEVELDESC.PORKLAND,
    version = 2,
    location = "porkland",
    overrides = {
        task_set = "porkland",
        start_location = "PorkLandStart",

        prefabswaps_start = "classic",

        spawnmode = "fixed",
        specialevent = "none",
        grassgekkos = "never",

        roads = "never",
        branching = "least",

        frograin = "never",
        wildfires = "never",

        deerclops = "never",
        bearger = "never",
        deciduousmonster = "never",

        perd = "never",  --火鸡
        penguins = "never",  -- 企鹅
        hunt = "never",  -- 脚印

        no_joining_islands = false,

        pl_clocktype = "plateau",
    },

    background_node_range = {0, 1},
})

AddLevel(LEVELTYPE.SURVIVAL, {
    id = "PORKLAND_TEST",
    name = "PORKLAND_TEST",
    desc = "PORKLAND_TEST",
    version = 2,
    location = "porkland",
    overrides = {
        world_size = "small",
        start_location = "PorkLandStart",
        task_set = "porkland_test",
        pl_clocktype = "plateau",
        keep_disconnected_tiles = true,
    },

    background_node_range = {0, 1},
})
