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
modimport("main/fx")
modimport("main/util")
modimport("main/actions")
modimport("main/postinit")

modimport("main/strings")
--modimport("main/recipes")  --除了城镇规划和室内的制作配方都弄好了，但一直崩溃，好像不是我能搞定的。——lulu
