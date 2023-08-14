local MODROOT = MODROOT
local PLENV = env
GLOBAL.setfenv(1, GLOBAL)

IACore.LoadAndTranslateString("scripts/languages/pl_", PLENV)
