local TheNet = GLOBAL.TheNet

PrefabFiles = {
    "aporkalypse_clock",
    "asparagus",
    "chitin",
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
    --mod stuff dung
    "dungbeetle",
	"dungball",
	"dungpile",
	"pog",
	"pogherd",
    --mod hippopotamoose
    "hippopotamoose",
    "hippoherd",
    "hippo_antler",
    "lillypad",
    "lotus",
    "lotus_flower",
    "bill",
    "bill_quill",
    "reeds_water",
    "frog_poison",
    "froglegs_poison",
    "venomgland"
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

    -- mod stuff
    Asset("IMAGE", "map_icons/minimap_hamlet.tex"),
	Asset("MINIMAP_IMAGE", "map_icons/minimap_hamlet.tex"),
	Asset("ATLAS", "map_icons/minimap_hamlet.xml"),
	Asset("IMAGE", "images/inventoryimages/inventoryimages_hamlet.tex"),
	Asset("ATLAS", "images/inventoryimages/inventoryimages_hamlet.xml"),
	Asset("IMAGE", "images/inventoryimages/inventoryimages_hamlet_2.tex"),
	Asset("ATLAS", "images/inventoryimages/inventoryimages_hamlet_2.xml"),
}

Pl_Util.RegisterInventoryItemAtlas("images/pl_inventoryimages.xml")
AddMinimapAtlas("images/minimap/pl_minimap.xml")
AddMinimapAtlas("map_icons/minimap_hamlet.xml") -- duplicate might need to delete

if not TheNet:IsDedicated() then
    -- table.insert(Assets, Asset("SOUND", "sound/"))
end
