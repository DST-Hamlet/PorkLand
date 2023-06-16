local modimport = modimport
local GetModConfigData = GetModConfigData
local AddPrototyperDef = AddPrototyperDef


local CustomTechTree = gemrun("tools/customtechtree")

-- Create the custom techtrees
CustomTechTree.AddNewTechType("CITY")
GLOBAL.TECH.CITY_TWO = {CITY = 2}
CustomTechTree.AddPrototyperTree("CITY", {CITY = 2})

GLOBAL.setfenv(1, GLOBAL)

IA_ENABLED = rawget(_G, "IA_CONFIG") ~= nil
IA_CONFIG = rawget(_G, "IA_CONFIG") or {
    droplootground = true
}

PL_CONFIG = {
    -- Some of these may be treated as client-side, as indicated by the bool
    locale = GetModConfigData("locale", true),
}

modimport("main/tuning")
modimport("main/constants")

modimport("main/pl_util")
modimport("main/util")
modimport("main/commands")
modimport("main/standardcomponents")

modimport("main/assets")
modimport("main/fx")
modimport("main/strings")

modimport("main/pl_worldsettings_overrides")
modimport("main/RPC")
modimport("main/actions")
modimport("main/postinit")


modimport("main/recipes")
modimport("main/containers")
modimport("main/prefabskin")
modimport("main/cooking")

modimport("main/shadeeffects")


PROTOTYPER_DEFS.hogusporkusator = PROTOTYPER_DEFS.researchlab4

AddPrototyperDef("key_to_city", {icon_atlas = "images/hud/pl_hud.xml", icon_image = "tab_city.tex", is_crafting_station = true, action_str = "CITY", filter_text = "City"})
PROTOTYPER_DEFS.key_to_city.filter_text = STRINGS.UI.CRAFTING_STATION_FILTERS.CITY --make it use the string now that its been loaded