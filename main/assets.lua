local TheNet = GLOBAL.TheNet

PrefabFiles = {
    "adult_flytrap",
    "alloy",
    "ancient_herald",
    "ancient_hulk_laser",
    "ancient_hulk",
    "ancient_robot_assembly",
    "ancient_robots",
    "antcombhome",
    "antcombhome",
    "anthill_lamp",
    "anthill_stalactite",
    "anthill",
    "antivenom",
    "antlarva",
    "antman_warrior_egg",
    "antman_warrior",
    "antman",
    "antqueen_chamber",
    "antqueen",
    "antsuit",
    "aporkalypse_clock",
    "armor_metalplate",
    "armor_vortex_cloak",
    "armor_weevole",
    "ballpein_hammer",
    "banditmap",
    "basefan",
    "bat_hide",
    "batsonar_fx",
    "bill_quill",
    "bill",
    "birdwhistle",
    "blunderbuss",
    "boat_torch",
    "boatrepairkit",
    "boats",
    "bonestaff",
    "bramble_bulb",
    "bramble",
    "bugfood",
    "bugrepellent",
    "burr",
    "candlefire",
    "cave_entrance_roc",
    "chitin",
    "city_hammer",
    "city_lamp",
    "clawpalmtree_sapling",
    "clawpalmtrees",
    "clippings",
    "cloud_fx",
    "cloudpuff",
    "coconade",
    "construction_permit",
    "cork",
    "corkbat",
    "cutlass",
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
    "deco",
    "deed",
    "deep_jungle_fern_noise",
    "demolition_permit",
    "disarmingkit",
    "dungball",
    "dungbeetle",
    "dungpile",
    "exterior_texture_packages",
    "fabric",
    "falloff_fx",
    "fast_farmplot_planted",
    "firerain",
    "flotsam",
    "flower_rainforest",
    "floweroflife",
    "gascloud",
    "gaze_beam",
    "giantgrub",
    "glowfly",
    "gnat",
    "gnatmound",
    "gold_dust",
    "goldpan",
    "grabbing_vine",
    "grass_tall",
    "group_child",
    "group_parent",
    "halberd",
    "hanging_vine_patch",
    "hanging_vine",
    "hedge",
    "herald_tatters",
    "hippo_antler",
    "hippopotamoose",
    "house_door",
    "infused_iron",
    "interior_boundary",
    "interior_surface",
    "interior_texture_packages",
    "interiorfloor_fx",
    "interiorwall_fx",
    "interiorworkblank",
    "inv_bamboo",
    "inv_vine",
    "inv_vine",
    "iron",
    "jungle_border_vine",
    "key_to_city",
    "lavapool",
    "lawnornaments",
    "lightrays_jungle",
    "lilypad",
    "living_artifact",
    "lotus_flower",
    "lotus",
    "machete",
    "magnifying_glass",
    "mandrakehouse",
    "mandrakeman",
    "mean_flytrap",
    "meteor_impact",
    "nectar_pod",
    "nettle_plant",
    "nettle",
    "obsidian",
    "oinc",
    "ox_flute",
    "ox_horn",
    "pangolden",
    "peagawk",
    "peagawkfeather",
    "pedestal_key",
    "pheromonestone",
    "pig_guard_tower",
    "pig_ruins_creeping_vines",
    "pig_ruins_dart_statue",
    "pig_ruins_dart",
    "pig_ruins_entrance",
    "pig_ruins_light_beam",
    "pig_ruins_pressure_plate",
    "pig_ruins_spear_trap",
    "pig_ruins_torch",
    "pig_ruins",
    "pig_scepter",
    "pig_shop",
    "pigbandit",
    "pigghost",
    "pighouse_city",
    "pigman_city",
    "pigman_shopkeeper_desk",
    "piko",
    "pl_bat",
    "pl_birds",
    "pl_chests",
    "pl_chests",
    "pl_feathers",
    "pl_fish",
    "pl_foodbuffs",
    "pl_frog",
    "pl_froglegs",
    "pl_hats",
    "pl_magicprototyper",
    "pl_plantables",
    "pl_planted_tree",
    "pl_planted_veggies",
    "pl_preparedfoods",
    "pl_turfs",
    "pl_veggies",
    "pl_walls",
    "pl_wave_shore",
    "playerhouse_city",
    "pog",
    "pogherd",
    "poisonbalm",
    "poisonbubble",
    "poisonmist",
    "porkland_network",
    "porkland",
    "porklandintro",
    "prop_door",
    "pugalisk_fountain",
    "pugalisk_ruins_pillar",
    "pugalisk_skull",
    "pugalisk_trap_door",
    "pugalisk",
    "rabid_beetle",
    "rainforesttrees",
    "reconstruction_project",
    "reeds_water",
    "relics",
    "ro_bin_egg",
    "ro_bin_gizzard_stone",
    "ro_bin",
    "roc_body_parts",
    "roc_nest",
    "roc",
    "rock_flippable",
    "rowboat_wake",
    "rugs",
    "sail",
    "sand",
    "scorpion",
    "securitycontract",
    "sedimentpuddle",
    "shears",
    "shelves",
    "shop_buyer",
    "smashingpot",
    "smelter",
    "snake_bone",
    "snake",
    "snakeoil",
    "snakeskin_jacket",
    "snakeskin",
    "spider_monkey",
    "sprinkler",
    "sunkenprefab",
    "target_indicator_marker",
    "teatree_nut",
    "teatrees",
    "thunderbird",
    "thunderbirdnest",
    "tile_fx",
    "topiary",
    "trawlnet",
    "tree_pillar",
    "trinkets_giftshop",
    "trusty_shooter",
    "tuber",
    "tubertrees",
    "tunacan",
    "vampire_bat_wing",
    "vampirebat",
    "vampirebatcave",
    "venomgland",
    "venus_stalk",
    "visual_slot",
    "walkingstick",
    "wallcrack_ruins",
    "water_pipe",
    "water_spray",
    "waterdrop",
    "waterfall_lilypond",
    "waterfall_sfx",
    "wave_ripple",
    "weevole_carapace",
    "weevole",
    "wheeler_tracker",
    "wheeler",
    "windswirl",
    "windtrail",
    "worldsound",
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
    Asset("ANIM", "anim/pl_leaves_canopy.zip"),

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
    Asset("ANIM", "anim/player_actions_sailing.zip"),
    Asset("ANIM", "anim/player_boat_death.zip"),
    Asset("ANIM", "anim/werebeaver_boat_death.zip"),
    Asset("ANIM", "anim/player_lifeplant.zip"),
    Asset("ANIM", "anim/player_actions_hand_lens.zip"),
    Asset("ANIM", "anim/player_mount_hand_lens.zip"),
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
    Asset("ANIM", "anim/player_mount_pistol.zip"),

    -- replace_anim
    Asset("ANIM", "anim/replace_anim/player_attacks_old.zip"),
    Asset("ANIM", "anim/replace_anim/player_hits_old.zip"),
    Asset("ANIM", "anim/replace_anim/player_idles_fixed.zip"),

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

    -- wheeler ui
    Asset("ANIM", "anim/wheeler_compass_hud.zip"),
    Asset("ANIM", "anim/wheeler_compass_bg.zip"),

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
    -- TODO: Decide if we want to use Glassic API or not for character skins
    -- table.insert(Assets, Asset("ATLAS", "bigportraits/"..name.."_none.xml"))
    table.insert(Assets, Asset("ATLAS", "images/names_gold_"..name..".xml"))
    table.insert(Assets, Asset("ATLAS", "images/names_gold_cn_"..name..".xml"))
    table.insert(Assets, Asset("ATLAS", "images/avatars/avatar_"..name..".xml"))
    table.insert(Assets, Asset("ATLAS", "images/avatars/avatar_ghost_"..name..".xml"))
    table.insert(Assets, Asset("ATLAS", "images/avatars/self_inspect_"..name..".xml"))
    -- table.insert(Assets, Asset("ATLAS", "images/saveslot_portraits/"..name..".xml"))
    -- table.insert(Assets, Asset("ATLAS", "images/crafting_menu_avatars/avatar_"..name..".xml"))

    AddModCharacter(name, gender)
end

AddCharacter("wheeler", "FEMALE")
