local Assets = Assets
GLOBAL.setfenv(1, GLOBAL)

local function FinalOffset1(inst)
    inst.AnimState:SetFinalOffset(1)
end

local function TintOceantFx(inst)
    inst.AnimState:SetOceanBlendParams(TUNING.OCEAN_SHADER.EFFECT_TINT_AMOUNT)
end

local function BelowGroundFx(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    if y < -0.1 then
        inst.AnimState:SetLayer(LAYER_BELOW_GROUND)
    end
end

local pl_fx = {
    {
        name = "groundpound_nosound_fx",
        bank = "bearger_ground_fx",
        build = "bearger_ground_fx",
        anim = "idle",
    },
    {
        name = "hacking_tall_grass_fx",
        bank = "hacking_fx",
        build = "hacking_tall_grass_fx",
        anim = "idle",
        tint = Vector3(.6, .7, .6),
    },
    {
        name = "shock_machines_fx",
        bank = "shock_machines_fx",
        build = "shock_machines_fx",
        anim = "shock",
        -- sound = "dontstarve_DLC002/creatures/palm_tree_guard/coconut_explode",
        fn = FinalOffset1,
    },
    {
        name = "splash_water",
        bank = "splash_water",
        build = "splash_water",
        anim = "idle",
        fn = TintOceantFx,
    },
    {
        name = "snake_scales_fx",
        bank = "snake_scales_fx",
        build = "snake_scales_fx",
        anim = "idle",
    },
    {
        name = "splash_water_drop",
        bank = "splash_water_drop",
        build = "splash_water_drop",
        anim = "idle",
        sound = "dontstarve_DLC002/common/item_float",
        fn = TintOceantFx,
    },
    {
        name = "splash_water_sink",
        bank = "splash_water_drop",
        build = "splash_water_drop",
        anim = "idle_sink",
        sound = "dontstarve_DLC002/common/item_sink"
    },
    {
        name = "boat_hit_fx_raft_log",
        bank = "boat_hit_debris",
        build = "boat_hit_debris",
        anim = "hit_raft_log",
    },
    {
        name = "boat_hit_fx_raft_bamboo",
        bank = "boat_hit_debris",
        build = "boat_hit_debris",
        anim = "hit_raft_bamboo",
    },
    {
        name = "boat_hit_fx_rowboat",
        bank = "boat_hit_debris",
        build = "boat_hit_debris",
        anim = "hit_rowboat",
    },
    {
        name = "boat_hit_fx_cargoboat",
        bank = "boat_hit_debris",
        build = "boat_hit_debris",
        anim = "hit_cargoboat",
    },
    {
        name = "boat_hit_fx_corkboat",
        bank = "boat_hit_debris",
        build = "boat_hit_debris",
        anim = "hit_corkboat",
    },
    {
        name = "boat_death",
        bank = "boatdeathshadow",
        build = "boat_death_shadows",
        anim = "boat_death",
        tintalpha = 0.5,
    },
    {
    	name = "splash_clouds_drop",
    	bank = "splash_clouds_drop",
    	build = "splash_clouds_drop",
    	anim = "idle_sink",
        fn = BelowGroundFx,
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
