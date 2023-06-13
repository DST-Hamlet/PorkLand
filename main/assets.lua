local TheNet = GLOBAL.TheNet

PrefabFiles = {
    "aporkalypse_clock",
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
    "weevole_carapace",
    "weevole",

	-- by Godless --
    --"pl_pocketdimensioncontainer_defs", -- i use override
	"halberd",
	"corkbat",
	"smelter",
	"pl_armor",
    "pl_hats",
    "pl_trinkets",
    "pl_chest",
    --"pl_preparedfoods", -- need to do perfected
    "pl_veggies",
    "pl_veggie_plant",
    "bugfood",
    "nectar_pod",
    "candlefire",
    "alloy",
    "cork",
    "gold_dust",
    "iron",
    "infused_iron",
    "venomgland",
    "clawpalmtrees",
    "clawpalmtree_sapling",
    "rock_flippable",
    "roc_nest",

    "smashingpot",
    "bramble_bulb",
    "inv_bamboo",
    "fabric",
    "clippings",
    "venus_stalk",
    "walkingstick",
    "pigghost",
    "lawnornaments",
    "topiary",
    "hedge",
    --"poisonmistarea", -- need update code
    "poisonmistparticle",
    "meteor_impact",
    --"deflated_balloon",
    "porklandintro",
    --"boatrepairkit",
    --"boattorch",

	-- by J0chem and n00bita
	"dungbeetle",
	"dungball",
	"dungpile",
	"pog",
	"pogherd",
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
	"pl_wave",

	-- By Noctice / Ardent
	"pl_feathers",
	"gnatmound",
    "gnat",
	"pangolden",
	"sedimentpuddle",
	"thunderbird",
    "thunderbirdnest",
	"tuber",
    "tubertrees",
	"jungle_tree_burr",
	"rainforesttrees",
	"snakeskin",
	"spider_monkey",
    "spider_monkey_tree",
    "spider_monkey_herd",
	"grabbing_vine",
	"hanging_vine",
	"adult_flytrap",
	"inv_vine",
    "pl_plantables",
    "pl_planted_tree",
	"mean_flytrap",
    "nettle",
    "nettle_plant",
    "sprinkler",
    "water_pipe",
    "water_spray",

	-- By Darian Stephens
	"oincs",
	"relics",
	"littlehammer",
	"waterdrop",
	"floweroflife",
	"ham_light_rays",
	--"vampirebatcave",
	"city_lamp",
	"scorpion",
	"snake",
	"pl_rocks",
	"ancient_hulk",
	"ancient_robots",
	"ancient_robots_assembly",
	"laser",
	"laser_ring",
	"reconstruction_project",

	"pig_ruins_creeping_vines",
	--"pig_ruins_dart",
	--"pig_ruins_dart_statue",
	--"pig_ruins_light_beam",
	--"pig_ruins_pressure_plate",
	"pig_ruins_spear_trap",
	"pig_ruins_torch",

    "teatrees",
    "teatree_nut",
    "piko",
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
	Asset("ANIM", "anim/player_actions_tap.zip"),

	-- turf_item
    Asset("ANIM", "anim/turf_pl.zip"),

	-- variant animations
	Asset("ANIM", "anim/log_rainforest.zip"),
	Asset("ANIM", "anim/hat_snakeskin_scaly.zip"),
}

Pl_Util.RegisterInventoryItemAtlas("images/pl_inventoryimages.xml")
AddMinimapAtlas("images/minimap/pl_minimap.xml")

if not TheNet:IsDedicated() then
    -- table.insert(Assets, Asset("SOUND", "sound/"))
end
