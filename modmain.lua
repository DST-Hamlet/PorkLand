local modimport = modimport
local GetModConfigData = GetModConfigData
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

STRINGS.NAMES.DUNGBEETLE = "Dung Beetle"
STRINGS.NAMES.DUNGBALL = "Dung Ball"
STRINGS.NAMES.DUNGPILE = "Dung Pile"
STRINGS.NAMES.POG = "Pog"
STRINGS.NAMES.CORK = "Cork"
STRINGS.NAMES.CLAWPALMTREE = "Claw Palm Tree"

STRINGS.CHARACTERS.GENERIC.DESCRIBE.DUNGBEETLE =
{
	GENERIC = "She's on a roll.",
	UNDUNGED = "She needs to get her dung together.",
	SLEEPING = "She's pooped.",
	DEAD = "Dung for.",
}
STRINGS.CHARACTERS.GENERIC.DESCRIBE.DUNGBALL = "Most definitely poop."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.DUNGPILE = 
	{
		GENERIC = "It's a pile of dung.",
		PICKED = "Dung and dung.",
	}
STRINGS.NAMES.HIPPOPOTAMOOSE = "hippopotamoose"
