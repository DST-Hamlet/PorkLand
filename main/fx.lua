local Assets = Assets
GLOBAL.setfenv(1, GLOBAL)

local function FinalOffset1(inst)
    inst.AnimState:SetFinalOffset(1)
end

local function TintOceantFx(inst)
    inst.AnimState:SetOceanBlendParams(TUNING.OCEAN_SHADER.EFFECT_TINT_AMOUNT)
end

local function BelowGroundFx(inst)
    local _, y, _ = inst.Transform:GetWorldPosition()
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
        sound = "dontstarve_DLC002/common/wave_break",
        fn = TintOceantFx,
    },
    {
        name = "splash_water_boost",
        bank = "splash_water",
        build = "splash_water",
        anim = "idle",
        sound = "dontstarve_DLC002/common/wave_break",
        sound2 = "dontstarve_DLC002/common/wave_boost",
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
        sound = "turnoftides/common/together/water/splash/small", -- "dontstarve_DLC002/common/item_sink"
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
    {
        name = "clouds_bombsplash",
        bank = "clouds_bombsplash",
        build = "clouds_bombsplash",
        anim = "splash",
        fn = BelowGroundFx,
    },
    {
        name = "circle_puff_fx",
        bank = "circle_puff_fx",
        build = "circle_puff_fx",
        anim = "idle",
    },
    {
        name = "hacking_fx",
        bank = "hacking_fx",
        build = "hacking_fx",
        anim = "idle",
    },
    {
        name = "rock_hit_debris",
        bank = "rock_hit_debris",
        build = "rock_hit_debris",
        anim = "hit_rock_ruins",
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
        anim = "sparks_1",
        fn = function(inst)
            local anims = {"sparks_1", "sparks_2", "sparks_3"}
            inst.AnimState:PlayAnimation(anims[math.random(1, 3)])
        end
    },
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
        name = "laser_explosion",
        build = "laser_explosion",
        bank = "laser_explosion",
        anim = "idle",
        fn = function(inst)
            inst.Transform:SetScale(0.85, 0.85, 0.85)
        end,
    },
    {
        name = "laser_explosion_small",
        build = "laser_explosion",
        bank = "laser_explosion",
        anim = "idle",
        fn = function(inst)
            inst.Transform:SetScale(0.4, 0.4, 0.4)
        end,
    },
    {
        name = "living_suit_explode_fx",
        bank = "living_suit_explode_fx",
        build = "living_suit_explode_fx",
        anim = "idle",
    },
    {
        name = "chop_mangrove_pink",
        bank = "chop_mangrove",
        build = "chop_mangrove_pink",
        anim = "chop",
    },
    {
        name = "fall_mangrove_pink",
        bank = "chop_mangrove",
        build = "chop_mangrove_pink",
        anim = "fall",
    },
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
        name = "cloudpuff",
        bank = "cloud_puff_soft",
        build = "cloud_puff_soft",
        anim = "idle_sink",
    },
    {
        name = "armorvortexcloak_fx",
        bank = "cloakfx",
        build = "cloak_fx",
        anim = "idle",
        fn = function(inst)
            for i = 1, 14 do
                inst.AnimState:Hide("fx" .. i)
            end
            inst.AnimState:Show("fx" .. math.random(1, 14))
        end
    },
    {
        name = "vortex_cloak_fx",
        bank = "vortex_cloak_fx",
        build = "vortex_cloak_fx",
        anim = "idle",
    },
    {
        name = "int_ceiling_dust_fx",
        bank = "int_ceiling_dust_fx",
        build = "int_ceiling_dust_fx",
        anim = "idle",
    },
    {
        name = "explode_large",
        bank = "explode_large",
        build = "explode_large",
        anim = "large",
        bloom = true,
        sound = "dontstarve/common/blackpowder_explo",
        fn = function(inst)
            inst.AnimState:SetLightOverride(1)
        end,
    },
    {
        name = "explodering_fx",
        bank = "explode_ring_fx",
        build = "explode_ring_fx",
        anim = "idle",
        fn = function(inst)
            inst.AnimState:SetFinalOffset(-1)
            inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
            inst.AnimState:SetLayer(LAYER_BACKGROUND)
            inst.AnimState:SetSortOrder( -3 )
        end,
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
