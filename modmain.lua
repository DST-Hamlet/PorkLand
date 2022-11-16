local modimport = modimport
local GetModConfigData = GetModConfigData
GLOBAL.setfenv(1, GLOBAL)

IA_CONFIG = rawget(_G, "IA_CONFIG") or {
    droplootground = true
}

PL_CONFIG = {
	-- Some of these may be treated as client-side, as indicated by the bool
    locale = GetModConfigData("locale", true),
}

modimport("main/tuning")
modimport("main/constants")
modimport("main/assets")
modimport("main/util")
modimport("main/fx")
modimport("main/standardcomponents")
modimport("main/commands")

modimport("main/actions")
modimport("main/postinit")

modimport("main/strings")
