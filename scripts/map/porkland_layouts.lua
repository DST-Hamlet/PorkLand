-- This file loads all static layouts and contains all non-static layouts
local StaticLayout = require("map/static_layout")
local AllLayouts = require("map/layouts").Layouts
require("constants")

local ground_types = {
	--Translates tile type index from constants.lua into tiled tileset.
	--Order they appear here is the order they will be used in tiled.
}
AllLayouts["PorklandStart"] = StaticLayout.Get("map/static_layouts/porkland_start")
AllLayouts["roc_nest"] = StaticLayout.Get("map/static_layouts/roc_nest", {restrict_to_valid_land = true})