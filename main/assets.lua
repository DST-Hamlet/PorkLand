local TheNet = GLOBAL.TheNet

PrefabFiles = {
    "alloy",
    "aporkalypse_clock",
    "armor_metalplate",
    "asparagus_planted",
    "basefan",
    "bill_quill",
    "bill",
    "boatcontainer_classified",
    "boats",
    "chitin",
    "deep_jungle_fern_noise",
    "dungball",
    "dungbeetle",
    "dungpile",
    "flotsam",
    "flower_rainforest",
    "glowfly",
    "gold_dust",
    "goldpan",
    "grabbing_vine",
    "grass_tall",
    "halberd",
    "hanging_vine_patch",
    "hanging_vine",
    "hippo_antler",
    "hippoherd",
    "hippopotamoose",
    "inv_vine",
    "iron",
    "pl_wave_shore",
    "jungle_border_vine",
    "lilypad",
    "lotus",
    "lotus_flower",
    "machete",
    "nettle",
    "pangolden",
    "peagawk",
    -- "peagawk_spawner",
    "piko",
    "pl_frog",
    "pl_froglegs",
    "pl_planted_tree",
    "pl_preparedfoods",
    "pl_veggies",
    "pl_foodbuffs",
    "peagawkfeather",
    "poisonbubble",
    "porkland_network",
    "porkland",
    "rabid_beetle",
    "rowboat_wake",
    "sail",
    "sedimentpuddle",
    "shears",
    "smelter",
    "snake",
    "snakeskin",
    "snakeoil",
    "teatree_nut",
    "teatrees",
    "tree_pillar",
    -- "tuber",
    -- "tubertrees",
    "wave_ripple",
    "venomgland",
    "weevole_carapace",
    "weevole",
}

Assets = {
    -- minimap
    Asset("ATLAS", "images/minimap/pl_minimap.xml"),

    -- inventoryimages
    Asset("ATLAS", "images/hud/pl_inventoryimages.xml"),
    Asset("ATLAS_BUILD", "images/hud/pl_inventoryimages.xml", 256),  -- for minisign

    -- boat
    Asset("ATLAS", "images/hud/pl_hud.xml"),
    Asset("IMAGE", "images/hud/pl_hud.tex"),

    -- crafting menu icons
    Asset("ATLAS", "images/hud/pl_crafting_menu_icons.xml"),

    -- hud
    Asset("ATLAS", "images/overlays/fx3.xml"),  -- poison
    Asset("IMAGE", "images/overlays/fx3.tex"),
    Asset("ATLAS", "images/overlays/fx4.xml"),  -- pollen(hayfever)
    Asset("IMAGE", "images/overlays/fx4.tex"),
    Asset("ATLAS", "images/overlays/fx5.xml"),  -- fog
    Asset("IMAGE", "images/overlays/fx5.tex"),

    Asset("ANIM", "anim/moon_aporkalypse_phases.zip"),  -- blood moon

    -- player_actions
    Asset("ANIM", "anim/player_idles_poison.zip"),
    Asset("ANIM", "anim/player_mount_idles_poison.zip"),
    Asset("ANIM", "anim/player_actions_hack.zip"),
    Asset("ANIM", "anim/player_actions_shear.zip"),
    Asset("ANIM", "anim/player_sneeze.zip"),
    Asset("ANIM", "anim/player_mount_sneeze.zip"),
    Asset("ANIM", "anim/player_actions_panning.zip"),
    Asset("ANIM", "anim/player_boat_onoff.zip"),
    Asset("ANIM", "anim/swap_paddle.zip"),
    Asset("ANIM", "anim/player_action_sailing.zip"),

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
}

ToolUtil.RegisterInventoryItemAtlas("images/hud/pl_inventoryimages.xml")
AddMinimapAtlas("images/minimap/pl_minimap.xml")

local sounds = {
    Asset("SOUND", "sound/DLC003_AMB_stream.fsb"),
    Asset("SOUND", "sound/DLC003_music_stream.fsb"),
    Asset("SOUND", "sound/DLC003_sfx.fsb"),
    Asset("SOUNDPACKAGE", "sound/dontstarve_DLC003.fev")
}

if not TheNet:IsDedicated() then
    for _, asset in ipairs(sounds) do
        table.insert(Assets, asset)
    end
end
