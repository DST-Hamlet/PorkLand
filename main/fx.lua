local Assets = Assets
GLOBAL.setfenv(1, GLOBAL)

local pl_fx = {
    {
        name = "hacking_tall_grass_fx",
        bank = "hacking_fx",
        build = "hacking_tall_grass_fx",
        anim = "idle",
    },
    {
        name = "robot_leaf_fx",
        bank = "robot_leaf_fx",
        build = "robot_leaf_fx",
        anim = "idle",
	},
}

-- Sneakily add these to the FX table
-- Also force-load the assets because the fx file won't do for some reason

local fx = require("fx")

for _, v in ipairs(pl_fx) do
    table.insert(fx, v)
    if Settings.last_asset_set ~= nil then
        table.insert(Assets, Asset("ANIM", "anim/" .. v.build .. ".zip"))
    end
end
