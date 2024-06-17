local VARIANTS = {
    snakeskin =  {
        default = {
            bank = "snakeskin",
            build = "snakeskin"
        },
        porkland = {
            bank = "snakeskin_scaly",
            build = "snakeskin_scaly",
            inv_image = "snakeskin_scaly"
        }
    },
    sail_snakeskin = {
        default = {
            build = "swap_sail_snakeskin",
            visualprefab = "sail_snakeskin"
        },
        porkland = {
            build = "swap_sail_snakeskin_scaly",
            visualprefab = "sail_snakeskin_scaly",
            inv_image = "sail_snakeskin_scaly"
        }
    }
}

local SW_ICONS =
{
}

local PL_ICONS =
{
    ["snakeskin"] = "snakeskin_scaly",
    ["sail_snakeskin"] = "sail_snakeskin_scaly"
    -- ["dug_grass"] = "dug_grass_tropical",
    -- ["cutgrass"] = "cutgrass_tropical",
    -- ["log"] = "log_plateu",
    --
    -- ["snake"] = "snake_scaly",
    -- ["snakeskinsail"] = "snakeskinsail_scaly",
    -- ["armor_snakeskin"] = "armor_snakeskin_scaly",
    -- ["snakeskinhat"] = "snakeskinhat_scaly",
    -- ["fish"] = "coi",
    -- ["fish_cooked"] = "coi_cooked",
}

return {VARIANTS = VARIANTS, SW_ICONS = SW_ICONS, PL_ICONS = PL_ICONS}
