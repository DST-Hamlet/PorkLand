local resolvefilepath = GLOBAL.resolvefilepath
local TheNet = GLOBAL.TheNet

PrefabFiles = {
    "adult_flytrap",
    "asparagus",
    "corkbat",
    "deep_jungle_fern_noise",
    "grass_tall",
    "halberd",
    "jungle_border_vine",
    "machete",
    "mean_flytrap",
    "nectar_pod",
    "peagawk",
    "peagawkfeather",
    "peagawk_spawner",
    "pog",
    "pog_spawner",
    "poisonbubble",
    "shears",
    "tuber",
    "tubertrees",
    "venus_stalk",
    "vine",
    "walkingstick",
    "weevole",
    "weevole_carapace",
    "chitin",
    "antman",
    "antman_warrior",
    "antman_warrior_egg",
    "antlarva",
    "antcombhome",
    "anthill_lamp",
    "giantgrub",
    "anthill_stalactite",
    "antqueen",
    "antqueen_throne",
    "antqueen_spawner",
    "pheromonestone",
    "rabid_beetle",
    "glowfly"
}

local AddInventoryItemAtlas = gemrun("tools/misc").Local.AddInventoryItemAtlas
AddInventoryItemAtlas(resolvefilepath("images/pl_inventoryimages.xml"))

Assets = {
	Asset("IMAGE", "images/pl_inventoryimages.tex"),
    Asset("ATLAS", "images/pl_inventoryimages.xml"),
	Asset("ATLAS_BUILD", "images/pl_inventoryimages.xml", 256),  --For minisign

    Asset("ATLAS", "images/overlays/fx3.xml"),
    Asset("IMAGE", "images/overlays/fx3.tex"),

    --Loading this here because the meatrack needs them
    Asset("ANIM", "anim/meat_rack_food_sw.zip"),

    --Loading minimap
    Asset("ATLAS", "images/minimap/pl_minimap.xml"),
    Asset("IMAGE", "images/minimap/pl_minimap.tex"),

    Asset("ANIM", "anim/player_actions_hack.zip"),
	Asset("ANIM", "anim/player_actions_shear.zip"),
}

AddMinimapAtlas("images/minimap/pl_minimap.xml")

if not TheNet:IsDedicated() then
    -- table.insert(Assets, Asset("SOUND", "sound/pl.fsb"))
    -- table.insert(Assets, Asset("SOUNDPACKAGE", "sound/pl.fev"))
end
