local Assets = Assets
GLOBAL.setfenv(1, GLOBAL)

local function TintOceantFx(inst)
	inst.AnimState:SetOceanBlendParams(TUNING.OCEAN_SHADER.EFFECT_TINT_AMOUNT)
end

local pl_fx = {
    {
    	name = "chop_mangrove_blue",
    	bank = "chop_mangrove",
    	build = "chop_mangrove_blue",
    	anim = "chop",
	},	
    {
    	name = "fall_mangrove_blue",
    	bank = "chop_mangrove",
    	build = "chop_mangrove_blue",
    	anim = "fall",
	},
	{
    	name = "chop_mangrove_pink",
    	bank = "chop_mangrove",
    	build = "chop_mangrove_pink",
    	anim = "chop",
    	dlc = true,
	},
    {
    	name = "fall_mangrove_pink",
    	bank = "chop_mangrove",
    	build = "chop_mangrove_pink",
    	anim = "fall",
    	dlc = true,
	},
	{
	    name = "hacking_fx",
	    bank = "hacking_fx",
	    build = "hacking_fx",
	    anim = "idle",
    },
	{
        name = "hacking_tall_grass_fx",
        bank = "hacking_fx",
        build = "hacking_tall_grass_fx",
        anim = "idle",
    },
	--------------------------------------------------------
	{
        name = "metal_hulk_ring_fx", 
        bank = "metal_hulk_ring_fx", 
        build = "metal_hulk_ring_fx", 
        anim = "idle",
        fn = function(inst)
			inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
			inst.AnimState:SetLayer(LAYER_BACKGROUND)
			inst.AnimState:SetSortOrder(2)
        end,     
    },
	{
	    name = "groundpound_fx_hulk",
	    bank = "bearger_ground_fx",
	    build = "bearger_ground_fx",
	    sound = "dontstarve_DLC003/creatures/boss/hulk_metal_robot/dust",
    	anim = "idle",
    },    
    {
        name = "laser_burst_fx", 
        bank = "laser_ring_fx", 
        build = "laser_ring_fx", 
        anim = "idle", 
    },    
    {
        name = "living_suit_explode_fx", 
        bank = "living_suit_explode_fx", 
        build = "living_suit_explode_fx", 
        anim = "idle",     
    }, 
	{
		name = "circle_puff_fx",
    	bank = "circle_puff_fx",
    	build = "circle_puff_fx",
    	anim = "idle",
	},    
    {
    	name = "snake_scales_fx",
    	bank = "snake_scales_fx",
    	build = "snake_scales_fx",
    	anim = "idle",
	},
	{
    	name = "int_ceiling_dust_fx",
    	bank = "int_ceiling_dust_fx",
    	build = "int_ceiling_dust_fx",
    	anim = "idle",
	},
	{
    	name = "robot_leaf_fx",
    	bank = "robot_leaf_fx",
    	build = "robot_leaf_fx",
    	anim = "idle",
	},
	{
    	name = "sparks_green_fx",
    	bank = "sparks",
    	build = "sparks_green",
	    -- anim = {"sparks_1", "sparks_2", "sparks_3"}, -- Seems it needs to support a table of animations to properly reflect Hamlet again. Or I could separate them out into 3?
	    anim = "sparks_1",
	},	
    {
        name = "spat_splat_fx",
        bank = "spat_splat",
        build = "spat_splat",
        anim = "idle",
    },	
    {
        name = "spat_splash_fx_full",
        bank = "spat_splash",
        build = "spat_splash",
        anim = "full",     
    },
    {
        name = "spat_splash_fx_med",
        bank = "spat_splash",
        build = "spat_splash",
        anim = "med",    
    },
    {
        name = "spat_splash_fx_low",
        bank = "spat_splash",
        build = "spat_splash",
        anim = "low",
    },
    {
        name = "spat_splash_fx_melted", 
        bank = "spat_splash", 
        build = "spat_splash", 
        anim = "melted",
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
