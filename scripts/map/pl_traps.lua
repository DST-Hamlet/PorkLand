require("constants")
local StaticLayout = require("map/static_layout")
local obj_layout = require("map/object_layout")

local Rare = {
	--["Dev Graveyard"] = StaticLayout.Get("map/static_layouts/dev_graveyard"),
}

local Rocky = {
}

local Traps = {
	["Rare"] = Rare,
    [WORLD_TILES.ROCKY] = Rocky,
}

local layouts = {}
for k,area in pairs(Traps) do
	if GetTableSize(area) >0 then
		for name, layout in pairs(area) do
			layouts[name] = layout
		end
	end
end

return {Sandbox = Traps, Layouts = layouts}
