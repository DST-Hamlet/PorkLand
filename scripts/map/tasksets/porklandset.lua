-- Also used in city_builder.lua
GLOBAL.PORKLAND_REQUIRED_PREFABS =
{
    "pugalisk_fountain",
    "roc_nest",
    "pig_ruins_entrance",
    "pig_ruins_entrance2",
    "pig_ruins_entrance3",
    "pig_ruins_entrance4",
    "pig_ruins_entrance5",
    "pig_ruins_exit",
    "pig_ruins_exit2",
    "pig_ruins_exit4",

    "anthill_exit",
    "anthill_exit",
    "anthill",

    --"teleportato_hamlet_base",
    --"teleportato_hamlet_box",
    --"teleportato_hamlet_crank",
    --"teleportato_hamlet_ring",
    --"teleportato_hamlet_potato", -- THE POTATO IS HANDLED IN CITYBUILDER AS A UNIQUE FARM.

    "ancient_robot_ribs",
    "ancient_robot_head",
    "ancient_robot_claw",
    "ancient_robot_claw",
    "ancient_robot_leg",
    "ancient_robot_leg",

    "teatree_piko_nest",
}

AddTaskSet("porkland", {
    name = GLOBAL.STRINGS.UI.CUSTOMIZATIONSCREEN.TASKSETNAMES.PORKLAND,
    location = "porkland",

    tasks = {
        "Pigtopia",
        "Pigtopia_capital",
        "Edge_of_civilization",
        "Edge_of_the_unknown",
        "Edge_of_the_unknown_2",
        "Lilypond_land",
        "Lilypond_land_2",
        "Deep_rainforest",
        "Deep_rainforest_2",
        "Deep_lost_ruins_gas",
        "Lost_Ruins_1",
        "Deep_rainforest_3",
        "Deep_rainforest_mandrake",
        "Path_to_the_others",
        "Other_pigtopia_capital",
        "Other_pigtopia",
        "Other_edge_of_civilization",
        "this_is_how_you_get_ants",

        "Deep_lost_ruins4",
        "lost_rainforest",

        "Land_Divide_1",
        "Land_Divide_2",
        "Land_Divide_3",
        "Land_Divide_4",

        "painted_sands",
        "plains",
        "rainforests",
        "rainforest_ruins",
        "plains_ruins",
        "pincale",

        "Deep_wild_ruins4",
        "wild_rainforest",
        "wild_ancient_ruins",
    },

    numoptionaltasks = 0,
    numrandom_set_pieces = 0,
    set_pieces = {
    --     ["TeleportatoHamletBaseLayout"] = {count = 1, tasks = {
    --         "Deep_rainforest",
    --         "Deep_rainforest_2",
    --         "Deep_rainforest_3",
    --         "Deep_lost_ruins4",
    --         "Deep_wild_ruins4",
    --         "wild_ancient_ruins",
    --     }},
    --    ["TeleportatoHamletBoxLayout"] = {count = 1, tasks = {
    --         "Edge_of_the_unknown",
    --        "Edge_of_the_unknown_2",
    --        "lost_rainforest",
    --        "painted_sands",
    --        "plains",
    --        "rainforests",
    --        "rainforest_ruins",
    --        "plains_ruins",
    --        "wild_rainforest",
    --        "Path_to_the_others",
    --      }},
    --    ["TeleportatoHamletCrankLayout"] = {count = 1, tasks = {
    --        "Edge_of_the_unknown",
    --        "Edge_of_the_unknown_2",
    --        "lost_rainforest",
    --        "painted_sands",
    --        "plains",
    --        "rainforests",
    --        "rainforest_ruins",
    --        "plains_ruins",
    --        "wild_rainforest",
    --        "Path_to_the_others",
    --      }},
    --    ["TeleportatoHamletRingLayout"] = {count = 1, tasks = {
    --        "Edge_of_the_unknown",
    --        "Edge_of_the_unknown_2",
    --        "lost_rainforest",
    --        "painted_sands",
    --        "plains",
    --        "rainforests",
    --        "rainforest_ruins",
    --        "plains_ruins",
    --        "wild_rainforest",
    --        "Path_to_the_others",
    --     }},
    --     --[[  THE POTATO IS HANDLED IN CITYBUILDER AS A UNIQUE FARM
    --     ["TeleportatoHamletPotatoLayout"] = { count = 1, tasks = {
    --        "Edge_of_civilization",
    --        "Other_edge_of_civilization",
    --     }},
    --     --]]
    },
    required_prefabs = GLOBAL.PORKLAND_REQUIRED_PREFABS
})

AddTaskSet("porkland_test", {
    name = "porkland_test",
    location = "porkland",
    tasks = {
        "porkland_test"
    },
    numoptionaltasks = 0,
    numrandom_set_pieces = 0,
    set_pieces = {},
    required_prefabs = {}
})
