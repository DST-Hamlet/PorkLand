local TheNet = GLOBAL.TheNet

PrefabFiles = {
    "aporkalypse_clock",
    "asparagus",
    "chitin",
    "deep_jungle_fern_noise",
    "flower_rainforest",
    "glowfly",
    "gnatmound",
    "gnat",
    "gold_dust",
    "grabbing_vine",
    "grass_tall",
    "hanging_vine",
    "iron",
    "pl_feathers",
    "pl_plantables",
    "pl_planted_tree",
    "pl_wave_shore",
    "jungle_border_vine",
    "jungle_tree_burr",
    "machete",
    "nettle",
    "nettle_plant",
    "pangolden",
    "peagawk",
    "peagawk_spawner",
    "peagawkfeather",
    "poisonbubble",
    "porkland_network",
    "rabid_beetle",
    "porkland",
    "rainforesttrees",
    "scorpion",
    "sedimentpuddle",
    "shears",
    "snake",
    "snakeoil",
    "snakeskin",
    "sprinkler",
    "spider_monkey",
    "spider_monkey_tree",
    "spider_monkey_herd",
    "thunderbird",
    "thunderbirdnest",
    "tree_pillar",
    "tuber",
    "tubertrees",
    "venomgland",
    "water_pipe",
    "water_spray",
    "weevole_carapace",
    "weevole",
}

Assets = {
    -- minimap
    Asset("IMAGE", "images/minimap/pl_minimap.tex"),
    Asset("ATLAS", "images/minimap/pl_minimap.xml"),

    -- inventoryimages
    Asset("IMAGE", "images/pl_inventoryimages.tex"),
    Asset("ATLAS", "images/pl_inventoryimages.xml"),
    Asset("ATLAS_BUILD", "images/pl_inventoryimages.xml", 256),  -- for minisign

    -- hud
    Asset("ATLAS", "images/overlays/fx3.xml"),  -- poison
    Asset("IMAGE", "images/overlays/fx3.tex"),
    Asset("ATLAS", "images/overlays/fx5.xml"),  -- fog
    Asset("IMAGE", "images/overlays/fx5.tex"),
    Asset("ANIM", "anim/moon_aporkalypse_phases.zip"),  -- blood moon

    -- player_actions
    Asset("ANIM", "anim/player_idles_poison.zip"),
    Asset("ANIM", "anim/player_mount_idles_poison.zip"),
    Asset("ANIM", "anim/player_actions_hack.zip"),
    Asset("ANIM", "anim/player_actions_shear.zip"),
}

Pl_Util.RegisterInventoryItemAtlas("images/pl_inventoryimages.xml")
AddMinimapAtlas("images/minimap/pl_minimap.xml")

if not TheNet:IsDedicated() then
    -- table.insert(Assets, Asset("SOUND", "sound/"))
end
