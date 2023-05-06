-- This file loads all static layouts and contains all non-static layouts
local StaticLayout = require("map/static_layout")
local AllLayouts = require("map/layouts").Layouts
require("constants")

local ground_types = {
    --Translates tile type index from constants.lua into tiled tileset.
    --Order they appear here is the order they will be used in tiled.
}
