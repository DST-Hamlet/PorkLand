local LEVELTYPE = GLOBAL.LEVELTYPE
local STRINGS = GLOBAL.STRINGS

AddLevel(LEVELTYPE.SURVIVAL, {
    id = "PORKLAND_DEFAULT",
    name = STRINGS.UI.CUSTOMIZATIONSCREEN.PRESETLEVELS.PORKLAND,
    desc = STRINGS.UI.CUSTOMIZATIONSCREEN.PRESETLEVELDESC.PORKLAND,
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
        grassgekkos = "never",

        no_joining_islands = false,

        pl_clocktype = "plateau",
    },

    background_node_range = {0, 1},
})
