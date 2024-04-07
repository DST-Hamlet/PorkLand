local modimport = modimport
local GetModConfigData = GetModConfigData
GLOBAL.setfenv(1, GLOBAL)

PL_CONFIG = {
    locale = GetModConfigData("locale", true), -- Some of these may be treated as client-side, as indicated by the bool
}

-- modimport("main/toolutil")

-- modimport("main/tuning")
modimport("main/constants")

modimport("main/util")
-- modimport("main/oceanutil")

modimport("main/assets")
modimport("main/fx")
modimport("main/strings")

modimport("main/commands")
modimport("main/standardcomponents")

modimport("main/pl_worldsettings_overrides")
modimport("main/RPC")
modimport("main/actions")
modimport("main/recipes")
modimport("main/cooking")
modimport("main/containers")
modimport("main/postinit")

AddReplicableComponent("hayfever")
AddReplicableComponent("sailor")
AddReplicableComponent("sailable")
AddReplicableComponent("boathealth")
AddReplicableComponent("boatcontainer")
AddReplicableComponent("boatvisualmanager")
