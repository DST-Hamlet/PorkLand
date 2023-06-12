local POCKETDIMENSIONCONTAINER_DEFS = require("prefabs/pocketdimensioncontainer_defs").POCKETDIMENSIONCONTAINER_DEFS

local ROOTCONTAINER_DEFS = {
	name = "root",
	prefab = "roottrunk",
	ui = "anim/ui_chester_shadow_3x4.zip",
	widgetname = "roottrunk",
	tags = { "spoiler" },
}
table.insert(POCKETDIMENSIONCONTAINER_DEFS, ROOTCONTAINER_DEFS)

--[[
POCKETDIMENSIONCONTAINER_DEFS[2] = 
{
	name = "root",
	prefab = "roottrunk",
	ui = "anim/ui_chester_shadow_3x4.zip",
	widgetname = "roottrunk",
	tags = { "spoiler" },
}]]

print("POCKETDIMENSIONCONTAINER_DEFS", POCKETDIMENSIONCONTAINER_DEFS[1].name)
print("POCKETDIMENSIONCONTAINER_DEFS", POCKETDIMENSIONCONTAINER_DEFS[2].name)