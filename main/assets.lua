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
    "alloy",
    "bramble_bulb",
    "bugfood",
    "candlefire",
    "clawpalmtree_sapling",
    "clawpalmtrees",
    "clippings",
    "cork",
	"corkbat",
    "fabric",
    "gold_dust",
	"halberd",
    "hedge",
    "infused_iron",
    "inv_bamboo",
    "iron",
    "lawnornaments",
    "meteor_impact",
    "nectar_pod",
    "pigghost",
	"pl_armor",
    "pl_chest",
    "pl_hats",
    "pl_trinkets",
    "pl_veggie_plant",
    "pl_veggies",
    "poisonmistparticle",
    "porklandintro",
    "roc_nest",
    "rock_flippable",
    "smashingpot",
	"smelter",
    "topiary",
    "venomgland",
    "venus_stalk",
    "walkingstick",
    "hogusporkusator",
    "key_to_city",
    --"boatrepairkit",						-- need add boat
    --"boattorch",							-- need add boat
    --"deflated_balloon", 					-- no in pl world
    --"pl_pocketdimensioncontainer_defs", 	-- i use override
    --"pl_preparedfoods", 					-- need to do perfected

	-- by J0chem and n00bita
	"dungball",
	"dungbeetle",
	"dungpile",
	"lotus",
	"pl_wave",
	"pog",
	"pogherd",
    "bill",
    "bill_quill",
    "frog_poison",
    "hippo_antler",
    "hippoherd",
    "hippopotamoose",
    "lillypad",
    "lotus_flower",
    "reeds_water",

	-- By Noctice / Ardent
	"adult_flytrap",
	"gnatmound",
	"grabbing_vine",
	"hanging_vine",
	"inv_vine",
	"jungle_tree_burr",
	"mean_flytrap",
	"pangolden",
	"pl_feathers",
	"rainforesttrees",
	"sedimentpuddle",
	"snakeskin",
	"spider_monkey",
	"teatrees",
	"thunderbird",
	"tuber",
    "gnat",
    "nettle",
    "nettle_plant",
    "piko",
    "pl_plantables",
    "pl_planted_tree",
    "spider_monkey_herd",
    "spider_monkey_tree",
    "sprinkler",
    "teatree_nut",
    "thunderbirdnest",
    "tubertrees",
    "water_pipe",
    "water_spray",

	-- By Darian Stephens
	"oincs",
	"relics",
	"littlehammer",
	"waterdrop",
	"floweroflife",
	"ham_light_rays",
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
	"pig_ruins_dart",
	"pig_ruins_dart_statue",
	"pig_ruins_light_beam",
	"pig_ruins_pressure_plate",
	"pig_ruins_spear_trap",
	"pig_ruins_torch",
	"deed",
	"demolition_permit",
	"securitycontract",

	"wallcrack_ruins",	
	"pighouse_city",
	"pigman_city",				
	"pig_guard_tower",				
}

Assets = {
    -- minimap
    Asset("IMAGE", "images/minimap/pl_minimap.tex"),
    Asset("ATLAS", "images/minimap/pl_minimap.xml"),
	
	-- craft
	Asset("IMAGE", "images/hud/pl_hud.tex"),
    Asset("ATLAS", "images/hud/pl_hud.xml"),

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
