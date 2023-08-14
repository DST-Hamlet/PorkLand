local LEVELTYPE = GLOBAL.LEVELTYPE

AddLevel(LEVELTYPE.SURVIVAL, {
    id = "PORKLAND_DEFAULT",
    name = "Pork Land",
    desc = "Pork Land",
    location = "porkland",
    overrides = {
        task_set = "porkland",
        start_location = "PorkLandStart",

        prefabswaps_start = "classic",

        roads = "never",
        branching = "least",

        frograin = "never",
        wildfires = "never",

        deerclops = "never",
        bearger = "never",

        perd = "never",  --火鸡
        penguins = "never",  -- 企鹅
        hunt = "never",  -- 脚印

        no_joining_islands = false,
        has_ocean = false,

        -- {"start_setpeice",    "PorkLandStart"},
        -- {"start_node",        "BG_rainforest_base"},

        pl_clocktype = "plateau",
    },

    background_node_range = {0, 1},
})
