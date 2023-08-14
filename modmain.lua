local modimport = modimport
local GetModConfigData = GetModConfigData
local AddReplicableComponent = AddReplicableComponent
GLOBAL.setfenv(1, GLOBAL)

IA_ENABLED = rawget(_G, "IA_CONFIG") ~= nil
IA_CONFIG = rawget(_G, "IA_CONFIG") or {
    droplootground = true
}

PL_CONFIG = {
    -- Some of these may be treated as client-side, as indicated by the bool
}

modimport("main/tuning")
modimport("main/constants")

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

AddReplicableComponent("hayfever")
