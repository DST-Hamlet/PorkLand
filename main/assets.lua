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
    "tuber",
    "tubertrees",
    "weevole_carapace",
    "weevole",
    "littlehammer",
    "pig_ruins",
    "relics",
    "walkingstick",
    "halberd",
    "corkbat",
    "adult_flytrap",
    "mean_flytrap",
    "nectar_pod",
    "venus_stalk",
    "vine"
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

	Asset("ANIM", "anim/player_actions_shear.zip"),
    Asset("ANIM", "anim/player_actions_tap.zip"),

    Asset("IMAGE", "images/hud/hud_porkland.tex"),
    Asset("ATLAS", "images/hud/hud_porkland.xml"),
}

AddMinimapAtlas("images/minimap/pl_minimap.xml")

if not TheNet:IsDedicated() then
    -- table.insert(Assets, Asset("SOUND", "sound/pl.fsb"))
    -- table.insert(Assets, Asset("SOUNDPACKAGE", "sound/pl.fev"))
end
