local TheNet = GLOBAL.TheNet

PrefabFiles = {
    "aporkalypse_clock",
    "asparagus",
    "deep_jungle_fern_noise",
    "flower_rainforest",
    "glowfly",
    "grass_tall",
    "pl_wave_shore",
    "jungle_border_vine",
    "machete",
    "peagawk",
    "peagawk_spawner",
    "peagawkfeather",
    "poisonbubble",
    "porkland_network",
    "rabid_beetle",
    "porkland",
    "shears",
    "tree_pillar",
    -- "tuber",
    -- "tubertrees",
    "weevole_carapace",
    "weevole",
}

Pl_Util.RegisterInventoryItemAtlas("images/pl_inventoryimages.xml")

Assets = {
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
    Asset("ANIM", "anim/player_actions_hack.zip"),
    Asset("ANIM", "anim/player_actions_shear.zip"),
}

AddMinimapAtlas("images/minimap/pl_minimap.xml")

if not TheNet:IsDedicated() then
    -- table.insert(Assets, Asset("SOUND", "sound/"))
end
