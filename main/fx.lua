local Assets = Assets
GLOBAL.setfenv(1, GLOBAL)

local function TintOceantFx(inst)
	inst.AnimState:SetOceanBlendParams(TUNING.OCEAN_SHADER.EFFECT_TINT_AMOUNT)
end

local pl_fx = {
    {
        name = "hacking_tall_grass_fx",
        bank = "hacking_fx",
        build = "hacking_tall_grass_fx",
        anim = "idle",
    },
    {
    	name = "splash_water",
    	bank = "splash_water",
    	build = "splash_water",
        fn = TintOceantFx,
    	anim = "idle",
	},
    {
    	name = "splash_water_wave",
    	bank = "splash_water",
    	build = "splash_water",
        sound = "ia/common/waves/break",
        fn = TintOceantFx,
    	anim = "idle",
	},
    {
    	name = "splash_water_drop",
    	bank = "splash_water_drop",
    	build = "splash_water_drop",
        fn = TintOceantFx,
    	anim = "idle",
	},
	{
    	name = "splash_water_float",
    	bank = "splash_water_drop",
    	build = "splash_water_drop",
		sound = "ia/common/item_float",
        fn = TintOceantFx,
    	anim = "idle",
	},
	{
    	name = "splash_water_sink",
    	bank = "splash_water_drop",
    	build = "splash_water_drop",
		sound = "ia/common/item_sink",
        fn = TintOceantFx,
    	anim = "idle_sink",
	},
    {
    	name = "splash_water_big",
    	bank = "splash_water_big",
    	build = "splash_water_big",
        fn = TintOceantFx,
    	anim = "idle",
	}
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
