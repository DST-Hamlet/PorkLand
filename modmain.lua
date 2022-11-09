local modimport = modimport
local GetModConfigData = GetModConfigData
GLOBAL.setfenv(1, GLOBAL)

PL_CONFIG = {
	-- Some of these may be treated as client-side, as indicated by the bool
    locale = GetModConfigData("locale", true),
}

modimport("main/tuning")
modimport("main/constants")
modimport("main/postinit")
modimport("main/assets")
modimport("main/actions")

modimport("main/strings")
