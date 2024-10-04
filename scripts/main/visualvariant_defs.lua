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
    },
    grass = {
        default = {
            build = "grass1",
        },
        porkland = {
            build = "grassgreen_build",
            minimap = "grassGreen.tex"
        }
    },
    dug_grass = {
        default = {
            build = "grass1",
        },
        porkland = {
            build = "grassgreen_build",
            inv_image = "dug_grass_green"
        }
    },
    cutgrass = {
        default = {
            build = "cutgrass",
        },
        porkland = {
            build = "cutgrassgreen",
            inv_image = "cutgrass_green"
        }
    },
    log = {
        default = {
            build = "log",
        },
        porkland = {
            build = "log_rainforest",
            inv_image = "log_rainforest"
        }
    },
}

local SW_ICONS =
{
}

local PL_ICONS =
{
    ["snakeskin"] = "snakeskin_scaly",
    ["sail_snakeskin"] = "sail_snakeskin_scaly",
    ["dug_grass"] = "dug_grass_green",
    ["cutgrass"] = "cutgrass_green",
    ["log"] = "log_rainforest",
    --
    -- ["snake"] = "snake_scaly",
    -- ["snakeskinsail"] = "snakeskinsail_scaly",
    -- ["armor_snakeskin"] = "armor_snakeskin_scaly",
    -- ["snakeskinhat"] = "snakeskinhat_scaly",
}

return {VARIANTS = VARIANTS, SW_ICONS = SW_ICONS, PL_ICONS = PL_ICONS}
