local TheNet = GLOBAL.TheNet

PrefabFiles = {
    "adult_flytrap",
    "alloy",
    "antivenom",
    "aporkalypse_clock",
    "armor_metalplate",
    "ballpein_hammer",
    "basefan",
    "bill_quill",
    "bill",
    "birdwhistle",
    "boat_torch",
    "boatcontainer_classified",
    "boatrepairkit",
    "boats",
    "bonestaff",
    "bugfood",
    "chitin",
    "deep_jungle_fern_noise",
    "dungball",
    "dungbeetle",
    "dungpile",
    "exterior_texture_packages",
    "fast_farmplot_planted",
    "flotsam",
    "flower_rainforest",
    "floweroflife",
    "gaze_beam",
    "glowfly",
    "gold_dust",
    "goldpan",
    "grabbing_vine",
    "grass_tall",
    "halberd",
    "hanging_vine_patch",
    "hanging_vine",
    "hippo_antler",
    "hippopotamoose",
    "inv_vine",
    "iron",
    "inv_vine",
    "pig_ruins",
    "pl_wave_shore",
    "jungle_border_vine",
    "lilypad",
    "lotus",
    "lotus_flower",
    "machete",
    "mandrakehouse",
    "mandrakeman",
    "mean_flytrap",
    "nectar_pod",
    "nettle",
    "pangolden",
    "peagawk",
    -- "peagawk_spawner",
    "piko",
    "pl_chests",
    "pl_frog",
    "pl_froglegs",
    "pl_planted_tree",
    "pl_preparedfoods",
    "pl_veggies",
    "pl_walls",
    "pl_planted_veggies",
    "pl_foodbuffs",
    "peagawkfeather",
    "poisonbubble",
    "porkland_network",
    "porkland",
    "pugalisk_fountain",
    "pugalisk_ruins_pillar",
    "pugalisk_skull",
    "pugalisk_trap_door",
    "pugalisk",
    "rabid_beetle",
    "relics",
    "reeds_water",
    "rock_flippable",
    "rowboat_wake",
    "sail",
    "scorpion",
    "sedimentpuddle",
    "shears",
    "visual_slot",
    "shelves",
    "smelter",
    "snake",
    "snakeskin",
    "snakeoil",
    "snake_bone",
    "teatree_nut",
    "teatrees",
    "tree_pillar",
    "tuber",
    "tubertrees",
    "vampire_bat_wing",
    "vampirebat",
    "venomgland",
    "venus_stalk",
    "walkingstick",
    "waterdrop",
    "wave_ripple",
    "weevole_carapace",
    "weevole",
    "windtrail",
    "windswirl",
    "worldsound",

    "deco",
    "deco_academy",
    "deco_antiquities",
    "deco_chair",
    "deco_florist",
    "deco_lamp",
    "deco_lightglow",
    "deco_placers",
    "deco_plantholder",
    "deco_roomglow",
    "deco_ruins_fountain",
    "deco_swinging_light",
    "deco_table",
    "deco_wall_ornament",
    "interior_boundary",
    "interior_surface",
    "interior_texture_packages",
    "interiorwall_fx",
    "interiorfloor_fx",
    "vampirebatcave",
    "interiorworkblank",
    "prop_door",
    "pig_ruins_creeping_vines",
    "pl_birds",
    "pl_fish",
    "bat_hide",
    "cave_entrance_roc",
    "pig_ruins_light_beam",
    "pig_ruins_entrance",
    "wallcrack_ruins",
    "pig_ruins_pressure_plate",
    "pig_ruins_dart_statue",
    "smashingpot",
    "pig_ruins_dart",
    "pig_ruins_torch",
    "lightrays_jungle",
    "pig_ruins_spear_trap",
    "pigghost",
    "rugs",
    "pheromonestone",
    "antcombhome",
    "anthill_lamp",
    "anthill_stalactite",
    "antcombhome",
    "magnifying_glass",
    "disarmingkit",

    "ancient_hulk",
    "ancient_robot_assembly",
    "ancient_robots",
    "infused_iron",
    "living_artifact",
    "ancient_hulk_laser",
    "burr",
    "poisonmist",
    "rainforesttrees",
    "clawpalmtrees",
    "cork",
    "clawpalmtree_sapling",
    "bramble_bulb",
    "pog",
    "pogherd",
    "spider_monkey",
    "pl_chests",


    "pighouse_city",
    "pig_shop",
    "pig_guard_tower",
    "playerhouse_city",
    "pigman_city",
    "pigman_shopkeeper_desk",
    "city_lamp",
    "hedge",
    "lawnornaments",
    "topiary",
    "clippings",
    "reconstruction_project",
    "city_hammer",
    "shop_buyer",
    "trinkets_giftshop",
    "deed",
    "securitycontract",
    "key_to_city",

    "oinc",
    "bramble",
    "antsuit",
    "armor_weevole",
    "blunderbuss",
    "bugrepellent",
    "candlefire",
    "corkbat",
    "gascloud",
    "pl_hats",
    "pl_turfs",
    "poisonbalm",
    "snakeskin_jacket",
    "pl_magicprototyper",
    "cloudpuff",
    "batsonar_fx",
    "ancient_herald",
    "armor_vortex_cloak",
    "herald_tatters",
    "firerain",
    "lavapool",
    "meteor_impact",
    "obsidian",
    "pigbandit",
    "banditmap",
    "tunacan",

    "nettle_plant",
    "sprinkler",
    "water_pipe",
    "water_spray",
    "pl_plantables",

    "thunderbird",
    "thunderbirdnest",

    "pedestal_key",

    "gnat",
    "gnatmound",

    "waterfall_lilypond",
    "waterfall_sfx",

    "fabric", -- 亚丹：这个表一开始不是说按照字母顺序进行排序的吗 ziwbi: 排序一下不就好了
    "inv_bamboo",
    "sand",


    "roc_nest",
    "ro_bin_egg",
    "ro_bin_gizzard_stone",
    "ro_bin",
    "pig_scepter",

    "ox_horn",
    "ox_flute",
    "porklandintro",

    "roc",
    "roc_body_parts",

    "cutlass",
    "pl_feathers",

    "giantgrub",
    "antman",
    "antman_warrior",
    "antman_warrior_egg",
    "anthill",
    "antlarva",
    "antqueen",
    "antqueen_chamber",

    "house_door",
    "construction_permit",
    "demolition_permit",

    "coconade",
    "trawlnet",
    "sunkenprefab",

    "pl_bat",

    "falloff_fx",
    "cloud_fx",
    "group_parent",

    "wheeler",
    "trusty_shooter",
    "wheeler_tracker",
}

Assets = {
    -- minimap
    Asset("ATLAS", "images/minimap/pl_minimap.xml"),

    -- inventoryimages
    Asset("ATLAS", "images/hud/pl_inventoryimages.xml"),
    Asset("ATLAS_BUILD", "images/hud/pl_inventoryimages.xml", 256), -- for minisign

    -- boat
    Asset("ATLAS", "images/hud/pl_hud.xml"),
    Asset("IMAGE", "images/hud/pl_hud.tex"),

    -- crafting menu icons
    Asset("ATLAS", "images/hud/pl_crafting_menu_icons.xml"),

    -- minimap hud
    Asset("ATLAS", "images/hud/pl_minimaphud.xml"),
    Asset("IMAGE", "images/hud/pl_minimaphud.tex"),

    -- interior map toggle button and arrows
    Asset("ATLAS", "images/hud/pl_mapscreen_widgets.xml"),
    Asset("IMAGE", "images/hud/pl_mapscreen_widgets.tex"),

    -- falloff
    Asset("IMAGE", "levels/tiles/black_falloff.tex"),
    Asset("FILE", "levels/tiles/black_falloff.xml"),

    -- hud
    Asset("ATLAS", "images/overlays/fx3.xml"), -- poison, boat_over
    Asset("IMAGE", "images/overlays/fx3.tex"),
    Asset("ATLAS", "images/overlays/fx4.xml"), -- pollen(hayfever)
    Asset("IMAGE", "images/overlays/fx4.tex"),
    Asset("ATLAS", "images/overlays/fx5.xml"), -- fog
    Asset("IMAGE", "images/overlays/fx5.tex"),
    Asset("ATLAS", "images/overlays/fx6.xml"),  -- living artifact
    Asset("IMAGE", "images/overlays/fx6.tex"),
    Asset("ANIM", "anim/leaves_canopy2.zip"),  -- canopy
    Asset("ANIM", "anim/livingartifact_meter.zip"),
    Asset("ANIM", "anim/poison_meter_overlay.zip"),
    Asset("ANIM", "anim/trawlnet_meter.zip"),

    Asset("ANIM", "anim/moon_aporkalypse_phases.zip"), -- blood moon

    -- player_actions
    Asset("ANIM", "anim/player_idles_poison.zip"),
    Asset("ANIM", "anim/player_mount_idles_poison.zip"),
    Asset("ANIM", "anim/player_actions_hack.zip"),
    Asset("ANIM", "anim/player_actions_shear.zip"),
    Asset("ANIM", "anim/player_sneeze.zip"),
    Asset("ANIM", "anim/player_mount_sneeze.zip"),
    Asset("ANIM", "anim/player_actions_tap.zip"),
    Asset("ANIM", "anim/player_actions_panning.zip"),
    Asset("ANIM", "anim/player_boat_onoff.zip"),
    Asset("ANIM", "anim/swap_paddle.zip"),
    Asset("ANIM", "anim/player_action_sailing.zip"),
    Asset("ANIM", "anim/player_boat_death.zip"),
    Asset("ANIM", "anim/werebeaver_boat_death.zip"),
    Asset("ANIM", "anim/player_lifeplant.zip"),
    Asset("ANIM", "anim/player_actions_hand_lens.zip"),
    Asset("ANIM", "anim/player_living_suit_destruct.zip"),
    Asset("ANIM", "anim/player_living_suit_morph.zip"),
    Asset("ANIM", "anim/player_living_suit_punch.zip"),
    Asset("ANIM", "anim/player_living_suit_shoot.zip"),
    Asset("ANIM", "anim/player_actions_cropdust.zip"),
    Asset("ANIM", "anim/player_actions_speargun.zip"),
    Asset("ANIM", "anim/player_mount_actions_cropdust.zip"),
    Asset("ANIM", "anim/player_mount_actions_speargun.zip"),
    Asset("ANIM", "anim/player_actions_scroll.zip"),
    Asset("ANIM", "anim/player_mount_actions_scroll.zip"),
    Asset("ANIM", "anim/player_teleport_bfb.zip"),
    Asset("ANIM", "anim/player_teleport_bfb2.zip"),
    Asset("ANIM", "anim/player_pistol.zip"),

    -- replace_anim
    Asset("ANIM", "anim/replace_anim/player_attacks_old.zip"),
    Asset("ANIM", "anim/replace_anim/player_hits_old.zip"),

    -- boat ui
    Asset("ANIM", "anim/boat_health.zip"),
    Asset("ANIM", "anim/boat_hud_raft.zip"),
    Asset("ANIM", "anim/boat_hud_row.zip"),
    Asset("ANIM", "anim/boat_hud_cargo.zip"),
    Asset("ANIM", "anim/boat_inspect_raft.zip"),
    Asset("ANIM", "anim/boat_inspect_row.zip"),
    Asset("ANIM", "anim/boat_inspect_cargo.zip"),

    -- boat sail visual
    Asset("ANIM", "anim/sail_visual.zip"),
    Asset("ANIM", "anim/sail_visual_idle.zip"),
    Asset("ANIM", "anim/sail_visual_trawl.zip"),

    -- floater
    Asset("ANIM", "anim/ripple_build.zip"),

    Asset("ANIM", "anim/meat_rack_food_pl.zip"),

    -- Wind blown
    Asset("ANIM", "anim/grass_blown.zip"),
    Asset("ANIM", "anim/sapling_blown.zip"),
    Asset("ANIM", "anim/evergreen_short_blown.zip"),
    Asset("ANIM", "anim/evergreen_tall_blown.zip"),
    Asset("ANIM", "anim/grass_inwater.zip"),
    Asset("ANIM", "anim/tree_leaf_normal_blown.zip"),
    Asset("ANIM", "anim/tree_leaf_short_blown.zip"),
    Asset("ANIM", "anim/tree_leaf_tall_blown.zip"),

    -- visualvariant
    Asset("ANIM", "anim/grassgreen_build.zip"),
    Asset("ANIM", "anim/cutgrassgreen.zip"),
    Asset("ANIM", "anim/log_rainforest.zip"),

    -- multiplayer_portal
    Asset("ANIM", "anim/portal_dst.zip"),

    -- worldgen screen
    Asset("ANIM", "anim/generating_hamlet.zip"),

    -- Billboard
    Asset("SHADER", "shaders/animrotatingbillboard.ksh"),

    -- Waterfall
    Asset("SHADER", "shaders/anim_waterfall.ksh"),
    Asset("SHADER", "shaders/anim_waterfall_corner.ksh"),

    -- Vertical
    Asset("SHADER", "shaders/anim_vertical.ksh"),

    -- Interior MiniMap
    Asset("ATLAS", "interior_minimap/interior_minimap.xml"),
    Asset("ATLAS", "levels/textures/map_interior/mini_floor_marble_royal.xml"),
    Asset("IMAGE", "levels/textures/map_interior/mini_floor_marble_royal.tex"),
    Asset("ATLAS", "levels/textures/map_interior/mini_ruins_slab.xml"),
    Asset("IMAGE", "levels/textures/map_interior/mini_ruins_slab.tex"),
    Asset("ATLAS", "levels/textures/map_interior/mini_antcave_floor.xml"),
    Asset("IMAGE", "levels/textures/map_interior/mini_antcave_floor.tex"),
    Asset("ATLAS", "levels/textures/map_interior/mini_vamp_cave_noise.xml"),
    Asset("IMAGE", "levels/textures/map_interior/mini_vamp_cave_noise.tex"),

    Asset("ATLAS", "levels/textures/map_interior/mini_floor_wood.xml"),
    Asset("IMAGE", "levels/textures/map_interior/mini_floor_wood.tex"),
    Asset("ATLAS", "levels/textures/map_interior/mini_floor_woodpanels.xml"),
    Asset("IMAGE", "levels/textures/map_interior/mini_floor_woodpanels.tex"),
    Asset("ATLAS", "levels/textures/map_interior/mini_floor_marble.xml"),
    Asset("IMAGE", "levels/textures/map_interior/mini_floor_marble.tex"),
    Asset("ATLAS", "levels/textures/map_interior/mini_floor_checker.xml"),
    Asset("IMAGE", "levels/textures/map_interior/mini_floor_checker.tex"),
    Asset("ATLAS", "levels/textures/map_interior/mini_floor_checkered.xml"),
    Asset("IMAGE", "levels/textures/map_interior/mini_floor_checkered.tex"),
    Asset("ATLAS", "levels/textures/map_interior/mini_floor_cityhall.xml"),
    Asset("IMAGE", "levels/textures/map_interior/mini_floor_cityhall.tex"),
    Asset("ATLAS", "levels/textures/map_interior/mini_floor_sheetmetal.xml"),
    Asset("IMAGE", "levels/textures/map_interior/mini_floor_sheetmetal.tex"),
    Asset("ATLAS", "levels/textures/map_interior/mini_floor_geometrictiles.xml"),
    Asset("IMAGE", "levels/textures/map_interior/mini_floor_geometrictiles.tex"),
    Asset("ATLAS", "levels/textures/map_interior/mini_floor_shag_carpet.xml"),
    Asset("IMAGE", "levels/textures/map_interior/mini_floor_shag_carpet.tex"),
    Asset("ATLAS", "levels/textures/map_interior/mini_floor_transitional.xml"),
    Asset("IMAGE", "levels/textures/map_interior/mini_floor_transitional.tex"),
    Asset("ATLAS", "levels/textures/map_interior/mini_floor_herringbone.xml"),
    Asset("IMAGE", "levels/textures/map_interior/mini_floor_herringbone.tex"),
    Asset("ATLAS", "levels/textures/map_interior/mini_floor_hexagon.xml"),
    Asset("IMAGE", "levels/textures/map_interior/mini_floor_hexagon.tex"),
    Asset("ATLAS", "levels/textures/map_interior/mini_floor_hoof_curvy.xml"),
    Asset("IMAGE", "levels/textures/map_interior/mini_floor_hoof_curvy.tex"),
    Asset("ATLAS", "levels/textures/map_interior/mini_floor_octagon.xml"),
    Asset("IMAGE", "levels/textures/map_interior/mini_floor_octagon.tex"),

    -- Cookbook HD icons
    Asset("ATLAS", "images/hud/pl_cook_pot_food_image.xml"),
    Asset("IMAGE", "images/hud/pl_cook_pot_food_image.tex"),

    Asset("SHADER", "shaders/ui_fillmode.ksh"),
    Asset("SHADER", "shaders/ui_anim_cc_nolight.ksh"),
}

for _, v in ipairs(require("main/interior_texture_defs").Assets) do
    table.insert(Assets, v)
end

ToolUtil.RegisterInventoryItemAtlas("images/hud/pl_inventoryimages.xml")
AddMinimapAtlas("images/minimap/pl_minimap.xml")
AddMinimapAtlas("interior_minimap/interior_minimap.xml")

local sounds = {
    Asset("SOUND", "sound/DLC003_AMB_stream.fsb"),
    Asset("SOUND", "sound/DLC003_music_stream.fsb"),
    Asset("SOUND", "sound/DLC003_sfx.fsb"),
    Asset("SOUNDPACKAGE", "sound/dontstarve_DLC003.fev"),
    Asset("SOUND", "sound/dontstarve_shipwreckedSFX.fsb"),
    Asset("SOUNDPACKAGE", "sound/dontstarve_DLC002.fev"),
    Asset("SOUND", "sound/porkland_soundpackage_bank_1.fsb"),
    Asset("SOUNDPACKAGE", "sound/porkland_soundpackage.fev"),
}

local shade_anim_assets =
{
    {path = "images/shade_anim/roc_shadow/shadow/shadow-", length = 0},
    {path = "images/shade_anim/roc_shadow/ground_pre/ground_pre-", length = 42},
    {path = "images/shade_anim/roc_shadow/ground_loop/ground_loop-", length = 0},
    {path = "images/shade_anim/roc_shadow/ground_pst/ground_pst-", length = 54},
    {path = "images/shade_anim/roc_shadow/shadow_flap_loop/shadow_flap_loop-", length = 37},
}
for _, v in ipairs(shade_anim_assets) do
    for i = 0, v.length do
        local realframe = i + 1
        local framepath = v.path..tostring(realframe)..".tex"
        table.insert(Assets, Asset("IMAGE", framepath))
    end
end

if not TheNet:IsDedicated() then
    for _, asset in ipairs(sounds) do
        table.insert(Assets, asset)
    end
end

local function AddCharacter(name, gender)
    table.insert(Assets, Asset("ATLAS", "bigportraits/"..name..".xml"))
    -- table.insert(Assets, Asset("ATLAS", "bigportraits/"..name.."_none.xml"))
    -- table.insert(Assets, Asset("ATLAS", "images/names_"..name..".xml"))
    table.insert(Assets, Asset("ATLAS", "images/avatars/avatar_"..name..".xml"))
    -- table.insert(Assets, Asset("ATLAS", "images/avatars/avatar_ghost_"..name..".xml"))
    table.insert(Assets, Asset("ATLAS", "images/avatars/self_inspect_"..name..".xml"))
    -- table.insert(Assets, Asset("ATLAS", "images/saveslot_portraits/"..name..".xml"))
    -- table.insert(Assets, Asset("ATLAS", "images/crafting_menu_avatars/avatar_"..name..".xml"))

    AddModCharacter(name, gender)
end

AddCharacter("wheeler", "FEMALE")
