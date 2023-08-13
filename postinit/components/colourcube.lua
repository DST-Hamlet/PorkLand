local AddComponentPostInit = AddComponentPostInit
GLOBAL.setfenv(1, GLOBAL)

local PL_SEASON_COLOURCUBES = {
    [SEASONS.TEMPERATE] = {
        day = resolvefilepath("images/colour_cubes/pork_temperate_day_cc.tex"),
        dusk = resolvefilepath("images/colour_cubes/pork_temperate_dusk_cc.tex"),
        night = resolvefilepath("images/colour_cubes/pork_temperate_night_cc.tex"),
        full_moon = resolvefilepath("images/colour_cubes/pork_temperate_fullmoon_cc.tex"),
    },
    [SEASONS.HUMID] = {
        day = resolvefilepath("images/colour_cubes/pork_cold_day_cc.tex"),
        dusk = resolvefilepath("images/colour_cubes/pork_cold_dusk_cc.tex"),
        night = resolvefilepath("images/colour_cubes/pork_cold_dusk_cc.tex"),
        full_moon = resolvefilepath("images/colour_cubes/pork_cold_fullmoon_cc.tex"),
    },
    [SEASONS.LUSH] = {
        day = resolvefilepath("images/colour_cubes/pork_lush_day_test.tex"),
        dusk = resolvefilepath("images/colour_cubes/pork_lush_dusk_test.tex"),
        night = resolvefilepath("images/colour_cubes/pork_lush_dusk_test.tex"),
        full_moon = resolvefilepath("images/colour_cubes/pork_warm_fullmoon_cc.tex"),
    },
    [SEASONS.APORKALYPSE] = {
        day = resolvefilepath("images/colour_cubes/pork_cold_bloodmoon_cc.tex"),
        dusk = resolvefilepath("images/colour_cubes/pork_cold_bloodmoon_cc.tex"),
        night = resolvefilepath("images/colour_cubes/pork_cold_bloodmoon_cc.tex"),
        full_moon = resolvefilepath("images/colour_cubes/pork_cold_bloodmoon_cc.tex"),
    },
}

AddComponentPostInit("colourcube", function(self, inst)
    self:AddSeasonColourCube(PL_SEASON_COLOURCUBES)
end)
