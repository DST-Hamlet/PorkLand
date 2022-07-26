local LEVELTYPE = GLOBAL.LEVELTYPE

AddLevel(LEVELTYPE.SURVIVAL, {
    id = "PORKLAND_DEFAULT",
    name = "Porkland_level",
    desc = "Porkland_level",
    location = "forest",
    overrides = {
        task_set = "porkland",
        start_location = "PorklandStart",

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

        isporkland = true,
        no_joining_islands = false,
        has_ocean = false,
        -- {"start_setpeice", 	"PorklandStart"},
        -- {"start_node",		"BG_rainforest_base"},
        -- {"spring",			"noseason"},
        -- {"summer",			"noseason"},
    },

    background_node_range = {0, 1},
})