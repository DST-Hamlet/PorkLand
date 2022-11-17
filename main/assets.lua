local resolvefilepath = GLOBAL.resolvefilepath
local TheNet = GLOBAL.TheNet

PrefabFiles = {
    "asparagus",
    "deep_jungle_fern_noise",
    "grass_tall",
    "jungle_border_vine",
    "machete",
    "peagawk",
    "peagawk_spawner",
	"peagawkfeather",
    "poisonbubble",
	"shears",
    -- "tuber",
    -- "tubertrees",
    "weevole_carapace",
    "weevole",
    "littlehammer",
    "pig_ruins",
    "relics",
}

local AddInventoryItemAtlas = gemrun("tools/misc").Local.AddInventoryItemAtlas
AddInventoryItemAtlas(resolvefilepath("images/pl_inventoryimages.xml"))

Assets = {
	Asset("IMAGE", "images/pl_inventoryimages.tex"),
    Asset("ATLAS", "images/pl_inventoryimages.xml"),
	Asset("ATLAS_BUILD", "images/pl_inventoryimages.xml", 256),  --For minisign

    Asset("ATLAS", "images/overlays/fx3.xml"),
    Asset("IMAGE", "images/overlays/fx3.tex"),

	Asset("ANIM", "anim/player_actions_shear.zip"),
    Asset("ANIM", "anim/player_actions_tap.zip"),
}

AddMinimapAtlas("images/minimap/pl_minimap.xml")

if not TheNet:IsDedicated() then
	-- table.insert(Assets, Asset("SOUND", "sound/"))
end
