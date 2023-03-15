local resolvefilepath = GLOBAL.resolvefilepath
local TheNet = GLOBAL.TheNet

PrefabFiles = {
    "aporkalypse_clock",
    "asparagus",
    "deep_jungle_fern_noise",
    "grass_tall",
    "pl_wave_shore",
    "jungle_border_vine",
    "machete",
    "peagawk",
    "peagawk_spawner",
    "peagawkfeather",
    "poisonbubble",
    "porkland_network",
    "porkland",
    "shears",
    -- "tuber",
    -- "tubertrees",
    "weevole_carapace",
    "weevole",
}

Pl_Util.RegisterInventoryItemAtlas(resolvefilepath("images/pl_inventoryimages.xml"))

Assets = {
    -- inventoryimages
    Asset("IMAGE", "images/pl_inventoryimages.tex"),
    Asset("ATLAS", "images/pl_inventoryimages.xml"),
    Asset("ATLAS_BUILD", "images/pl_inventoryimages.xml", 256),  -- for minisign

    -- hud
    Asset("ANIM", "anim/moon_aporkalypse_phases.zip"),

    -- fx
    -- poison
    Asset("ATLAS", "images/overlays/fx3.xml"),
    Asset("IMAGE", "images/overlays/fx3.tex"),
    -- fog
    Asset("ATLAS", "images/overlays/fx5.xml"),
    Asset("IMAGE", "images/overlays/fx5.tex"),

    -- player_actions
    Asset("ANIM", "anim/player_actions_hack.zip"),
    Asset("ANIM", "anim/player_actions_shear.zip"),
}

AddMinimapAtlas("images/minimap/pl_minimap.xml")

if not TheNet:IsDedicated() then
    -- table.insert(Assets, Asset("SOUND", "sound/"))
end
