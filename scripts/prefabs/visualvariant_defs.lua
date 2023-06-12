local POSSIBLE_VARIANTS = {}

local VISUALVARIANT_PREFABS = {}

POSSIBLE_VARIANTS.log = {
    default = {build="log",invatlas="default",sourceprefabs={
        "marsh_tree",
        "evergreen",
        "evergreen_sparse",
        "winter_tree",
        "twiggytree",
        "winter_twiggytree",
        "deciduoustree",
        "winter_deciduoustree",
        "palmconetree",
        "winter_palmconetree",
        "leif",
        "leif_sparse",
        "moon_tree",
        "oceantree",
        "oceantree_pillar",
    },sourcetags={
        "deciduoustree",
        "cavedweller",
        "mushtree",
    }},
    porkland = {build="log_rainforest",invatlas="images/pl_inventoryimages.xml",sourceprefabs={
        "evergreen",
    },testfn=IsInPLClimate},
}
POSSIBLE_VARIANTS.snakeskinhat = {
    default = {build="hat_snakeskin"},
    tropical = {build="hat_snakeskin",testfn=IsInIAClimate},
	porkland = {build="hat_snakeskin_scaly",testfn=IsInPLClimate},
}

return {POSSIBLE_VARIANTS = POSSIBLE_VARIANTS, VISUALVARIANT_PREFABS = VISUALVARIANT_PREFABS}